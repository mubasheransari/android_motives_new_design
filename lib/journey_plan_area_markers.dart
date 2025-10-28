import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Constants/constants.dart';






// DROP-IN REPLACEMENT: only this widget changed.


class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
  const AreaMarkersFromJourneyPlanMap({
    super.key,
    this.regionHint = 'Sindh',
    this.country = 'Pakistan',
    this.autoFitAfterLoad = true,
  });

  final String regionHint;
  final String country;
  final bool autoFitAfterLoad;

  @override
  State<AreaMarkersFromJourneyPlanMap> createState() =>
      _AreaMarkersFromJourneyPlanMapState();
}

class _AreaMarkersFromJourneyPlanMapState
    extends State<AreaMarkersFromJourneyPlanMap> {
  final _box = GetStorage();
  final _memCache = <String, LatLng>{};
  final _markers = <Marker>{};
  final _mapCtl = Completer<GoogleMapController>();
  final _loc = loc.Location();

  bool _loading = false;
  LatLng? _myLoc;

  int _geocodeOk = 0;
  int _geocodeFail = 0;
  int _dupSkipped = 0;

  _Selected? _selected;

  // Neutral Pakistan center (only for initial fallback camera)
  static const _pkCenter = LatLng(30.3753, 69.3451);

  static const _fallbackCamera = CameraPosition(
    target: _pkCenter,
    zoom: 5.5,
  );

  final List<_FailureRow> _failures = [];
  final List<_DupRow> _dups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMyLocation();
      await _loadAndPlaceAll();

      // Prefer centering on current location if we have it
      if (_myLoc != null) {
        await _centerOnMyLocation(initial: true);
      } else if (_markers.isNotEmpty && widget.autoFitAfterLoad) {
        await _fitAllMarkers();
      }
    });
  }

  // -------------------- Current location --------------------
  Future<void> _ensureMyLocation() async {
    try {
      final perm = await _loc.hasPermission();
      if (perm == loc.PermissionStatus.denied ||
          perm == loc.PermissionStatus.deniedForever) {
        final req = await _loc.requestPermission();
        if (req != loc.PermissionStatus.granted) return;
      }
      var svc = await _loc.serviceEnabled();
      if (!svc) {
        svc = await _loc.requestService();
        if (!svc) return;
      }
      final l = await _loc.getLocation();
      if (l.latitude != null && l.longitude != null) {
        setState(() => _myLoc = LatLng(l.latitude!, l.longitude!));
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _centerOnMyLocation({bool initial = false}) async {
    final ctl = await _mapCtl.future;
    final target = _myLoc ?? _pkCenter;
    await ctl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: initial ? 16 : 15.5),
    ));
  }

  // -------------------- Field extractors --------------------
  String _areaOf(dynamic plan) {
    try {
      final v = (plan as dynamic).areaName;
      if (v != null) return v.toString();
    } catch (_) {}
    if (plan is Map) {
      final v = plan['areaName'];
      if (v != null) return v.toString();
    }
    return '';
  }

  String _shopOf(dynamic plan) {
    final tryKeys = ['partyName', 'shopName', 'name', 'outlet', 'customerName'];
    try {
      final v = (plan as dynamic).partyName;
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    } catch (_) {}
    if (plan is Map) {
      for (final k in tryKeys) {
        final v = plan[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
    }
    return 'Shop';
  }

  String _ownerOf(dynamic plan) {
    final tryKeys = [
      'ownerName','owner','proprietor','contactPerson','contact_name',
      'personName','custOwner','shopOwner'
    ];
    try {
      final v = (plan as dynamic).ownerName;
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    } catch (_) {}
    if (plan is Map) {
      for (final k in tryKeys) {
        final v = plan[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
    }
    return '—';
  }

  String _journeyIdOf(dynamic plan) {
    const keys = [
      'journeyId','JourneyId','journyId','journeyid',
      'jpId','jp_id','JPId','jid','JID',
      'routeId','route_id','journey_id','planId','PlanId',
    ];
    if (plan is Map) {
      for (final k in keys) {
        final v = plan[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
    }
    try {
      final tryDyn = [
        (plan as dynamic).journeyId, (plan as dynamic).JourneyId,
        (plan as dynamic).journyId, (plan as dynamic).jpId,
        (plan as dynamic).jid, (plan as dynamic).routeId,
        (plan as dynamic).journey_id, (plan as dynamic).planId,
      ];
      for (final v in tryDyn) {
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
    } catch (_) {}
    return '';
  }

  // -------------------- Geocoding by AREA ONLY --------------------
  String _cacheKey(String area) => 'geo_area_only_${area.trim().toLowerCase()}';

  Future<LatLng?> _geocodeAreaOnly(String areaName) async {
    final a = areaName.trim();
    if (a.isEmpty) return null;

    // cache
    final key = _cacheKey(a);
    if (_memCache.containsKey(key)) return _memCache[key];
    final cached = _box.read(key);
    if (cached is String && cached.contains(',')) {
      final parts = cached.split(',');
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        final pos = LatLng(lat, lng);
        _memCache[key] = pos;
        return pos;
      }
    }

    // Try area alone first (no city), then country-scoped fallbacks.
    final candidates = <String>[
      a,
      '$a, ${widget.country}',
      '$a, ${widget.regionHint}, ${widget.country}',
    ];

    for (final q in candidates) {
      try {
        final hits = await geo.locationFromAddress(q);
        if (hits.isEmpty) continue;
        final h = hits.first; // accept first hit (no city filtering)
        final pos = LatLng(h.latitude, h.longitude);
        _memCache[key] = pos;
        await _box.write(key, '${pos.latitude},${pos.longitude}');
        return pos;
      } catch (_) {/* try next */}
    }
    return null;
  }

  // -------------------- Marker creation & placement --------------------
  LatLng _withJitter(LatLng base, int indexOnSamePoint) {
    if (indexOnSamePoint <= 0) return base;
    const step = 0.0002; // ~22m
    final angle = (indexOnSamePoint % 12) * (2 * pi / 12);
    final radius = step * ((indexOnSamePoint ~/ 12) + 1);
    return LatLng(
      base.latitude + radius * sin(angle),
      base.longitude + radius * cos(angle),
    );
  }

  Future<void> _loadAndPlaceAll() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _geocodeOk = 0;
      _geocodeFail = 0;
      _dupSkipped = 0;
      _failures.clear();
      _dups.clear();
      _selected = null;
    });

    final model = context.read<GlobalBloc>().state.loginModel;
    final List<dynamic> plans =
        (model?.journeyPlan as List?) ?? const <dynamic>[];

    // Dedup by journeyId (if present)
    final rawRows = plans
        .map((p) => (
              area: _areaOf(p).trim(),
              shop: _shopOf(p).trim(),
              owner: _ownerOf(p).trim(),
              jid: _journeyIdOf(p).trim(),
              raw: p
            ))
        .toList();

    final seenJid = <String>{};
    final rows = <({String area, String shop, String owner, String jid, dynamic raw})>[];

    for (final r in rawRows) {
      if (r.jid.isNotEmpty) {
        if (seenJid.contains(r.jid)) {
          _dupSkipped++;
          _dups.add(_DupRow(jid: r.jid, area: r.area, shop: r.shop, owner: r.owner));
          continue;
        }
        seenJid.add(r.jid);
      }
      rows.add(r);
    }

    // Geocode & place markers (post-dedup)
    final futures = <Future<_GeoRow>>[];
    for (int i = 0; i < rows.length; i++) {
      futures.add(_geocodeRow(rows[i], i));
    }
    final results = await Future.wait(futures);

    final samePosCounter = <String, int>{};
    final newMarkers = <Marker>{};

    for (final r in results) {
      if (r.pos == null) {
        _geocodeFail++;
        _failures.add(_FailureRow(
          area: r.area,
          shop: r.shop,
          reason: r.reason ?? 'Unable to resolve this area to a location.',
        ));
        continue;
      }

      _geocodeOk++;
      final roundedKey =
          '${r.pos!.latitude.toStringAsFixed(5)},${r.pos!.longitude.toStringAsFixed(5)}';
      final idxOnSame =
          samePosCounter.update(roundedKey, (v) => v + 1, ifAbsent: () => 0);

      final effectivePos = _withJitter(r.pos!, idxOnSame);
      final markerId = 'shop_${r.index}_${r.area}_${r.shop}';

      newMarkers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: effectivePos,
          infoWindow: InfoWindow(
            title: r.shop.isEmpty ? 'Shop' : r.shop,
            snippet: r.owner.isNotEmpty ? 'Owner: ${r.owner}' : r.area,
          ),
          onTap: () => _onMarkerTap(
            shop: r.shop.isEmpty ? 'Shop' : r.shop,
            owner: r.owner.isEmpty ? '—' : r.owner,
            area: r.area,
            pos: effectivePos,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
      _loading = false;
    });
  }

  Future<_GeoRow> _geocodeRow(
      ({String area, String shop, String owner, String jid, dynamic raw}) row,
      int index) async {
    if (row.area.isEmpty) {
      return _GeoRow(
        area: row.area,
        shop: row.shop,
        owner: row.owner,
        index: index,
        pos: null,
        reason: 'Missing area name.',
      );
    }

    final pos = await _geocodeAreaOnly(row.area);
    return _GeoRow(
      area: row.area,
      shop: row.shop,
      owner: row.owner,
      index: index,
      pos: pos,
      reason: pos == null ? 'Could not geocode from area name only.' : null,
    );
  }

  // -------------------- Marker tap: distance & info card --------------------
  void _onMarkerTap({
    required String shop,
    required String owner,
    required String area,
    required LatLng pos,
  }) {
    final km = (_myLoc == null) ? null : _distanceKm(_myLoc!, pos);
    setState(() {
      _selected = _Selected(shop: shop, owner: owner, area: area, pos: pos, km: km);
    });
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(la1) * cos(la2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return R * c;
  }

  double _deg2rad(double d) => d * (pi / 180.0);

  // -------------------- Fit all markers --------------------------------------
  Future<void> _fitAllMarkers() async {
    if (_markers.isEmpty) return;
    final c = await _mapCtl.future;

    double minLat = _markers.first.position.latitude;
    double maxLat = minLat;
    double minLng = _markers.first.position.longitude;
    double maxLng = minLng;

    for (final m in _markers) {
      final p = m.position;
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  // -------------------- UI ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Plan — Area Markers'),
        actions: [
          IconButton(
            tooltip: 'Clear geocode cache',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final keys = _box.getKeys()
                  .where((k) => k.toString().startsWith('geo_area_only_'))
                  .toList();
              for (final k in keys) {
                await _box.remove(k);
              }
              _memCache.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Geocode cache cleared')),
              );
            },
          ),
          IconButton(
            tooltip: 'Reload markers',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await _loadAndPlaceAll();
              if (_myLoc != null) {
                await _centerOnMyLocation();
              } else if (_markers.isNotEmpty) {
                await _fitAllMarkers();
              }
            },
          ),
          IconButton(
            tooltip: 'Fit all markers',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: _fitAllMarkers,
          ),
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _centerOnMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _fallbackCamera,
            onMapCreated: (c) async {
              _mapCtl.complete(c);
              if (_myLoc != null) {
                await _centerOnMyLocation(initial: true);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: _markers,
          ),

          if (!_loading)
            Positioned(
              top: 12, left: 12,
              child: InkWell(
                onTap: (_failures.isEmpty && _dups.isEmpty) ? null : _showStatusSheet,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))],
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.place_rounded, size: 16, color: Color(0xFF1F2937)),
                    const SizedBox(width: 6),
                    Text('Markers: $_geocodeOk  •  Failed: $_geocodeFail  •  Dups: $_dupSkipped',
                        style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700)),
                    if (_failures.isNotEmpty || _dups.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF6B7280)),
                    ],
                  ]),
                ),
              ),
            ),

          if (_loading)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 8),
                  Text('Placing markers…', style: TextStyle(color: Colors.white)),
                ]),
              ),
            ),

          if (_selected != null)
            Positioned(
              left: 12, right: 12, bottom: 16,
              child: _BottomInfoCard(
                selected: _selected!,
                onClose: () => setState(() => _selected = null),
                onCenterHere: () async {
                  final ctl = await _mapCtl.future;
                  await ctl.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(target: _selected!.pos, zoom: 17)),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fitAllMarkers,
        icon: const Icon(Icons.fullscreen_rounded),
        label: const Text('Fit all'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Placement report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              if (_dups.isNotEmpty) ...[
                Row(children: const [
                  Icon(Icons.copy_rounded, color: Colors.amber), SizedBox(width: 6),
                  Text('Skipped duplicates (same Journey ID)', style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dups.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = _dups[i];
                    return ListTile(
                      leading: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                      title: Text(d.shop.isEmpty ? 'Shop' : d.shop,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('JID: ${d.jid} • ${d.area.isEmpty ? "(no area)" : d.area} • ${d.owner}'),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_failures.isNotEmpty) ...[
                Row(children: const [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent), SizedBox(width: 6),
                  Text('Unable to mark these locations', style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _failures.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final f = _failures[i];
                    return ListTile(
                      leading: const Icon(Icons.place_outlined, color: Colors.redAccent),
                      title: Text(f.shop.isEmpty ? 'Shop' : f.shop,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${f.area.isEmpty ? "(no area)" : f.area} • ${f.reason}'),
                    );
                  },
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// -------------------- Helper widgets / models --------------------

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({
    required this.selected,
    required this.onClose,
    required this.onCenterHere,
  });

  final _Selected selected;
  final VoidCallback onClose;
  final VoidCallback onCenterHere;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.store_rounded, color: Color(0xFFEA7A3B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(selected.shop,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Flexible(child: Text(selected.owner,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)))),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Flexible(child: Text(selected.area,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)))),
                  const SizedBox(width: 10),
                  const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    selected.km == null
                        ? '—'
                        : (selected.km! < 1
                            ? '${(selected.km! * 1000).toStringAsFixed(0)} m'
                            : '${selected.km!.toStringAsFixed(1)} km'),
                    style: t.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA7A3B),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            IconButton(tooltip: 'Center here', icon: const Icon(Icons.center_focus_strong_rounded), onPressed: onCenterHere),
            IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

class _GeoRow {
  final String area;
  final String shop;
  final String owner;
  final int index;
  final LatLng? pos;
  final String? reason;
  _GeoRow({required this.area, required this.shop, required this.owner, required this.index, required this.pos, this.reason});
}

class _FailureRow {
  final String area;
  final String shop;
  final String reason;
  _FailureRow({required this.area, required this.shop, required this.reason});
}

class _DupRow {
  final String jid;
  final String area;
  final String shop;
  final String owner;
  _DupRow({required this.jid, required this.area, required this.shop, required this.owner});
}

class _Selected {
  final String shop;
  final String owner;
  final String area;
  final LatLng pos;
  final double? km;
  _Selected({required this.shop, required this.owner, required this.area, required this.pos, required this.km});
}
