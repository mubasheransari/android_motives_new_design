import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';








class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
  const AreaMarkersFromJourneyPlanMap({
    super.key,
    this.cityHint = 'Karachi',
    this.regionHint = 'Sindh',
    this.country = 'Pakistan',
    this.autoFitAfterLoad = true,
  });

  /// We bias geocoding to this city/region/country.
  final String cityHint;
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

  _Selected? _selected;

  /// Karachi approx bounds (loose but excludes Lahore, etc.)
  static const _KARACHI_MIN_LAT = 24.75;
  static const _KARACHI_MAX_LAT = 25.10;
  static const _KARACHI_MIN_LNG = 66.65;
  static const _KARACHI_MAX_LNG = 67.45;

  static const _karachiCenter = LatLng(24.8607, 67.0011);

  static const _fallbackCamera = CameraPosition(
    target: _karachiCenter,
    zoom: 12,
  );

  final List<_FailureRow> _failures = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMyLocation();   // acquire GPS to start on user
      await _loadAndPlaceAll();    // place markers
      // Start view: prefer my location; otherwise fit all; else Karachi
      if (_myLoc != null) {
        await _centerOnMyLocation(initial: true);
      } else if (_markers.isNotEmpty && widget.autoFitAfterLoad) {
        await _fitAllMarkers();
      } else {
        await _centerOnKarachi();
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
    final target = _myLoc ?? _karachiCenter;
    await ctl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: initial ? 16 : 15.5),
    ));
  }

  Future<void> _centerOnKarachi() async {
    final ctl = await _mapCtl.future;
    await ctl.animateCamera(CameraUpdate.newCameraPosition(
      const CameraPosition(target: _karachiCenter, zoom: 12.5),
    ));
  }

  // -------------------- Helpers from JourneyPlan --------------------

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
      'ownerName',
      'owner',
      'proprietor',
      'contactPerson',
      'contact_name',
      'personName',
      'custOwner',
      'shopOwner'
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

  // -------------------- Geocoding with Karachi bias --------------------

  bool _inKarachi(LatLng p) {
    return p.latitude >= _KARACHI_MIN_LAT &&
        p.latitude <= _KARACHI_MAX_LAT &&
        p.longitude >= _KARACHI_MIN_LNG &&
        p.longitude <= _KARACHI_MAX_LNG;
  }

  String _cacheKey(String area) =>
      'geo_area_${area.trim().toLowerCase()}__${widget.cityHint.toLowerCase()}';

  Future<LatLng?> _geocodeAreaKarachiBiased(String areaName) async {
    // Treat bad/ambiguous area names as failure
    final a = areaName.trim();
    if (a.isEmpty) return null;
    if (a.toLowerCase() == widget.country.toLowerCase()) return null; // too broad

    final key = _cacheKey(a);

    // memory
    if (_memCache.containsKey(key)) return _memCache[key];

    // disk
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

    // Try strict → loose
    final candidates = <String>[
      '$a, ${widget.cityHint}, ${widget.regionHint}, ${widget.country}', // strict Karachi
      '$a, ${widget.cityHint}, ${widget.country}',                       // Karachi + PK
      '$a, ${widget.country}',                                           // PK only
      a,                                                                 // plain
    ];

    for (final q in candidates) {
      try {
        final hits = await geo.locationFromAddress(q);
        if (hits.isEmpty) continue;
        // choose first within Karachi bounds if possible
        geo.Location? picked;
        for (final h in hits) {
          final pos = LatLng(h.latitude, h.longitude);
          if (_inKarachi(pos)) {
            picked = h;
            break;
          }
        }
        picked ??= hits.first;
        final pos = LatLng(picked.latitude, picked.longitude);

        // If still outside Karachi after strict queries, treat as fail
        if (!_inKarachi(pos)) {
          continue;
        }

        _memCache[key] = pos;
        await _box.write(key, '${pos.latitude},${pos.longitude}');
        return pos;
      } catch (_) {
        // try next candidate
      }
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
      _failures.clear();
      _selected = null;
    });

    final model = context.read<GlobalBloc>().state.loginModel;
    final List<dynamic> plans =
        (model?.journeyPlan as List?) ?? const <dynamic>[];

    final rows = plans
        .map((p) => (
              area: _areaOf(p).trim(),
              shop: _shopOf(p).trim(),
              owner: _ownerOf(p).trim(),
              raw: p
            ))
        .toList();

    // Geocode all rows
    final futures = <Future<_GeoRow>>[];
    for (int i = 0; i < rows.length; i++) {
      futures.add(_geocodeRow(rows[i], i));
    }
    final results = await Future.wait(futures);

    // Prevent overlap for identical coords
    final samePosCounter = <String, int>{}; // "lat,lng" -> count
    final newMarkers = <Marker>{};

    for (final r in results) {
      if (r.pos == null) {
        _geocodeFail++;
        _failures.add(_FailureRow(
          area: r.area,
          shop: r.shop,
          reason: r.reason ?? 'Unable to mark this location.',
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
      ({String area, String shop, String owner, dynamic raw}) row,
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
    if (row.area.toLowerCase() == widget.country.toLowerCase()) {
      return _GeoRow(
        area: row.area,
        shop: row.shop,
        owner: row.owner,
        index: index,
        pos: null,
        reason: 'Area is too broad (“${widget.country}”).',
      );
    }

    final pos = await _geocodeAreaKarachiBiased(row.area);
    return _GeoRow(
      area: row.area,
      shop: row.shop,
      owner: row.owner,
      index: index,
      pos: pos,
      reason: pos == null
          ? 'Could not geocode within ${widget.cityHint}.'
          : null,
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
        title: const Text('Journey Plan — Shop Markers (Karachi)'),
        actions: [
          IconButton(
            tooltip: 'Clear geocode cache',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              // Clear only our keys to avoid nuking other storage
              final keys = _box.getKeys().where((k) => k.toString().startsWith('geo_area_')).toList();
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
              // If we already have a GPS fix when the map comes up, center immediately
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

          // status chip (OK/Fail) with viewer
          if (!_loading)
            Positioned(
              top: 12,
              left: 12,
              child: InkWell(
                onTap: _failures.isEmpty ? null : _showFailuresSheet,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: Color(0xFF1F2937)),
                      const SizedBox(width: 6),
                      Text(
                        'Markers: $_geocodeOk  •  Failed: $_geocodeFail',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_failures.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF6B7280)),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Loading pill
          if (_loading)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Placing markers…',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

          // Bottom info card for tapped marker
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _BottomInfoCard(
                selected: _selected!,
                onClose: () => setState(() => _selected = null),
                onCenterHere: () async {
                  final ctl = await _mapCtl.future;
                  await ctl.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                      target: _selected!.pos,
                      zoom: 17,
                    )),
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

  void _showFailuresSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unable to mark these locations',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _failures.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final f = _failures[i];
                    return ListTile(
                      leading: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                      title: Text(f.shop.isEmpty ? 'Shop' : f.shop,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${f.area.isEmpty ? '(no area)' : f.area} • ${f.reason}',
                      ),
                    );
                  },
                ),
              ),
            ],
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            // icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded, color: Color(0xFFEA7A3B)),
            ),
            const SizedBox(width: 10),
            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.shop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          selected.owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          selected.area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // actions
            IconButton(
              tooltip: 'Center here',
              icon: const Icon(Icons.center_focus_strong_rounded),
              onPressed: onCenterHere,
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            ),
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
  _GeoRow({
    required this.area,
    required this.shop,
    required this.owner,
    required this.index,
    required this.pos,
    this.reason,
  });
}

class _FailureRow {
  final String area;
  final String shop;
  final String reason;
  _FailureRow({required this.area, required this.shop, required this.reason});
}

class _Selected {
  final String shop;
  final String owner;
  final String area;
  final LatLng pos;
  final double? km; // null if my location unknown
  _Selected({
    required this.shop,
    required this.owner,
    required this.area,
    required this.pos,
    required this.km,
  });
}


// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:geocoding/geocoding.dart' as geo;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';



// /// Map screen that drops markers based on JourneyPlan.areaName (no lat/lng needed).
// class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
//   const AreaMarkersFromJourneyPlanMap({
//     super.key,
//     this.countryHint = 'Pakistan', // improves geocoding accuracy
//     this.autoFitAfterLoad = true,
//   });

//   /// Appended to area name when geocoding (e.g., "Gulshan-e-Iqbal, Pakistan").
//   final String? countryHint;

//   /// Fit camera to all markers after placing them.
//   final bool autoFitAfterLoad;

//   @override
//   State<AreaMarkersFromJourneyPlanMap> createState() =>
//       _AreaMarkersFromJourneyPlanMapState();
// }

// class _AreaMarkersFromJourneyPlanMapState
//     extends State<AreaMarkersFromJourneyPlanMap> {
//   final _box = GetStorage();
//   final _memCache = <String, LatLng>{};
//   final _markers = <Marker>{};
//   final _mapCtl = Completer<GoogleMapController>();
//   bool _loading = false;

//   static const _initialCamera = CameraPosition(
//     target: LatLng(24.8607, 67.0011), // Karachi fallback
//     zoom: 11,
//   );

//   @override
//   void initState() {
//     super.initState();
//     // Small delay so context is fully ready
//     WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndPlaceAll());
//   }

//   String _keyFor(String area) => 'geo_area_${area.trim().toLowerCase()}';

//   Future<LatLng?> _resolveArea(String areaName) async {
//     final norm = _keyFor(areaName);

//     // 1) memory cache
//     if (_memCache.containsKey(norm)) return _memCache[norm];

//     // 2) persistent cache
//     final cached = _box.read(norm);
//     if (cached is String && cached.contains(',')) {
//       final p = cached.split(',');
//       final lat = double.tryParse(p[0]);
//       final lng = double.tryParse(p[1]);
//       if (lat != null && lng != null) {
//         final pos = LatLng(lat, lng);
//         _memCache[norm] = pos;
//         return pos;
//       }
//     }

//     // 3) device geocoding
//     try {
//       final query = widget.countryHint == null || widget.countryHint!.isEmpty
//           ? areaName
//           : '$areaName, ${widget.countryHint}';
//       final hits = await geo.locationFromAddress(query);
//       if (hits.isNotEmpty) {
//         final pos = LatLng(hits.first.latitude, hits.first.longitude);
//         _memCache[norm] = pos;
//         await _box.write(norm, '${pos.latitude},${pos.longitude}');
//         return pos;
//       }
//     } catch (_) {
//       // swallow and return null
//     }
//     return null;
//   }

//   Future<void> _addMarkerForArea(String areaName,
//       {bool moveCamera = false}) async {
//     final pos = await _resolveArea(areaName);
//     if (pos == null) return;

//     setState(() {
//       _markers.removeWhere((m) => m.markerId.value == areaName);
//       _markers.add(
//         Marker(
//           markerId: MarkerId(areaName),
//           position: pos,
//           infoWindow: InfoWindow(title: areaName),
//         ),
//       );
//     });

//     if (moveCamera) {
//       final c = await _mapCtl.future;
//       await c.animateCamera(CameraUpdate.newLatLngZoom(pos, 14));
//     }
//   }

//   Future<void> _loadAndPlaceAll() async {
//     if (_loading) return;
//     setState(() => _loading = true);

//     // 1) read journey plan from bloc
//     final model =
//         context.read<GlobalBloc>().state.loginModel; // your existing state
//     final plans = model?.journeyPlan ?? const <dynamic>[];

//     // 2) extract unique, non-empty area names
//     final areas = <String>{};
//     for (final p in plans) {
//       final raw = (p.areaName ?? '').toString().trim();
//       if (raw.isNotEmpty) areas.add(raw);
//     }
//     final sorted = areas.toList()..sort();

//     // 3) sequentially resolve & add markers (keeps UI responsive)
//     for (final name in sorted) {
//       await _addMarkerForArea(name, moveCamera: false);
//     }

//     setState(() => _loading = false);

//     if (widget.autoFitAfterLoad) {
//       await _fitAllMarkers();
//     }
//   }

//   Future<void> _fitAllMarkers() async {
//     if (_markers.isEmpty) return;
//     final c = await _mapCtl.future;

//     // build bounds
//     double minLat = _markers.first.position.latitude;
//     double maxLat = minLat;
//     double minLng = _markers.first.position.longitude;
//     double maxLng = minLng;

//     for (final m in _markers) {
//       final p = m.position;
//       minLat = min(minLat, p.latitude);
//       maxLat = max(maxLat, p.latitude);
//       minLng = min(minLng, p.longitude);
//       maxLng = max(maxLng, p.longitude);
//     }

//     final bounds = LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );

//     await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
//   }

//   Future<void> _clearAllMarkers() async {
//     setState(() => _markers.clear());
//   }

//   Future<void> _clearGeoCache() async {
//     // remove only area keys to be safe
//     final keys = _box.getKeys().where((k) => k.toString().startsWith('geo_area_')).toList();
//     for (final k in keys) {
//       await _box.remove(k);
//     }
//     _memCache.clear();
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Area geocode cache cleared')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey Areas Map'),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh markers',
//             icon: const Icon(Icons.refresh_rounded),
//             onPressed: _loadAndPlaceAll,
//           ),
//           IconButton(
//             tooltip: 'Fit all',
//             icon: const Icon(Icons.fullscreen_rounded),
//             onPressed: _fitAllMarkers,
//           ),
//           PopupMenuButton<String>(
//             onSelected: (v) {
//               if (v == 'clear_markers') _clearAllMarkers();
//               if (v == 'clear_cache') _clearGeoCache();
//             },
//             itemBuilder: (_) => const [
//               PopupMenuItem(value: 'clear_markers', child: Text('Clear markers')),
//               PopupMenuItem(value: 'clear_cache', child: Text('Clear geocode cache')),
//             ],
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: _initialCamera,
//             markers: _markers,
//             onMapCreated: (c) => _mapCtl.complete(c),
//             myLocationEnabled: false,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//           ),

//           // loading banner
//           if (_loading)
//             Align(
//               alignment: Alignment.topCenter,
//               child: Container(
//                 margin: const EdgeInsets.only(top: 12),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(.55),
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     SizedBox(
//                       height: 14, width: 14,
//                       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                     ),
//                     SizedBox(width: 8),
//                     Text('Placing markers…', style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),

//       // Bottom action bar
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     backgroundColor: const Color(0xFFEA7A3B),
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: _loadAndPlaceAll,
//                   icon: const Icon(Icons.place_rounded),
//                   label: const Text('Mark Journey Areas'),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               IconButton(
//                 tooltip: 'Fit',
//                 style: IconButton.styleFrom(
//                   backgroundColor: const Color(0xFFF3F4F6),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 onPressed: _fitAllMarkers,
//                 icon: const Icon(Icons.center_focus_strong_rounded, color: Color(0xFF1F2937)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
