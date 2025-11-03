import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';

// journey_plan_map_single_file.dart
// Drop-in single file. Requires: google_maps_flutter, geocoding, location, get_storage, flutter_bloc.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart' as loc;

// journey_plan_map_single_file.dart
// Single-file Google Map for JourneyPlan with areaName parsing:
// last token = City, second-last token = Area (for geocoding).

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart' as loc;



// area_markers_from_journey_plan_map.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:flutter_bloc/flutter_bloc.dart';


// AreaMarkersFromJourneyPlanMap.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:flutter_bloc/flutter_bloc.dart';

// Import your GlobalBloc / models
// import 'path_to_your_bloc/global_bloc.dart';
// import 'path_to_your_models/login_model.dart';

class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
  const AreaMarkersFromJourneyPlanMap({
    super.key,
    this.cityHint = 'Karachi',
    this.regionHint = 'Sindh',
    this.country = 'Pakistan',
    this.autoFitAfterLoad = true,
  });

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
  // --- Storage / caches ---
  final _box = GetStorage();
  final _memCache = <String, LatLng>{};

  // --- Map / location ---
  final _markers = <Marker>{};
  final _mapCtl = Completer<GoogleMapController>();
  final _loc = loc.Location();
  LatLng? _myLoc;

  // --- UI / filtering ---
  final _searchCtl = TextEditingController();
  String? _filterArea;      // areaName
  String? _filterAddress;   // custAddress
  final _areas = <String>[];     // distinct areaName values
  final _addresses = <String>[]; // distinct custAddress values

  // --- Status ---
  bool _loading = false;
  int _geocodeOk = 0;
  int _geocodeFail = 0;
  int _dupSkipped = 0;
  _Selected? _selected;
  final List<_FailureRow> _failures = [];
  final List<_DupRow> _dups = [];

  // --- Karachi bias / bounds ---
  static const _KARACHI_MIN_LAT = 24.75;
  static const _KARACHI_MAX_LAT = 25.10;
  static const _KARACHI_MIN_LNG = 66.65;
  static const _KARACHI_MAX_LNG = 67.45;

  static const _karachiCenter = LatLng(24.8607, 67.0011);
  static const _fallbackCamera = CameraPosition(
    target: _karachiCenter,
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    // seed lookups from current model
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMyLocation();
      _rebuildFilterChoices();        // build dropdown choices
      await _applyFiltersAndReload(); // place markers for current filters
      if (_myLoc != null) {
        await _centerOnMyLocation(initial: true);
      } else if (_markers.isNotEmpty && widget.autoFitAfterLoad) {
        await _fitAllMarkers();
      } else {
        await _centerOnKarachi();
      }
    });

    // live search filtering
    _searchCtl.addListener(() {
      // Apply a tiny debounce effect
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _applyFiltersAndReload();
      });
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
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

  // -------------------- Safe extractors --------------------
  String _safeLower(dynamic v) =>
      v == null ? '' : v.toString().trim().toLowerCase();

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

  String _addressOf(dynamic plan) {
    try {
      final v = (plan as dynamic).custAddress;
      if (v != null) return v.toString();
    } catch (_) {}
    if (plan is Map) {
      final v = plan['custAddress'];
      if (v != null) return v.toString();
    }
    return '';
  }

  /// Prefer journeyId; fallback to deterministic composite key
  String _planKey(dynamic p) {
    try {
      final jid = ((p as dynamic).journeyId ?? '').toString().trim();
      if (jid.isNotEmpty) return 'jid:$jid';
    } catch (_) {}
    final accode = _safeLower((p as dynamic).accode);
    final name   = _safeLower((p as dynamic).partyName);
    final addr   = _safeLower((p as dynamic).custAddress);
    final area   = _safeLower((p as dynamic).areaName);
    return 'ac:$accode|nm:$name|ad:$addr|ar:$area';
  }

  // -------------------- Distinct choices for dropdowns --------------------
  List<dynamic> _allPlans() {
    final model = context.read<GlobalBloc>().state.loginModel;
    return (model?.journeyPlan as List?) ?? const <dynamic>[];
  }

  void _rebuildFilterChoices() {
    final plans = _allPlans();
    final aSet = <String>{};
    final adSet = <String>{};

    for (final p in plans) {
      final area = _areaOf(p).trim();
      final addr = _addressOf(p).trim();
      if (area.isNotEmpty) aSet.add(area);
      if (addr.isNotEmpty) adSet.add(addr);
    }

    final areas = aSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
    final addrs = adSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      _areas
        ..clear()
        ..addAll(areas);
      _addresses
        ..clear()
        ..addAll(addrs);

      // keep existing selection if still valid, else clear
      if (_filterArea != null && !_areas.contains(_filterArea)) _filterArea = null;
      if (_filterAddress != null && !_addresses.contains(_filterAddress)) _filterAddress = null;
    });
  }

  // -------------------- Karachi-biased geocoding --------------------
  bool _inKarachi(LatLng p) {
    return p.latitude >= _KARACHI_MIN_LAT &&
        p.latitude <= _KARACHI_MAX_LAT &&
        p.longitude >= _KARACHI_MIN_LNG &&
        p.longitude <= _KARACHI_MAX_LNG;
  }

  String _cacheKey(String area) =>
      'geo_area_${area.trim().toLowerCase()}__${widget.cityHint.toLowerCase()}';

  Future<LatLng?> _geocodeAreaKarachiBiased(String areaName) async {
    final a = areaName.trim();
    if (a.isEmpty) return null;
    if (a.toLowerCase() == widget.country.toLowerCase()) return null;

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

    final candidates = <String>[
      '$a, ${widget.cityHint}, ${widget.regionHint}, ${widget.country}',
      '$a, ${widget.cityHint}, ${widget.country}',
      '$a, ${widget.country}',
      a,
    ];

    for (final q in candidates) {
      try {
        final hits = await geo.locationFromAddress(q);
        if (hits.isEmpty) continue;
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
        if (!_inKarachi(pos)) continue;

        _memCache[key] = pos;
        await _box.write(key, '${pos.latitude},${pos.longitude}');
        return pos;
      } catch (_) {/* try next */}
    }
    return null;
  }

  // -------------------- Filtering + Marker placement --------------------
  Future<void> _applyFiltersAndReload() async {
    if (_loading) return;

    // Build filtered base set (search + area + address)
    final plans = _allPlans();
    final q = _searchCtl.text.trim().toLowerCase();
    final areaSel = _filterArea?.trim();
    final addrSel = _filterAddress?.trim();

    Iterable<dynamic> filtered = plans.where((p) {
      final shop  = _safeLower(_shopOf(p));
      final owner = _safeLower(_ownerOf(p));
      final area  = _safeLower(_areaOf(p));
      final addr  = _safeLower(_addressOf(p));

      final matchesSearch = q.isEmpty || shop.contains(q) || owner.contains(q) || area.contains(q);
      final matchesArea   = areaSel == null || area == _safeLower(areaSel);
      final matchesAddr   = addrSel == null || addr == _safeLower(addrSel);

      return matchesSearch && matchesArea && matchesAddr;
    });

    // de-dup by journeyId (or composite)
    final seen = <String>{};
    final dedup = <dynamic>[];
    for (final p in filtered) {
      final key = _planKey(p);
      if (seen.add(key)) dedup.add(p);
    }

    await _placeMarkersFrom(dedup);
  }

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

  Future<void> _placeMarkersFrom(List<dynamic> filteredPlans) async {
    setState(() {
      _loading = true;
      _geocodeOk = 0;
      _geocodeFail = 0;
      _dupSkipped = 0; // dups are handled before geocode now
      _failures.clear();
      _dups.clear();
      _selected = null;
    });

    // rows for geocode
    final rows = filteredPlans
        .map((p) => (
              area: _areaOf(p).trim(),
              shop: _shopOf(p).trim(),
              owner: _ownerOf(p).trim(),
            ))
        .toList();

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
      ({String area, String shop, String owner}) row, int index) async {
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
        title: const Text('Journey Plan — Map Filters'),
        actions: [
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _centerOnMyLocation,
          ),
          IconButton(
            tooltip: 'Fit all markers',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: _fitAllMarkers,
          ),
          IconButton(
            tooltip: 'Clear geocode cache',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final keys = _box.getKeys()
                  .where((k) => k.toString().startsWith('geo_area_'))
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

          // Floating filter panel
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _FilterPanel(
              searchCtl: _searchCtl,
              areas: _areas,
              addresses: _addresses,
              filterArea: _filterArea,
              filterAddress: _filterAddress,
              onAreaChanged: (v) {
                setState(() => _filterArea = v?.isEmpty == true ? null : v);
                _applyFiltersAndReload();
              },
              onAddressChanged: (v) {
                setState(() => _filterAddress = v?.isEmpty == true ? null : v);
                _applyFiltersAndReload();
              },
              onReset: () {
                setState(() {
                  _searchCtl.text = '';
                  _filterArea = null;
                  _filterAddress = null;
                });
                _applyFiltersAndReload();
              },
            ),
          ),

          // status chip (OK/Fail/Dups) with viewer
          if (!_loading)
            Positioned(
              top: 120,
              left: 12,
              child: InkWell(
                onTap: (_failures.isEmpty && _dups.isEmpty) ? null : _showStatusSheet,
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
                      if (_failures.isNotEmpty || _dups.isNotEmpty) ...[
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
                margin: const EdgeInsets.only(top: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Text('Placing markers…', style: TextStyle(color: Colors.white)),
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
        backgroundColor: const Color(0xFFEA7A3B),
        onPressed: _fitAllMarkers,
        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
        label: const Text('View All Markers', style: TextStyle(color: Colors.white)),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Placement report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),

                if (_dups.isNotEmpty) ...[
                  Row(
                    children: const [
                      Icon(Icons.copy_rounded, color: Colors.amber),
                      SizedBox(width: 6),
                      Text('Skipped duplicates (same Journey ID)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
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
                  Row(
                    children: const [
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                      SizedBox(width: 6),
                      Text('Unable to mark these locations',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _failures.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = _failures[i];
                      return ListTile(
                        leading: const Icon(Icons.place_rounded, color: Colors.redAccent),
                        title: Text(f.shop.isEmpty ? 'Shop' : f.shop,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${f.area.isEmpty ? "(no area)" : f.area} • ${f.reason}'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- Filter Panel --------------------
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchCtl,
    required this.areas,
    required this.addresses,
    required this.filterArea,
    required this.filterAddress,
    required this.onAreaChanged,
    required this.onAddressChanged,
    required this.onReset,
  });

  final TextEditingController searchCtl;
  final List<String> areas;
  final List<String> addresses;
  final String? filterArea;
  final String? filterAddress;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String?> onAddressChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
        child: Column(
          children: [
            // Search
            Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtl,
                    decoration: const InputDecoration(
                      hintText: 'Search shop / owner / area',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (searchCtl.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => searchCtl.clear(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Dropdowns
            Row(
              children: [
                Expanded(
                  child: _DropdownBox(
                    label: 'Area',
                    value: filterArea,
                    items: const [''] + ([]) // placeholder, replaced below
                      ..clear(), // just to keep analyzer happy
                    // We'll build via builder param:
                    builder: (ctx) => areas,
                    onChanged: onAreaChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownBox(
                    label: 'Address',
                    value: filterAddress,
                    items: const [''],
                    builder: (ctx) => addresses,
                    onChanged: onAddressChanged,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ItemsBuilder = List<String> Function(BuildContext);

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.builder,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final _ItemsBuilder builder;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final built = builder(context);
    final menu = ['(All)'] + built;
    final current = value == null ? '(All)' : value!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E9EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: (menu.contains(current)) ? current : '(All)',
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: menu
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v == '(All)' ? null : v),
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

class _DupRow {
  final String jid;
  final String area;
  final String shop;
  final String owner;
  _DupRow({
    required this.jid,
    required this.area,
    required this.shop,
    required this.owner,
  });
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




// class JourneyPlanMapSingleFile extends StatefulWidget {
//   const JourneyPlanMapSingleFile({super.key});

//   @override
//   State<JourneyPlanMapSingleFile> createState() => _JourneyPlanMapSingleFileState();
// }

// class _JourneyPlanMapSingleFileState extends State<JourneyPlanMapSingleFile> {
//   final _box = GetStorage();

//   // map + loc
//   final _mapCtl = Completer<GoogleMapController>();
//   final _markers = <Marker>{};
//   final _loc = loc.Location();
//   LatLng? _myLoc;

//   // geocode cache
//   final _memCache = <String, LatLng>{};

//   // filters
//   final _searchCtl = TextEditingController();
//   String? _filterArea;
//   String? _filterAddress;
//   final _areas = <String>[];
//   final _addresses = <String>[];

//   // status & selections
//   bool _loading = false;
//   int _geocodeOk = 0;
//   int _geocodeFail = 0;
//   int _dupSkipped = 0;
//   final _failures = <_FailureRow>[];
//   final _dups = <_DupRow>[];
//   _Selected? _selected;

//   static const _fallbackCamera = CameraPosition(target: LatLng(20, 0), zoom: 2.5);

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _ensureMyLocation();
//       _rebuildFilterChoices();
//       await _applyFiltersAndReload();
//       if (_myLoc != null) {
//         await _centerOnMyLocation(initial: true);
//       } else if (_markers.isNotEmpty) {
//         await _fitAllMarkers();
//       }
//     });
//     _searchCtl.addListener(() {
//       Future.delayed(const Duration(milliseconds: 120), () {
//         if (!mounted) return;
//         _applyFiltersAndReload();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchCtl.dispose();
//     super.dispose();
//   }

//   // -------- current location --------
//   Future<void> _ensureMyLocation() async {
//     try {
//       final p = await _loc.hasPermission();
//       if (p == loc.PermissionStatus.denied || p == loc.PermissionStatus.deniedForever) {
//         final r = await _loc.requestPermission();
//         if (r != loc.PermissionStatus.granted) return;
//       }
//       var svc = await _loc.serviceEnabled();
//       if (!svc) {
//         svc = await _loc.requestService();
//         if (!svc) return;
//       }
//       final l = await _loc.getLocation();
//       if (l.latitude != null && l.longitude != null) {
//         setState(() => _myLoc = LatLng(l.latitude!, l.longitude!));
//       }
//     } catch (_) {}
//   }

//   Future<void> _centerOnMyLocation({bool initial = false}) async {
//     final ctl = await _mapCtl.future;
//     final t = _myLoc ?? const LatLng(20, 0);
//     await ctl.animateCamera(CameraUpdate.newCameraPosition(
//       CameraPosition(target: t, zoom: initial ? 16 : 15.5),
//     ));
//   }

//   // -------- data access helpers --------
//   List<dynamic> _allPlans() {
//     final model = context.read<GlobalBloc>().state.loginModel;
//     return (model?.journeyPlan as List?) ?? const <dynamic>[];
//   }

//   String _safeLower(dynamic v) => v == null ? '' : v.toString().trim().toLowerCase();

//   String _areaName(dynamic p) {
//     try {
//       final v = (p as dynamic).areaName;
//       if (v != null) return v.toString();
//     } catch (_) {}
//     if (p is Map) {
//       final v = p['areaName'];
//       if (v != null) return v.toString();
//     }
//     return '';
//   }

//   String _shopOf(dynamic p) {
//     final tryKeys = ['partyName', 'shopName', 'name', 'outlet', 'customerName'];
//     try {
//       final v = (p as dynamic).partyName;
//       if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//     } catch (_) {}
//     if (p is Map) {
//       for (final k in tryKeys) {
//         final v = p[k];
//         if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//       }
//     }
//     return 'Shop';
//   }

//   String _ownerOf(dynamic p) {
//     final tryKeys = [
//       'ownerName','owner','proprietor','contactPerson','contact_name',
//       'personName','custOwner','shopOwner'
//     ];
//     try {
//       final v = (p as dynamic).ownerName;
//       if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//     } catch (_) {}
//     if (p is Map) {
//       for (final k in tryKeys) {
//         final v = p[k];
//         if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//       }
//     }
//     return '—';
//   }

//   String _addressOf(dynamic p) {
//     try {
//       final v = (p as dynamic).custAddress;
//       if (v != null) return v.toString();
//     } catch (_) {}
//     if (p is Map) {
//       final v = p['custAddress'];
//       if (v != null) return v.toString();
//     }
//     return '';
//   }

//   /// Prefer journeyId when available; else composite
//   String _planKey(dynamic p) {
//     for (final k in const [
//       'journeyId','JourneyId','journyId','journeyid',
//       'jpId','jp_id','JPId','jid','JID',
//       'routeId','route_id','journey_id','planId','PlanId'
//     ]) {
//       try {
//         if (p is Map && p[k] != null) {
//           final v = p[k].toString().trim();
//           if (v.isNotEmpty) return 'jid:$v';
//         }
//         final v = (p as dynamic).toJson?.call()[k];
//         if (v != null && v.toString().trim().isNotEmpty) {
//           return 'jid:${v.toString().trim()}';
//         }
//       } catch (_) {}
//     }
//     final accode = _safeLower((p as dynamic).accode);
//     final name   = _safeLower((p as dynamic).partyName);
//     final addr   = _safeLower((p as dynamic).custAddress);
//     final area   = _safeLower((p as dynamic).areaName);
//     return 'ac:$accode|nm:$name|ad:$addr|ar:$area';
//   }

//   // -------- filter building --------
//   void _rebuildFilterChoices() {
//     final plans = _allPlans();
//     final aSet = <String>{};
//     final adSet = <String>{};
//     for (final p in plans) {
//       final area = _areaName(p).trim();
//       final addr = _addressOf(p).trim();
//       if (area.isNotEmpty) aSet.add(area);
//       if (addr.isNotEmpty) adSet.add(addr);
//     }
//     final areas = aSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
//     final addrs = adSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
//     setState(() {
//       _areas..clear()..addAll(areas);
//       _addresses..clear()..addAll(addrs);
//       if (_filterArea != null && !_areas.contains(_filterArea)) _filterArea = null;
//       if (_filterAddress != null && !_addresses.contains(_filterAddress)) _filterAddress = null;
//     });
//   }

//   Future<void> _applyFiltersAndReload() async {
//     if (_loading) return;

//     final plans = _allPlans();
//     final q = _searchCtl.text.trim().toLowerCase();
//     final areaSel = _filterArea?.trim();
//     final addrSel = _filterAddress?.trim();

//     Iterable<dynamic> filtered = plans.where((p) {
//       final shop  = _safeLower(_shopOf(p));
//       final owner = _safeLower(_ownerOf(p));
//       final area  = _safeLower(_areaName(p));
//       final addr  = _safeLower(_addressOf(p));
//       final matchesSearch = q.isEmpty || shop.contains(q) || owner.contains(q) || area.contains(q);
//       final matchesArea   = areaSel == null || area == _safeLower(areaSel);
//       final matchesAddr   = addrSel == null || addr == _safeLower(addrSel);
//       return matchesSearch && matchesArea && matchesAddr;
//     });

//     // de-dupe
//     _dupSkipped = 0;
//     final seen = <String>{};
//     final dedup = <dynamic>[];
//     for (final p in filtered) {
//       final k = _planKey(p);
//       if (seen.add(k)) dedup.add(p);
//       else _dupSkipped++;
//     }

//     await _placeMarkersFrom(dedup);
//   }

//   // ----------------- areaName parsing (last = City, second-last = Area) -----------------
//   /// Given areaName, returns (areaToken, cityToken).
//   /// Rules:
//   /// 1) If it has commas, use non-empty segments: city = last seg, area = second-last seg.
//   /// 2) Else split by whitespace: city = last token, area = second-last token.
//   /// If not enough parts, area/city may be empty.
//   ({String areaToken, String cityToken}) _parseAreaCity(String raw) {
//     final s = raw.trim();
//     if (s.isEmpty) return (areaToken: '', cityToken: '');
//     final commaParts = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
//     if (commaParts.length >= 2) {
//       return (areaToken: commaParts[commaParts.length - 2], cityToken: commaParts.last);
//     }
//     final tokens = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
//     if (tokens.length >= 2) {
//       return (areaToken: tokens[tokens.length - 2], cityToken: tokens.last);
//     }
//     // not enough info
//     return (areaToken: s, cityToken: '');
//   }

//   // Optional global bias hints used anywhere in app via GetStorage.
//   String? get _hintCity    => _asNonEmpty(_box.read('geo_bias_city'));
//   String? get _hintRegion  => _asNonEmpty(_box.read('geo_bias_region'));
//   String? get _hintCountry => _asNonEmpty(_box.read('geo_bias_country'));
//   String? _asNonEmpty(dynamic v) {
//     final s = (v ?? '').toString().trim();
//     return s.isEmpty ? null : s;
//   }

//   String _cacheKey(String areaName) {
//     final ss = areaName.trim().toLowerCase();
//     final c = (_hintCity ?? '').toLowerCase();
//     final r = (_hintRegion ?? '').toLowerCase();
//     final co = (_hintCountry ?? '').toLowerCase();
//     return 'geo_area_parse__${ss}__${c}__${r}__$co';
//   }

//   /// Geocode using parsed areaName: "(second-last token), (last token)".
//   /// Falls back to original full string and area-only.
//   Future<LatLng?> _geocodeAreaParsed(String areaName) async {
//     final (areaToken: area, cityToken: city) = _parseAreaCity(areaName);

//     // Skip obvious country-only entries like "Pakistan"
//     if (areaName.toLowerCase() == 'pakistan' ||
//         city.toLowerCase() == 'pakistan' ||
//         (_hintCountry != null && areaName.toLowerCase() == _hintCountry!.toLowerCase())) {
//       return null;
//     }

//     final key = _cacheKey(areaName);
//     if (_memCache.containsKey(key)) return _memCache[key];
//     final cached = _box.read(key);
//     if (cached is String && cached.contains(',')) {
//       final parts = cached.split(',');
//       final lat = double.tryParse(parts[0]);
//       final lng = double.tryParse(parts[1]);
//       if (lat != null && lng != null) {
//         final pos = LatLng(lat, lng);
//         _memCache[key] = pos;
//         return pos;
//       }
//     }

//     // Build candidate queries with strict rule first, then soften.
//     final candidates = <String>[
//       if (area.isNotEmpty && city.isNotEmpty) '$area, $city',
//       if (area.isNotEmpty && city.isNotEmpty && _hintCountry != null)
//         '$area, $city, ${_hintCountry!}',
//       if (area.isNotEmpty && city.isNotEmpty && _hintRegion != null && _hintCountry != null)
//         '$area, $city, ${_hintRegion!}, ${_hintCountry!}',
//       if (area.isNotEmpty) area,
//       areaName, // original full
//       if (city.isNotEmpty) city, // last token alone (rarely useful, but safe fallback)
//     ];

//     geo.Location? best;
//     double bestScore = double.infinity;

//     for (final q in candidates) {
//       if (q.trim().isEmpty) continue;
//       try {
//         final hits = await geo.locationFromAddress(q);
//         if (hits.isEmpty) continue;

//         if (_myLoc != null) {
//           for (final h in hits) {
//             final d = _sqDist(_myLoc!, LatLng(h.latitude, h.longitude));
//             if (d < bestScore) {
//               bestScore = d;
//               best = h;
//             }
//           }
//         } else {
//           best ??= hits.first;
//         }
//       } catch (_) {/* try next */}
//     }

//     if (best == null) return null;

//     final pos = LatLng(best.latitude, best.longitude);
//     _memCache[key] = pos;
//     await _box.write(key, '${pos.latitude},${pos.longitude}');
//     return pos;
//   }

//   double _sqDist(LatLng a, LatLng b) {
//     final dx = a.latitude - b.latitude;
//     final dy = a.longitude - b.longitude;
//     return dx * dx + dy * dy;
//   }

//   // -------- markers placement --------
//   LatLng _withJitter(LatLng base, int indexOnSamePoint) {
//     if (indexOnSamePoint <= 0) return base;
//     const step = 0.0002; // ~22m
//     final angle = (indexOnSamePoint % 12) * (2 * pi / 12);
//     final radius = step * ((indexOnSamePoint ~/ 12) + 1);
//     return LatLng(
//       base.latitude + radius * sin(angle),
//       base.longitude + radius * cos(angle),
//     );
//   }

//   Future<void> _placeMarkersFrom(List<dynamic> filteredPlans) async {
//     setState(() {
//       _loading = true;
//       _geocodeOk = 0;
//       _geocodeFail = 0;
//       _failures.clear();
//       _dups.clear();
//       _selected = null;
//     });

//     final rows = filteredPlans
//         .map((p) => (
//               areaName: _areaName(p).trim(),
//               shop: _shopOf(p).trim(),
//               owner: _ownerOf(p).trim(),
//             ))
//         .toList();

//     final futures = <Future<_GeoRow>>[];
//     for (int i = 0; i < rows.length; i++) {
//       futures.add(_geocodeRow(rows[i], i));
//     }

//     final results = await Future.wait(futures);
//     final samePosCounter = <String, int>{};
//     final newMarkers = <Marker>{};

//     for (final r in results) {
//       if (r.pos == null) {
//         _geocodeFail++;
//         _failures.add(_FailureRow(
//           area: r.areaName,
//           shop: r.shop,
//           reason: r.reason ?? 'Unable to mark this location.',
//         ));
//         continue;
//       }

//       _geocodeOk++;
//       final roundedKey =
//           '${r.pos!.latitude.toStringAsFixed(5)},${r.pos!.longitude.toStringAsFixed(5)}';
//       final idxOnSame =
//           samePosCounter.update(roundedKey, (v) => v + 1, ifAbsent: () => 0);

//       final effectivePos = _withJitter(r.pos!, idxOnSame);
//       final markerId = 'shop_${r.index}_${r.areaName}_${r.shop}';

//       newMarkers.add(
//         Marker(
//           markerId: MarkerId(markerId),
//           position: effectivePos,
//           infoWindow: InfoWindow(
//             title: r.shop.isEmpty ? 'Shop' : r.shop,
//             snippet: r.owner.isNotEmpty ? 'Owner: ${r.owner}' : r.areaName,
//           ),
//           onTap: () => _onMarkerTap(
//             shop: r.shop.isEmpty ? 'Shop' : r.shop,
//             owner: r.owner.isEmpty ? '—' : r.owner,
//             area: r.areaName,
//             pos: effectivePos,
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers
//         ..clear()
//         ..addAll(newMarkers);
//       _loading = false;
//     });
//   }

//   Future<_GeoRow> _geocodeRow(
//       ({String areaName, String shop, String owner}) row, int index) async {
//     if (row.areaName.isEmpty) {
//       return _GeoRow(
//         areaName: row.areaName,
//         shop: row.shop,
//         owner: row.owner,
//         index: index,
//         pos: null,
//         reason: 'Missing area name.',
//       );
//     }
//     if (row.areaName.toLowerCase() == 'pakistan' ||
//         (_hintCountry != null &&
//             row.areaName.toLowerCase() == _hintCountry!.toLowerCase())) {
//       return _GeoRow(
//         areaName: row.areaName,
//         shop: row.shop,
//         owner: row.owner,
//         index: index,
//         pos: null,
//         reason: 'Area too broad (country).',
//       );
//     }

//     final pos = await _geocodeAreaParsed(row.areaName);
//     return _GeoRow(
//       areaName: row.areaName,
//       shop: row.shop,
//       owner: row.owner,
//       index: index,
//       pos: pos,
//       reason: pos == null ? 'Could not geocode using (Area, City) rule.' : null,
//     );
//   }

//   // -------- marker tap / distance --------
//   void _onMarkerTap({
//     required String shop,
//     required String owner,
//     required String area,
//     required LatLng pos,
//   }) {
//     final km = (_myLoc == null) ? null : _distanceKm(_myLoc!, pos);
//     setState(() {
//       _selected = _Selected(shop: shop, owner: owner, area: area, pos: pos, km: km);
//     });
//   }

//   double _distanceKm(LatLng a, LatLng b) {
//     const R = 6371.0;
//     final dLat = _deg2rad(b.latitude - a.latitude);
//     final dLng = _deg2rad(b.longitude - a.longitude);
//     final la1 = _deg2rad(a.latitude);
//     final la2 = _deg2rad(b.latitude);
//     final h = sin(dLat/2)*sin(dLat/2) + sin(dLng/2)*sin(dLng/2)*cos(la1)*cos(la2);
//     final c = 2 * atan2(sqrt(h), sqrt(1 - h));
//     return R * c;
//   }
//   double _deg2rad(double d) => d * (pi / 180.0);

//   // -------- camera fit --------
//   Future<void> _fitAllMarkers() async {
//     if (_markers.isEmpty) return;
//     final c = await _mapCtl.future;

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

//   // -------- optional bias hints editor --------
//   Future<void> _editBiasHints() async {
//     final cityCtl = TextEditingController(text: _hintCity ?? '');
//     final regionCtl = TextEditingController(text: _hintRegion ?? '');
//     final countryCtl = TextEditingController(text: _hintCountry ?? '');

//     final saved = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Geocoding Bias (optional)'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Helps when area/city names are ambiguous.'),
//             const SizedBox(height: 12),
//             TextField(
//               controller: cityCtl,
//               decoration: const InputDecoration(
//                 labelText: 'City (optional)', prefixIcon: Icon(Icons.location_city),
//               ),
//             ),
//             TextField(
//               controller: regionCtl,
//               decoration: const InputDecoration(
//                 labelText: 'Region/State (optional)', prefixIcon: Icon(Icons.map),
//               ),
//             ),
//             TextField(
//               controller: countryCtl,
//               decoration: const InputDecoration(
//                 labelText: 'Country (optional)', prefixIcon: Icon(Icons.public),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: ()=> Navigator.pop(context, false), child: const Text('Cancel')),
//           ElevatedButton(onPressed: ()=> Navigator.pop(context, true), child: const Text('Save')),
//         ],
//       ),
//     );

//     if (saved == true) {
//       await _box.write('geo_bias_city', cityCtl.text.trim());
//       await _box.write('geo_bias_region', regionCtl.text.trim());
//       await _box.write('geo_bias_country', countryCtl.text.trim());

//       // Clear geocode cache because hints changed
//       final keys = _box.getKeys().where((k) => k.toString().startsWith('geo_area_') || k.toString().startsWith('geo_area_parse__')).toList();
//       for (final k in keys) {
//         await _box.remove(k);
//       }
//       _memCache.clear();

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Saved. Reloading markers with new hints…')),
//       );
//       await _applyFiltersAndReload();
//       if (_markers.isNotEmpty) await _fitAllMarkers();
//     }
//   }

//   // -------- UI --------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey Plan — Area Markers (Area=2nd-last, City=last)'),
//         actions: [
//           IconButton(
//             tooltip: 'Bias hints (optional)',
//             icon: const Icon(Icons.public_rounded),
//             onPressed: _editBiasHints,
//           ),
//           IconButton(
//             tooltip: 'My location',
//             icon: const Icon(Icons.my_location_rounded),
//             onPressed: _centerOnMyLocation,
//           ),
//           IconButton(
//             tooltip: 'Fit all markers',
//             icon: const Icon(Icons.fullscreen_rounded),
//             onPressed: _fitAllMarkers,
//           ),
//           IconButton(
//             tooltip: 'Clear geocode cache',
//             icon: const Icon(Icons.delete_sweep_rounded),
//             onPressed: () async {
//               final keys = _box.getKeys()
//                   .where((k) => k.toString().startsWith('geo_area_') || k.toString().startsWith('geo_area_parse__'))
//                   .toList();
//               for (final k in keys) {
//                 await _box.remove(k);
//               }
//               _memCache.clear();
//               if (!mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Geocode cache cleared')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: _fallbackCamera,
//             onMapCreated: (c) async {
//               _mapCtl.complete(c);
//               if (_myLoc != null) {
//                 await _centerOnMyLocation(initial: true);
//               }
//             },
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             compassEnabled: true,
//             markers: _markers,
//           ),

//           // filter/search panel
//           Positioned(
//             top: 12,
//             left: 12,
//             right: 12,
//             child: _FilterPanel(
//               searchCtl: _searchCtl,
//               areas: _areas,
//               addresses: _addresses,
//               filterArea: _filterArea,
//               filterAddress: _filterAddress,
//               onAreaChanged: (v) {
//                 setState(() => _filterArea = v?.isEmpty == true ? null : v);
//                 _applyFiltersAndReload();
//               },
//               onAddressChanged: (v) {
//                 setState(() => _filterAddress = v?.isEmpty == true ? null : v);
//                 _applyFiltersAndReload();
//               },
//               onReset: () {
//                 setState(() {
//                   _searchCtl.text = '';
//                   _filterArea = null;
//                   _filterAddress = null;
//                 });
//                 _applyFiltersAndReload();
//               },
//             ),
//           ),

//           // status chip
//           if (!_loading)
//             Positioned(
//               top: 120,
//               left: 12,
//               child: InkWell(
//                 onTap: (_failures.isEmpty && _dups.isEmpty) ? null : _showStatusSheet,
//                 borderRadius: BorderRadius.circular(999),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(999),
//                     boxShadow: const [
//                       BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
//                     ],
//                     border: Border.all(color: const Color(0xFFEAEAEA)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.place_rounded, size: 16, color: Color(0xFF1F2937)),
//                       const SizedBox(width: 6),
//                       Text(
//                         'Markers: $_geocodeOk  •  Failed: $_geocodeFail  •  Dups: $_dupSkipped',
//                         style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700),
//                       ),
//                       if (_failures.isNotEmpty || _dups.isNotEmpty) ...[
//                         const SizedBox(width: 8),
//                         const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF6B7280)),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // loading pill
//           if (_loading)
//             Align(
//               alignment: Alignment.topCenter,
//               child: Container(
//                 margin: const EdgeInsets.only(top: 120),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(.55),
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
//                     SizedBox(width: 8),
//                     Text('Placing markers…', style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),

//           // bottom info card
//           if (_selected != null)
//             Positioned(
//               left: 12,
//               right: 12,
//               bottom: 16,
//               child: _BottomInfoCard(
//                 selected: _selected!,
//                 onClose: () => setState(() => _selected = null),
//                 onCenterHere: () async {
//                   final ctl = await _mapCtl.future;
//                   await ctl.animateCamera(
//                     CameraUpdate.newCameraPosition(CameraPosition(target: _selected!.pos, zoom: 17)),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: const Color(0xFFEA7A3B),
//         onPressed: _fitAllMarkers,
//         icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
//         label: const Text('View All Markers', style: TextStyle(color: Colors.white)),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }

//   void _showStatusSheet() {
//     showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       isScrollControlled: true,
//       builder: (_) => SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Placement report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
//                 const SizedBox(height: 12),

//                 if (_dups.isNotEmpty) ...[
//                   Row(
//                     children: const [
//                       Icon(Icons.copy_rounded, color: Colors.amber),
//                       SizedBox(width: 6),
//                       Text('Skipped duplicates (same Journey ID)', style: TextStyle(fontWeight: FontWeight.w700)),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _dups.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (_, i) {
//                       final d = _dups[i];
//                       return ListTile(
//                         leading: const Icon(Icons.remove_circle_outline, color: Colors.amber),
//                         title: Text(d.shop.isEmpty ? 'Shop' : d.shop, style: const TextStyle(fontWeight: FontWeight.w700)),
//                         subtitle: Text('JID: ${d.jid} • ${d.area.isEmpty ? "(no area)" : d.area} • ${d.owner}'),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                 ],

//                 if (_failures.isNotEmpty) ...[
//                   Row(
//                     children: const [
//                       Icon(Icons.error_outline_rounded, color: Colors.redAccent),
//                       SizedBox(width: 6),
//                       Text('Unable to mark these locations', style: TextStyle(fontWeight: FontWeight.w700)),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _failures.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (_, i) {
//                       final f = _failures[i];
//                       return ListTile(
//                         leading: const Icon(Icons.place_rounded, color: Colors.redAccent),
//                         title: Text(f.shop.isEmpty ? 'Shop' : f.shop, style: const TextStyle(fontWeight: FontWeight.w700)),
//                         subtitle: Text('${f.area.isEmpty ? "(no area)" : f.area} • ${f.reason}'),
//                       );
//                     },
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------------- models / widgets (inside same file) ----------------

// class _GeoRow {
//   final String areaName;
//   final String shop;
//   final String owner;
//   final int index;
//   final LatLng? pos;
//   final String? reason;
//   _GeoRow({
//     required this.areaName,
//     required this.shop,
//     required this.owner,
//     required this.index,
//     required this.pos,
//     this.reason,
//   });
// }

// class _FailureRow {
//   final String area;
//   final String shop;
//   final String reason;
//   _FailureRow({required this.area, required this.shop, required this.reason});
// }

// class _DupRow {
//   final String jid;
//   final String area;
//   final String shop;
//   final String owner;
//   _DupRow({
//     required this.jid,
//     required this.area,
//     required this.shop,
//     required this.owner,
//   });
// }

// class _Selected {
//   final String shop;
//   final String owner;
//   final String area;
//   final LatLng pos;
//   final double? km;
//   _Selected({
//     required this.shop,
//     required this.owner,
//     required this.area,
//     required this.pos,
//     required this.km,
//   });
// }

// class _FilterPanel extends StatelessWidget {
//   const _FilterPanel({
//     required this.searchCtl,
//     required this.areas,
//     required this.addresses,
//     required this.filterArea,
//     required this.filterAddress,
//     required this.onAreaChanged,
//     required this.onAddressChanged,
//     required this.onReset,
//   });

//   final TextEditingController searchCtl;
//   final List<String> areas;
//   final List<String> addresses;
//   final String? filterArea;
//   final String? filterAddress;
//   final ValueChanged<String?> onAreaChanged;
//   final ValueChanged<String?> onAddressChanged;
//   final VoidCallback onReset;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       elevation: 10,
//       borderRadius: BorderRadius.circular(14),
//       color: Colors.white,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0xFFEAEAEA)),
//           boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 8))],
//         ),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: searchCtl,
//                     decoration: const InputDecoration(
//                       hintText: 'Search shop / owner / area',
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 if (searchCtl.text.isNotEmpty)
//                   IconButton(
//                     tooltip: 'Clear',
//                     icon: const Icon(Icons.close_rounded, size: 18),
//                     onPressed: () => searchCtl.clear(),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: _DropdownBox(
//                     label: 'Area',
//                     value: filterArea,
//                     itemsBuilder: (_) => areas,
//                     onChanged: onAreaChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _DropdownBox(
//                     label: 'Address',
//                     value: filterAddress,
//                     itemsBuilder: (_) => addresses,
//                     onChanged: onAddressChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 TextButton.icon(
//                   onPressed: onReset,
//                   icon: const Icon(Icons.refresh_rounded),
//                   label: const Text('Reset'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// typedef _ItemsBuilder = List<String> Function(BuildContext);

// class _DropdownBox extends StatelessWidget {
//   const _DropdownBox({
//     required this.label,
//     required this.value,
//     required this.itemsBuilder,
//     required this.onChanged,
//   });

//   final String label;
//   final String? value;
//   final _ItemsBuilder itemsBuilder;
//   final ValueChanged<String?> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final built = itemsBuilder(context);
//     final menu = ['(All)'] + built;
//     final current = value == null ? '(All)' : value!;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF7F7FA),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE9E9EF)),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           value: (menu.contains(current)) ? current : '(All)',
//           icon: const Icon(Icons.keyboard_arrow_down_rounded),
//           items: menu
//               .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
//               .toList(),
//           onChanged: (v) => onChanged(v == '(All)' ? null : v),
//         ),
//       ),
//     );
//   }
// }

// class _BottomInfoCard extends StatelessWidget {
//   const _BottomInfoCard({
//     required this.selected,
//     required this.onClose,
//     required this.onCenterHere,
//   });

//   final _Selected selected;
//   final VoidCallback onClose;
//   final VoidCallback onCenterHere;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Material(
//       elevation: 10,
//       borderRadius: BorderRadius.circular(14),
//       color: Colors.white,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0xFFEAEAEA)),
//           boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 8))],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF5F5F7),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.store_rounded, color: Color(0xFFEA7A3B)),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(selected.shop,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF1F2937),
//                       )),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           selected.owner,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           selected.area,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Text(
//                         selected.km == null
//                             ? '—'
//                             : (selected.km! < 1
//                                 ? '${(selected.km! * 1000).toStringAsFixed(0)} m'
//                                 : '${selected.km!.toStringAsFixed(1)} km'),
//                         style: t.bodySmall?.copyWith(
//                           fontWeight: FontWeight.w700,
//                           color: const Color(0xFFEA7A3B),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton(
//               tooltip: 'Center here',
//               icon: const Icon(Icons.center_focus_strong_rounded),
//               onPressed: onCenterHere,
//             ),
//             IconButton(
//               tooltip: 'Close',
//               icon: const Icon(Icons.close_rounded),
//               onPressed: onClose,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


/*

class JourneyPlanMapSingleFile extends StatefulWidget {
  const JourneyPlanMapSingleFile({super.key});

  @override
  State<JourneyPlanMapSingleFile> createState() => _JourneyPlanMapSingleFileState();
}

class _JourneyPlanMapSingleFileState extends State<JourneyPlanMapSingleFile> {
  // Storage + caching for geocoding results and bias hints
  final _box = GetStorage();
  final _memCache = <String, LatLng>{};

  // Map + current location
  final _mapCtl = Completer<GoogleMapController>();
  final _markers = <Marker>{};
  final _loc = loc.Location();
  LatLng? _myLoc;

  // Filters
  final _searchCtl = TextEditingController();
  String? _filterArea;
  String? _filterAddress;
  final _areas = <String>[];
  final _addresses = <String>[];

  // Status
  bool _loading = false;
  int _geocodeOk = 0;
  int _geocodeFail = 0;
  int _dupSkipped = 0;
  _Selected? _selected;
  final List<_FailureRow> _failures = [];
  final List<_DupRow> _dups = [];

  // Fallback camera (auto-zooms to my location or markers after load)
  static const _fallbackCamera =
      CameraPosition(target: LatLng(20, 0), zoom: 2.5);

  // --------------- Lifecycle ---------------
  @override
  void initState() {
    super.initState();
    // If your app didn't init GetStorage in main(), do: await GetStorage.init();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMyLocation();
      _rebuildFilterChoices();
      await _applyFiltersAndReload();
      if (_myLoc != null) {
        await _centerOnMyLocation(initial: true);
      } else if (_markers.isNotEmpty) {
        await _fitAllMarkers();
      }
    });

    _searchCtl.addListener(() {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _applyFiltersAndReload();
      });
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  // --------------- Current location ---------------
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
    final target = _myLoc ?? const LatLng(20, 0);
    await ctl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: initial ? 16 : 15.5),
    ));
  }

  // --------------- JourneyPlan access + helpers ---------------
  List<dynamic> _allPlans() {
    final model = context.read<GlobalBloc>().state.loginModel;
    return (model?.journeyPlan as List?) ?? const <dynamic>[];
  }

  String _safeLower(dynamic v) =>
      v == null ? '' : v.toString().trim().toLowerCase();

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

  String _addressOf(dynamic plan) {
    try {
      final v = (plan as dynamic).custAddress;
      if (v != null) return v.toString();
    } catch (_) {}
    if (plan is Map) {
      final v = plan['custAddress'];
      if (v != null) return v.toString();
    }
    return '';
  }

  /// Unique key used to de-dupe:
  /// Prefer journeyId; else use composite of accode|partyName|custAddress|areaName
  String _planKey(dynamic p) {
    // try common journey id keys
    for (final k in const [
      'journeyId','JourneyId','journyId','journeyid',
      'jpId','jp_id','JPId','jid','JID',
      'routeId','route_id','journey_id','planId','PlanId'
    ]) {
      try {
        if (p is Map && p[k] != null) {
          final v = p[k].toString().trim();
          if (v.isNotEmpty) return 'jid:$v';
        }
        // dynamic path
        final v = (p as dynamic).toJson?.call()[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return 'jid:${v.toString().trim()}';
        }
      } catch (_) {/* ignore */}
    }
    final accode = _safeLower((p as dynamic).accode);
    final name   = _safeLower((p as dynamic).partyName);
    final addr   = _safeLower((p as dynamic).custAddress);
    final area   = _safeLower((p as dynamic).areaName);
    return 'ac:$accode|nm:$name|ad:$addr|ar:$area';
  }

  // --------------- Filters (search/area/address) ---------------
  void _rebuildFilterChoices() {
    final plans = _allPlans();
    final aSet = <String>{};
    final adSet = <String>{};
    for (final p in plans) {
      final area = _areaOf(p).trim();
      final addr = _addressOf(p).trim();
      if (area.isNotEmpty) aSet.add(area);
      if (addr.isNotEmpty) adSet.add(addr);
    }
    final areas = aSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
    final addrs = adSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _areas
        ..clear()
        ..addAll(areas);
      _addresses
        ..clear()
        ..addAll(addrs);
      if (_filterArea != null && !_areas.contains(_filterArea)) _filterArea = null;
      if (_filterAddress != null && !_addresses.contains(_filterAddress)) _filterAddress = null;
    });
  }

  Future<void> _applyFiltersAndReload() async {
    if (_loading) return;

    final plans = _allPlans();
    final q = _searchCtl.text.trim().toLowerCase();
    final areaSel = _filterArea?.trim();
    final addrSel = _filterAddress?.trim();

    Iterable<dynamic> filtered = plans.where((p) {
      final shop  = _safeLower(_shopOf(p));
      final owner = _safeLower(_ownerOf(p));
      final area  = _safeLower(_areaOf(p));
      final addr  = _safeLower(_addressOf(p));

      final matchesSearch =
          q.isEmpty || shop.contains(q) || owner.contains(q) || area.contains(q);
      final matchesArea   = areaSel == null || area == _safeLower(areaSel);
      final matchesAddr   = addrSel == null || addr == _safeLower(addrSel);

      return matchesSearch && matchesArea && matchesAddr;
    });

    // De-dupe multiple entries (same journey id or composite)
    final seen = <String>{};
    final dedup = <dynamic>[];
    for (final p in filtered) {
      final key = _planKey(p);
      if (seen.add(key)) dedup.add(p);
      else _dupSkipped++;
    }

    await _placeMarkersFrom(dedup);
  }

  // --------------- Geocoding (AreaName-first, optional hints) ---------------
  String? get _hintCity    => _asNonEmpty(_box.read('geo_bias_city'));
  String? get _hintRegion  => _asNonEmpty(_box.read('geo_bias_region'));
  String? get _hintCountry => _asNonEmpty(_box.read('geo_bias_country'));

  String? _asNonEmpty(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  String _cacheKey(String area) {
    final c = (_hintCity ?? '').toLowerCase();
    final r = (_hintRegion ?? '').toLowerCase();
    final co = (_hintCountry ?? '').toLowerCase();
    return 'geo_area_${area.trim().toLowerCase()}';//vjkbvjk
    // Changing hints makes a different cache key automatically.
  }

  Future<LatLng?> _geocodeArea(String areaName) async {
    final a = areaName.trim();
    if (a.isEmpty) return null;

    // Skip country-only label like "Pakistan"
    if (a.toLowerCase() == 'pakistan' ||
        (_hintCountry != null && a.toLowerCase() == _hintCountry!.toLowerCase())) {
      return null;
    }

    final key = _cacheKey(a);

    // Memory cache
    if (_memCache.containsKey(key)) return _memCache[key];

    // Disk cache
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

    // AreaName-first (not dependent on city)
    final candidates = <String>[
      a,
      if (_hintCity != null) '$a, ${_hintCity!}',
      if (_hintRegion != null) '$a, ${_hintRegion!}',
      if (_hintCountry != null) '$a, ${_hintCountry!}',
      if (_hintCity != null && _hintCountry != null) '$a, ${_hintCity!}, ${_hintCountry!}',
      if (_hintRegion != null && _hintCountry != null) '$a, ${_hintRegion!}, ${_hintCountry!}',
      if (_hintCity != null && _hintRegion != null && _hintCountry != null)
        '$a, ${_hintCity!}, ${_hintRegion!}, ${_hintCountry!}',
    ];

    geo.Location? best;
    double bestDist = double.infinity;

    for (final q in candidates) {
      try {
        final hits = await geo.locationFromAddress(q);
        if (hits.isEmpty) continue;

        // Pick nearest to my current location to avoid wrong city when names repeat
        if (_myLoc != null) {
          for (final h in hits) {
            final d = _sqDist(_myLoc!, LatLng(h.latitude, h.longitude));
            if (d < bestDist) {
              bestDist = d;
              best = h;
            }
          }
        } else {
          best ??= hits.first;
        }
      } catch (_) {/* try next */}
    }

    if (best == null) return null;

    final pos = LatLng(best.latitude, best.longitude);
    _memCache[key] = pos;
    await _box.write(key, '${pos.latitude},${pos.longitude}');
    return pos;
  }

  double _sqDist(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  // --------------- Markers placement ---------------
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

  Future<void> _placeMarkersFrom(List<dynamic> filteredPlans) async {
    setState(() {
      _loading = true;
      _geocodeOk = 0;
      _geocodeFail = 0;
      _failures.clear();
      _dups.clear();
      _selected = null;
    });

    final rows = filteredPlans
        .map((p) => (
              area: _areaOf(p).trim(),
              shop: _shopOf(p).trim(),
              owner: _ownerOf(p).trim(),
            ))
        .toList();

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
      ({String area, String shop, String owner}) row, int index) async {
    // Reject empty area or country-only area like "Pakistan"
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
    if (row.area.toLowerCase() == 'pakistan' ||
        (_hintCountry != null &&
            row.area.toLowerCase() == _hintCountry!.toLowerCase())) {
      return _GeoRow(
        area: row.area,
        shop: row.shop,
        owner: row.owner,
        index: index,
        pos: null,
        reason: 'Area too broad (country).',
      );
    }

    final pos = await _geocodeArea(row.area);
    return _GeoRow(
      area: row.area,
      shop: row.shop,
      owner: row.owner,
      index: index,
      pos: pos,
      reason: pos == null ? 'Could not geocode areaName.' : null,
    );
  }

  // --------------- Marker tap: distance card ---------------
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

  // --------------- Fit all markers ---------------
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

  // --------------- Bias hints editor (single-file) ---------------
  Future<void> _editBiasHints() async {
    final cityCtl = TextEditingController(text: _hintCity ?? '');
    final regionCtl = TextEditingController(text: _hintRegion ?? '');
    final countryCtl = TextEditingController(text: _hintCountry ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geocoding Bias (optional)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('These hints help disambiguate areas with same names.'),
            const SizedBox(height: 12),
            TextField(
              controller: cityCtl,
              decoration: const InputDecoration(
                labelText: 'City (optional)', prefixIcon: Icon(Icons.location_city),
              ),
            ),
            TextField(
              controller: regionCtl,
              decoration: const InputDecoration(
                labelText: 'Region/State (optional)', prefixIcon: Icon(Icons.map),
              ),
            ),
            TextField(
              controller: countryCtl,
              decoration: const InputDecoration(
                labelText: 'Country (optional)', prefixIcon: Icon(Icons.public),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: ()=> Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved == true) {
      await _box.write('geo_bias_city', cityCtl.text.trim());
      await _box.write('geo_bias_region', regionCtl.text.trim());
      await _box.write('geo_bias_country', countryCtl.text.trim());

      // Clear geocode cache because hints changed:
      final keys = _box.getKeys().where((k) => k.toString().startsWith('geo_area_')).toList();
      for (final k in keys) {
        await _box.remove(k);
      }
      _memCache.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved. Reloading markers with new hints…'),
      ));
      await _applyFiltersAndReload();
      if (_markers.isNotEmpty) await _fitAllMarkers();
    }
  }

  // --------------- UI ---------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Plan — Area Markers'),
        actions: [
          IconButton(
            tooltip: 'Bias hints (optional)',
            icon: const Icon(Icons.public_rounded),
            onPressed: _editBiasHints,
          ),
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _centerOnMyLocation,
          ),
          IconButton(
            tooltip: 'Fit all markers',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: _fitAllMarkers,
          ),
          IconButton(
            tooltip: 'Clear geocode cache',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final keys = _box.getKeys()
                  .where((k) => k.toString().startsWith('geo_area_'))
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

          // Filter/search panel
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _FilterPanel(
              searchCtl: _searchCtl,
              areas: _areas,
              addresses: _addresses,
              filterArea: _filterArea,
              filterAddress: _filterAddress,
              onAreaChanged: (v) {
                setState(() => _filterArea = v?.isEmpty == true ? null : v);
                _applyFiltersAndReload();
              },
              onAddressChanged: (v) {
                setState(() => _filterAddress = v?.isEmpty == true ? null : v);
                _applyFiltersAndReload();
              },
              onReset: () {
                setState(() {
                  _searchCtl.text = '';
                  _filterArea = null;
                  _filterAddress = null;
                });
                _applyFiltersAndReload();
              },
            ),
          ),

          // Status chip
          if (!_loading)
            Positioned(
              top: 120,
              left: 12,
              child: InkWell(
                onTap: (_failures.isEmpty && _dups.isEmpty) ? null : _showStatusSheet,
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
                        'Markers: $_geocodeOk  •  Failed: $_geocodeFail  •  Dups: $_dupSkipped',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_failures.isNotEmpty || _dups.isNotEmpty) ...[
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
                margin: const EdgeInsets.only(top: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Text('Placing markers…', style: TextStyle(color: Colors.white)),
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
        backgroundColor: const Color(0xFFEA7A3B),
        onPressed: _fitAllMarkers,
        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
        label: const Text('View All Markers', style: TextStyle(color: Colors.white)),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Placement report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),

                if (_dups.isNotEmpty) ...[
                  Row(
                    children: const [
                      Icon(Icons.copy_rounded, color: Colors.amber),
                      SizedBox(width: 6),
                      Text('Skipped duplicates (same Journey ID)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
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
                  Row(
                    children: const [
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                      SizedBox(width: 6),
                      Text('Unable to mark these locations',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _failures.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = _failures[i];
                      return ListTile(
                        leading: const Icon(Icons.place_rounded, color: Colors.redAccent),
                        title: Text(f.shop.isEmpty ? 'Shop' : f.shop,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${f.area.isEmpty ? "(no area)" : f.area} • ${f.reason}'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Helper view models & widgets (all inside this file) ----------------

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

class _DupRow {
  final String jid;
  final String area;
  final String shop;
  final String owner;
  _DupRow({
    required this.jid,
    required this.area,
    required this.shop,
    required this.owner,
  });
}

class _Selected {
  final String shop;
  final String owner;
  final String area;
  final LatLng pos;
  final double? km;
  _Selected({
    required this.shop,
    required this.owner,
    required this.area,
    required this.pos,
    required this.km,
  });
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchCtl,
    required this.areas,
    required this.addresses,
    required this.filterArea,
    required this.filterAddress,
    required this.onAreaChanged,
    required this.onAddressChanged,
    required this.onReset,
  });

  final TextEditingController searchCtl;
  final List<String> areas;
  final List<String> addresses;
  final String? filterArea;
  final String? filterAddress;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String?> onAddressChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtl,
                    decoration: const InputDecoration(
                      hintText: 'Search shop / owner / area',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (searchCtl.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => searchCtl.clear(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DropdownBox(
                    label: 'Area',
                    value: filterArea,
                    itemsBuilder: (_) => areas,
                    onChanged: onAreaChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownBox(
                    label: 'Address',
                    value: filterAddress,
                    itemsBuilder: (_) => addresses,
                    onChanged: onAddressChanged,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ItemsBuilder = List<String> Function(BuildContext);

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.label,
    required this.value,
    required this.itemsBuilder,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final _ItemsBuilder itemsBuilder;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final built = itemsBuilder(context);
    final menu = ['(All)'] + built;
    final current = value == null ? '(All)' : value!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E9EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: (menu.contains(current)) ? current : '(All)',
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: menu
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v == '(All)' ? null : v),
        ),
      ),
    );
  }
}

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

*/

// class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
//   const AreaMarkersFromJourneyPlanMap({
//     super.key,
//     this.cityHint = 'Karachi',
//     this.regionHint = 'Sindh',
//     this.country = 'Pakistan',
//     this.autoFitAfterLoad = true,
//   });

//   final String cityHint;
//   final String regionHint;
//   final String country;
//   final bool autoFitAfterLoad;

//   @override
//   State<AreaMarkersFromJourneyPlanMap> createState() =>
//       _AreaMarkersFromJourneyPlanMapState();
// }

// class _AreaMarkersFromJourneyPlanMapState
//     extends State<AreaMarkersFromJourneyPlanMap> {
//   // --- Storage / caches ---
//   final _box = GetStorage();
//   final _memCache = <String, LatLng>{};

//   // --- Map / location ---
//   final _markers = <Marker>{};
//   final _mapCtl = Completer<GoogleMapController>();
//   final _loc = loc.Location();
//   LatLng? _myLoc;

//   // --- UI / filtering ---
//   final _searchCtl = TextEditingController();
//   String? _filterArea;      // areaName
//   String? _filterAddress;   // custAddress
//   final _areas = <String>[];     // distinct areaName values
//   final _addresses = <String>[]; // distinct custAddress values

//   // --- Status ---
//   bool _loading = false;
//   int _geocodeOk = 0;
//   int _geocodeFail = 0;
//   int _dupSkipped = 0;
//   _Selected? _selected;
//   final List<_FailureRow> _failures = [];
//   final List<_DupRow> _dups = [];

//   // --- Karachi bias / bounds ---
//   static const _KARACHI_MIN_LAT = 24.75;
//   static const _KARACHI_MAX_LAT = 25.10;
//   static const _KARACHI_MIN_LNG = 66.65;
//   static const _KARACHI_MAX_LNG = 67.45;

//   static const _karachiCenter = LatLng(24.8607, 67.0011);
//   static const _fallbackCamera = CameraPosition(
//     target: _karachiCenter,
//     zoom: 12,
//   );

//   @override
//   void initState() {
//     super.initState();
//     // seed lookups from current model
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _ensureMyLocation();
//       _rebuildFilterChoices();        // build dropdown choices
//       await _applyFiltersAndReload(); // place markers for current filters
//       if (_myLoc != null) {
//         await _centerOnMyLocation(initial: true);
//       } else if (_markers.isNotEmpty && widget.autoFitAfterLoad) {
//         await _fitAllMarkers();
//       } else {
//         await _centerOnKarachi();
//       }
//     });

//     // live search filtering
//     _searchCtl.addListener(() {
//       // Apply a tiny debounce effect
//       Future.delayed(const Duration(milliseconds: 120), () {
//         if (!mounted) return;
//         _applyFiltersAndReload();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchCtl.dispose();
//     super.dispose();
//   }

//   // -------------------- Current location --------------------
//   Future<void> _ensureMyLocation() async {
//     try {
//       final perm = await _loc.hasPermission();
//       if (perm == loc.PermissionStatus.denied ||
//           perm == loc.PermissionStatus.deniedForever) {
//         final req = await _loc.requestPermission();
//         if (req != loc.PermissionStatus.granted) return;
//       }
//       var svc = await _loc.serviceEnabled();
//       if (!svc) {
//         svc = await _loc.requestService();
//         if (!svc) return;
//       }
//       final l = await _loc.getLocation();
//       if (l.latitude != null && l.longitude != null) {
//         setState(() => _myLoc = LatLng(l.latitude!, l.longitude!));
//       }
//     } catch (_) {/* ignore */}
//   }

//   Future<void> _centerOnMyLocation({bool initial = false}) async {
//     final ctl = await _mapCtl.future;
//     final target = _myLoc ?? _karachiCenter;
//     await ctl.animateCamera(CameraUpdate.newCameraPosition(
//       CameraPosition(target: target, zoom: initial ? 16 : 15.5),
//     ));
//   }

//   Future<void> _centerOnKarachi() async {
//     final ctl = await _mapCtl.future;
//     await ctl.animateCamera(CameraUpdate.newCameraPosition(
//       const CameraPosition(target: _karachiCenter, zoom: 12.5),
//     ));
//   }

//   // -------------------- Safe extractors --------------------
//   String _safeLower(dynamic v) =>
//       v == null ? '' : v.toString().trim().toLowerCase();

//   String _areaOf(dynamic plan) {
//     try {
//       final v = (plan as dynamic).areaName;
//       if (v != null) return v.toString();
//     } catch (_) {}
//     if (plan is Map) {
//       final v = plan['areaName'];
//       if (v != null) return v.toString();
//     }
//     return '';
//   }

//   String _shopOf(dynamic plan) {
//     final tryKeys = ['partyName', 'shopName', 'name', 'outlet', 'customerName'];
//     try {
//       final v = (plan as dynamic).partyName;
//       if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//     } catch (_) {}
//     if (plan is Map) {
//       for (final k in tryKeys) {
//         final v = plan[k];
//         if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//       }
//     }
//     return 'Shop';
//   }

//   String _ownerOf(dynamic plan) {
//     final tryKeys = [
//       'ownerName','owner','proprietor','contactPerson','contact_name',
//       'personName','custOwner','shopOwner'
//     ];
//     try {
//       final v = (plan as dynamic).ownerName;
//       if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//     } catch (_) {}
//     if (plan is Map) {
//       for (final k in tryKeys) {
//         final v = plan[k];
//         if (v != null && v.toString().trim().isNotEmpty) return v.toString();
//       }
//     }
//     return '—';
//   }

//   String _addressOf(dynamic plan) {
//     try {
//       final v = (plan as dynamic).custAddress;
//       if (v != null) return v.toString();
//     } catch (_) {}
//     if (plan is Map) {
//       final v = plan['custAddress'];
//       if (v != null) return v.toString();
//     }
//     return '';
//   }

//   /// Prefer journeyId; fallback to deterministic composite key
//   String _planKey(dynamic p) {
//     try {
//       final jid = ((p as dynamic).journeyId ?? '').toString().trim();
//       if (jid.isNotEmpty) return 'jid:$jid';
//     } catch (_) {}
//     final accode = _safeLower((p as dynamic).accode);
//     final name   = _safeLower((p as dynamic).partyName);
//     final addr   = _safeLower((p as dynamic).custAddress);
//     final area   = _safeLower((p as dynamic).areaName);
//     return 'ac:$accode|nm:$name|ad:$addr|ar:$area';
//   }

//   // -------------------- Distinct choices for dropdowns --------------------
//   List<dynamic> _allPlans() {
//     final model = context.read<GlobalBloc>().state.loginModel;
//     return (model?.journeyPlan as List?) ?? const <dynamic>[];
//   }

//   void _rebuildFilterChoices() {
//     final plans = _allPlans();
//     final aSet = <String>{};
//     final adSet = <String>{};

//     for (final p in plans) {
//       final area = _areaOf(p).trim();
//       final addr = _addressOf(p).trim();
//       if (area.isNotEmpty) aSet.add(area);
//       if (addr.isNotEmpty) adSet.add(addr);
//     }

//     final areas = aSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));
//     final addrs = adSet.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));

//     setState(() {
//       _areas
//         ..clear()
//         ..addAll(areas);
//       _addresses
//         ..clear()
//         ..addAll(addrs);

//       // keep existing selection if still valid, else clear
//       if (_filterArea != null && !_areas.contains(_filterArea)) _filterArea = null;
//       if (_filterAddress != null && !_addresses.contains(_filterAddress)) _filterAddress = null;
//     });
//   }

//   // -------------------- Karachi-biased geocoding --------------------
//   bool _inKarachi(LatLng p) {
//     return p.latitude >= _KARACHI_MIN_LAT &&
//         p.latitude <= _KARACHI_MAX_LAT &&
//         p.longitude >= _KARACHI_MIN_LNG &&
//         p.longitude <= _KARACHI_MAX_LNG;
//   }

//   String _cacheKey(String area) =>
//       'geo_area_${area.trim().toLowerCase()}__${widget.cityHint.toLowerCase()}';

//   Future<LatLng?> _geocodeAreaKarachiBiased(String areaName) async {
//     final a = areaName.trim();
//     if (a.isEmpty) return null;
//     if (a.toLowerCase() == widget.country.toLowerCase()) return null;

//     final key = _cacheKey(a);

//     if (_memCache.containsKey(key)) return _memCache[key];

//     final cached = _box.read(key);
//     if (cached is String && cached.contains(',')) {
//       final parts = cached.split(',');
//       final lat = double.tryParse(parts[0]);
//       final lng = double.tryParse(parts[1]);
//       if (lat != null && lng != null) {
//         final pos = LatLng(lat, lng);
//         _memCache[key] = pos;
//         return pos;
//       }
//     }

//     final candidates = <String>[
//       '$a, ${widget.cityHint}, ${widget.regionHint}, ${widget.country}',
//       '$a, ${widget.cityHint}, ${widget.country}',
//       '$a, ${widget.country}',
//       a,
//     ];

//     for (final q in candidates) {
//       try {
//         final hits = await geo.locationFromAddress(q);
//         if (hits.isEmpty) continue;
//         geo.Location? picked;
//         for (final h in hits) {
//           final pos = LatLng(h.latitude, h.longitude);
//           if (_inKarachi(pos)) {
//             picked = h;
//             break;
//           }
//         }
//         picked ??= hits.first;
//         final pos = LatLng(picked.latitude, picked.longitude);
//         if (!_inKarachi(pos)) continue;

//         _memCache[key] = pos;
//         await _box.write(key, '${pos.latitude},${pos.longitude}');
//         return pos;
//       } catch (_) {/* try next */}
//     }
//     return null;
//   }

//   // -------------------- Filtering + Marker placement --------------------
//   Future<void> _applyFiltersAndReload() async {
//     if (_loading) return;

//     // Build filtered base set (search + area + address)
//     final plans = _allPlans();
//     final q = _searchCtl.text.trim().toLowerCase();
//     final areaSel = _filterArea?.trim();
//     final addrSel = _filterAddress?.trim();

//     Iterable<dynamic> filtered = plans.where((p) {
//       final shop  = _safeLower(_shopOf(p));
//       final owner = _safeLower(_ownerOf(p));
//       final area  = _safeLower(_areaOf(p));
//       final addr  = _safeLower(_addressOf(p));

//       final matchesSearch = q.isEmpty || shop.contains(q) || owner.contains(q) || area.contains(q);
//       final matchesArea   = areaSel == null || area == _safeLower(areaSel);
//       final matchesAddr   = addrSel == null || addr == _safeLower(addrSel);

//       return matchesSearch && matchesArea && matchesAddr;
//     });

//     // de-dup by journeyId (or composite)
//     final seen = <String>{};
//     final dedup = <dynamic>[];
//     for (final p in filtered) {
//       final key = _planKey(p);
//       if (seen.add(key)) dedup.add(p);
//     }

//     await _placeMarkersFrom(dedup);
//   }

//   LatLng _withJitter(LatLng base, int indexOnSamePoint) {
//     if (indexOnSamePoint <= 0) return base;
//     const step = 0.0002; // ~22m
//     final angle = (indexOnSamePoint % 12) * (2 * pi / 12);
//     final radius = step * ((indexOnSamePoint ~/ 12) + 1);
//     return LatLng(
//       base.latitude + radius * sin(angle),
//       base.longitude + radius * cos(angle),
//     );
//   }

//   Future<void> _placeMarkersFrom(List<dynamic> filteredPlans) async {
//     setState(() {
//       _loading = true;
//       _geocodeOk = 0;
//       _geocodeFail = 0;
//       _dupSkipped = 0; // dups are handled before geocode now
//       _failures.clear();
//       _dups.clear();
//       _selected = null;
//     });

//     // rows for geocode
//     final rows = filteredPlans
//         .map((p) => (
//               area: _areaOf(p).trim(),
//               shop: _shopOf(p).trim(),
//               owner: _ownerOf(p).trim(),
//             ))
//         .toList();

//     final futures = <Future<_GeoRow>>[];
//     for (int i = 0; i < rows.length; i++) {
//       futures.add(_geocodeRow(rows[i], i));
//     }
//     final results = await Future.wait(futures);

//     final samePosCounter = <String, int>{};
//     final newMarkers = <Marker>{};

//     for (final r in results) {
//       if (r.pos == null) {
//         _geocodeFail++;
//         _failures.add(_FailureRow(
//           area: r.area,
//           shop: r.shop,
//           reason: r.reason ?? 'Unable to mark this location.',
//         ));
//         continue;
//       }

//       _geocodeOk++;
//       final roundedKey =
//           '${r.pos!.latitude.toStringAsFixed(5)},${r.pos!.longitude.toStringAsFixed(5)}';
//       final idxOnSame =
//           samePosCounter.update(roundedKey, (v) => v + 1, ifAbsent: () => 0);

//       final effectivePos = _withJitter(r.pos!, idxOnSame);
//       final markerId = 'shop_${r.index}_${r.area}_${r.shop}';

//       newMarkers.add(
//         Marker(
//           markerId: MarkerId(markerId),
//           position: effectivePos,
//           infoWindow: InfoWindow(
//             title: r.shop.isEmpty ? 'Shop' : r.shop,
//             snippet: r.owner.isNotEmpty ? 'Owner: ${r.owner}' : r.area,
//           ),
//           onTap: () => _onMarkerTap(
//             shop: r.shop.isEmpty ? 'Shop' : r.shop,
//             owner: r.owner.isEmpty ? '—' : r.owner,
//             area: r.area,
//             pos: effectivePos,
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers
//         ..clear()
//         ..addAll(newMarkers);
//       _loading = false;
//     });
//   }

//   Future<_GeoRow> _geocodeRow(
//       ({String area, String shop, String owner}) row, int index) async {
//     if (row.area.isEmpty) {
//       return _GeoRow(
//         area: row.area,
//         shop: row.shop,
//         owner: row.owner,
//         index: index,
//         pos: null,
//         reason: 'Missing area name.',
//       );
//     }
//     if (row.area.toLowerCase() == widget.country.toLowerCase()) {
//       return _GeoRow(
//         area: row.area,
//         shop: row.shop,
//         owner: row.owner,
//         index: index,
//         pos: null,
//         reason: 'Area is too broad (“${widget.country}”).',
//       );
//     }

//     final pos = await _geocodeAreaKarachiBiased(row.area);
//     return _GeoRow(
//       area: row.area,
//       shop: row.shop,
//       owner: row.owner,
//       index: index,
//       pos: pos,
//       reason: pos == null
//           ? 'Could not geocode within ${widget.cityHint}.'
//           : null,
//     );
//   }

//   // -------------------- Marker tap: distance & info card --------------------
//   void _onMarkerTap({
//     required String shop,
//     required String owner,
//     required String area,
//     required LatLng pos,
//   }) {
//     final km = (_myLoc == null) ? null : _distanceKm(_myLoc!, pos);
//     setState(() {
//       _selected = _Selected(shop: shop, owner: owner, area: area, pos: pos, km: km);
//     });
//   }

//   double _distanceKm(LatLng a, LatLng b) {
//     const R = 6371.0; // km
//     final dLat = _deg2rad(b.latitude - a.latitude);
//     final dLng = _deg2rad(b.longitude - a.longitude);
//     final la1 = _deg2rad(a.latitude);
//     final la2 = _deg2rad(b.latitude);

//     final h = sin(dLat / 2) * sin(dLat / 2) +
//         sin(dLng / 2) * sin(dLng / 2) * cos(la1) * cos(la2);
//     final c = 2 * atan2(sqrt(h), sqrt(1 - h));
//     return R * c;
//   }

//   double _deg2rad(double d) => d * (pi / 180.0);

//   // -------------------- Fit all markers --------------------------------------
//   Future<void> _fitAllMarkers() async {
//     if (_markers.isEmpty) return;
//     final c = await _mapCtl.future;

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

//   // -------------------- UI ---------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Journey Plan — Map Filters'),
//         actions: [
//           IconButton(
//             tooltip: 'My location',
//             icon: const Icon(Icons.my_location_rounded),
//             onPressed: _centerOnMyLocation,
//           ),
//           IconButton(
//             tooltip: 'Fit all markers',
//             icon: const Icon(Icons.fullscreen_rounded),
//             onPressed: _fitAllMarkers,
//           ),
//           IconButton(
//             tooltip: 'Clear geocode cache',
//             icon: const Icon(Icons.delete_sweep_rounded),
//             onPressed: () async {
//               final keys = _box.getKeys()
//                   .where((k) => k.toString().startsWith('geo_area_'))
//                   .toList();
//               for (final k in keys) {
//                 await _box.remove(k);
//               }
//               _memCache.clear();
//               if (!mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Geocode cache cleared')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: _fallbackCamera,
//             onMapCreated: (c) async {
//               _mapCtl.complete(c);
//               if (_myLoc != null) {
//                 await _centerOnMyLocation(initial: true);
//               }
//             },
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             compassEnabled: true,
//             markers: _markers,
//           ),

//           // Floating filter panel
//           Positioned(
//             top: 12,
//             left: 12,
//             right: 12,
//             child: _FilterPanel(
//               searchCtl: _searchCtl,
//               areas: _areas,
//               addresses: _addresses,
//               filterArea: _filterArea,
//               filterAddress: _filterAddress,
//               onAreaChanged: (v) {
//                 setState(() => _filterArea = v?.isEmpty == true ? null : v);
//                 _applyFiltersAndReload();
//               },
//               onAddressChanged: (v) {
//                 setState(() => _filterAddress = v?.isEmpty == true ? null : v);
//                 _applyFiltersAndReload();
//               },
//               onReset: () {
//                 setState(() {
//                   _searchCtl.text = '';
//                   _filterArea = null;
//                   _filterAddress = null;
//                 });
//                 _applyFiltersAndReload();
//               },
//             ),
//           ),

//           // status chip (OK/Fail/Dups) with viewer
//           if (!_loading)
//             Positioned(
//               top: 120,
//               left: 12,
//               child: InkWell(
//                 onTap: (_failures.isEmpty && _dups.isEmpty) ? null : _showStatusSheet,
//                 borderRadius: BorderRadius.circular(999),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(999),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x14000000),
//                         blurRadius: 10,
//                         offset: Offset(0, 6),
//                       ),
//                     ],
//                     border: Border.all(color: const Color(0xFFEAEAEA)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.place_rounded, size: 16, color: Color(0xFF1F2937)),
//                       const SizedBox(width: 6),
//                       Text(
//                         'Markers: $_geocodeOk  •  Failed: $_geocodeFail',
//                         style: const TextStyle(
//                           color: Color(0xFF1F2937),
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       if (_failures.isNotEmpty || _dups.isNotEmpty) ...[
//                         const SizedBox(width: 8),
//                         const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF6B7280)),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // Loading pill
//           if (_loading)
//             Align(
//               alignment: Alignment.topCenter,
//               child: Container(
//                 margin: const EdgeInsets.only(top: 120),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(.55),
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     SizedBox(
//                       height: 14,
//                       width: 14,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Text('Placing markers…', style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),

//           // Bottom info card for tapped marker
//           if (_selected != null)
//             Positioned(
//               left: 12,
//               right: 12,
//               bottom: 16,
//               child: _BottomInfoCard(
//                 selected: _selected!,
//                 onClose: () => setState(() => _selected = null),
//                 onCenterHere: () async {
//                   final ctl = await _mapCtl.future;
//                   await ctl.animateCamera(
//                     CameraUpdate.newCameraPosition(CameraPosition(
//                       target: _selected!.pos,
//                       zoom: 17,
//                     )),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: const Color(0xFFEA7A3B),
//         onPressed: _fitAllMarkers,
//         icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
//         label: const Text('View All Markers', style: TextStyle(color: Colors.white)),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }

//   void _showStatusSheet() {
//     showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       isScrollControlled: true,
//       builder: (_) => SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Placement report',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
//                 const SizedBox(height: 12),

//                 if (_dups.isNotEmpty) ...[
//                   Row(
//                     children: const [
//                       Icon(Icons.copy_rounded, color: Colors.amber),
//                       SizedBox(width: 6),
//                       Text('Skipped duplicates (same Journey ID)',
//                           style: TextStyle(fontWeight: FontWeight.w700)),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _dups.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (_, i) {
//                       final d = _dups[i];
//                       return ListTile(
//                         leading: const Icon(Icons.remove_circle_outline, color: Colors.amber),
//                         title: Text(d.shop.isEmpty ? 'Shop' : d.shop,
//                             style: const TextStyle(fontWeight: FontWeight.w700)),
//                         subtitle: Text('JID: ${d.jid} • ${d.area.isEmpty ? "(no area)" : d.area} • ${d.owner}'),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                 ],

//                 if (_failures.isNotEmpty) ...[
//                   Row(
//                     children: const [
//                       Icon(Icons.error_outline_rounded, color: Colors.redAccent),
//                       SizedBox(width: 6),
//                       Text('Unable to mark these locations',
//                           style: TextStyle(fontWeight: FontWeight.w700)),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _failures.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (_, i) {
//                       final f = _failures[i];
//                       return ListTile(
//                         leading: const Icon(Icons.place_rounded, color: Colors.redAccent),
//                         title: Text(f.shop.isEmpty ? 'Shop' : f.shop,
//                             style: const TextStyle(fontWeight: FontWeight.w700)),
//                         subtitle: Text('${f.area.isEmpty ? "(no area)" : f.area} • ${f.reason}'),
//                       );
//                     },
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // -------------------- Filter Panel --------------------
// class _FilterPanel extends StatelessWidget {
//   const _FilterPanel({
//     required this.searchCtl,
//     required this.areas,
//     required this.addresses,
//     required this.filterArea,
//     required this.filterAddress,
//     required this.onAreaChanged,
//     required this.onAddressChanged,
//     required this.onReset,
//   });

//   final TextEditingController searchCtl;
//   final List<String> areas;
//   final List<String> addresses;
//   final String? filterArea;
//   final String? filterAddress;
//   final ValueChanged<String?> onAreaChanged;
//   final ValueChanged<String?> onAddressChanged;
//   final VoidCallback onReset;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       elevation: 10,
//       borderRadius: BorderRadius.circular(14),
//       color: Colors.white,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0xFFEAEAEA)),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 14,
//               offset: Offset(0, 8),
//             )
//           ],
//         ),
//         child: Column(
//           children: [
//             // Search
//             Row(
//               children: [
//                 const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: searchCtl,
//                     decoration: const InputDecoration(
//                       hintText: 'Search shop / owner / area',
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 if (searchCtl.text.isNotEmpty)
//                   IconButton(
//                     tooltip: 'Clear',
//                     icon: const Icon(Icons.close_rounded, size: 18),
//                     onPressed: () => searchCtl.clear(),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             // Dropdowns
//             Row(
//               children: [
//                 Expanded(
//                   child: _DropdownBox(
//                     label: 'Area',
//                     value: filterArea,
//                     items: const [''] + ([]) // placeholder, replaced below
//                       ..clear(), // just to keep analyzer happy
//                     // We'll build via builder param:
//                     builder: (ctx) => areas,
//                     onChanged: onAreaChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _DropdownBox(
//                     label: 'Address',
//                     value: filterAddress,
//                     items: const [''],
//                     builder: (ctx) => addresses,
//                     onChanged: onAddressChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 TextButton.icon(
//                   onPressed: onReset,
//                   icon: const Icon(Icons.refresh_rounded),
//                   label: const Text('Reset'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// typedef _ItemsBuilder = List<String> Function(BuildContext);

// class _DropdownBox extends StatelessWidget {
//   const _DropdownBox({
//     required this.label,
//     required this.value,
//     required this.items,
//     required this.builder,
//     required this.onChanged,
//   });

//   final String label;
//   final String? value;
//   final List<String> items;
//   final _ItemsBuilder builder;
//   final ValueChanged<String?> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     final built = builder(context);
//     final menu = ['(All)'] + built;
//     final current = value == null ? '(All)' : value!;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF7F7FA),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE9E9EF)),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           value: (menu.contains(current)) ? current : '(All)',
//           icon: const Icon(Icons.keyboard_arrow_down_rounded),
//           items: menu
//               .map((e) => DropdownMenuItem(
//                     value: e,
//                     child: Text(e, overflow: TextOverflow.ellipsis),
//                   ))
//               .toList(),
//           onChanged: (v) => onChanged(v == '(All)' ? null : v),
//         ),
//       ),
//     );
//   }
// }

// // -------------------- Helper widgets / models --------------------
// class _BottomInfoCard extends StatelessWidget {
//   const _BottomInfoCard({
//     required this.selected,
//     required this.onClose,
//     required this.onCenterHere,
//   });

//   final _Selected selected;
//   final VoidCallback onClose;
//   final VoidCallback onCenterHere;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Material(
//       elevation: 10,
//       borderRadius: BorderRadius.circular(14),
//       color: Colors.white,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0xFFEAEAEA)),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 14,
//               offset: Offset(0, 8),
//             )
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF5F5F7),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.store_rounded, color: Color(0xFFEA7A3B)),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(selected.shop,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF1F2937),
//                       )),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           selected.owner,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.place_rounded, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           selected.area,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: t.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF6B7280)),
//                       const SizedBox(width: 4),
//                       Text(
//                         selected.km == null
//                             ? '—'
//                             : (selected.km! < 1
//                                 ? '${(selected.km! * 1000).toStringAsFixed(0)} m'
//                                 : '${selected.km!.toStringAsFixed(1)} km'),
//                         style: t.bodySmall?.copyWith(
//                           fontWeight: FontWeight.w700,
//                           color: const Color(0xFFEA7A3B),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton(
//               tooltip: 'Center here',
//               icon: const Icon(Icons.center_focus_strong_rounded),
//               onPressed: onCenterHere,
//             ),
//             IconButton(
//               tooltip: 'Close',
//               icon: const Icon(Icons.close_rounded),
//               onPressed: onClose,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _GeoRow {
//   final String area;
//   final String shop;
//   final String owner;
//   final int index;
//   final LatLng? pos;
//   final String? reason;
//   _GeoRow({
//     required this.area,
//     required this.shop,
//     required this.owner,
//     required this.index,
//     required this.pos,
//     this.reason,
//   });
// }

// class _FailureRow {
//   final String area;
//   final String shop;
//   final String reason;
//   _FailureRow({required this.area, required this.shop, required this.reason});
// }

// class _DupRow {
//   final String jid;
//   final String area;
//   final String shop;
//   final String owner;
//   _DupRow({
//     required this.jid,
//     required this.area,
//     required this.shop,
//     required this.owner,
//   });
// }

// class _Selected {
//   final String shop;
//   final String owner;
//   final String area;
//   final LatLng pos;
//   final double? km; // null if my location unknown
//   _Selected({
//     required this.shop,
//     required this.owner,
//     required this.area,
//     required this.pos,
//     required this.km,
//   });
// }
