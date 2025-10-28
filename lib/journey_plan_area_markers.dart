import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';





/// One marker per JourneyPlan row using `areaName`.
/// - Skips entries where areaName == "Pakistan" (case-insensitive)
/// - After loading, camera auto-fits to show ALL markers.
/// - “My location” button lets you jump back to yourself anytime.
class AreaMarkersFromJourneyPlanMap extends StatefulWidget {
  const AreaMarkersFromJourneyPlanMap({
    super.key,
    this.countryHint = 'Pakistan',
    this.autoFitAfterLoad = true,
  });

  final String? countryHint;
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

  static const _fallbackCamera = CameraPosition(
    target: LatLng(24.8607, 67.0011), // fallback if no location/markers
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMyLocation();   // get blue dot
      await _loadAndPlaceAll();    // place markers (one per row)
      // IMPORTANT: after loading, fit markers (don’t override with my location)
      if (_markers.isNotEmpty && widget.autoFitAfterLoad) {
        await _fitAllMarkers();
      } else {
        await _centerOnMyLocation();
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
    } catch (_) {}
  }

  Future<void> _centerOnMyLocation() async {
    final ctl = await _mapCtl.future;
    final target = _myLoc ?? _fallbackCamera.target;
    await ctl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: _myLoc == null ? 12 : 15.5),
    ));
  }

  // -------------------- Geocoding helpers --------------------

  String _cacheKey(String area) => 'geo_area_${area.trim().toLowerCase()}';

  /// Safely reads `areaName` from typed object or Map.
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

  Future<LatLng?> _geocodeArea(String areaName) async {
    // Skip country-level "Pakistan" entries completely
    if (areaName.trim().toLowerCase() == 'pakistan') return null;

    final key = _cacheKey(areaName);

    // memory cache
    if (_memCache.containsKey(key)) return _memCache[key];

    // persistent cache
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

    // geocode
    try {
      final query = (widget.countryHint == null || widget.countryHint!.isEmpty)
          ? areaName
          : '$areaName, ${widget.countryHint}';
      final hits = await geo.locationFromAddress(query);
      if (hits.isNotEmpty) {
        final pos = LatLng(hits.first.latitude, hits.first.longitude);
        _memCache[key] = pos;
        await _box.write(key, '${pos.latitude},${pos.longitude}');
        return pos;
      }
    } catch (_) {}
    return null;
  }

  // -------------------- Marker creation --------------------

  /// Small circular jitter when many markers land at the same coords.
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
    });

    final model = context.read<GlobalBloc>().state.loginModel;
    final List<dynamic> plans =
        (model?.journeyPlan as List?) ?? const <dynamic>[];

    // NO DEDUPE; skip blank & "Pakistan"
    final List<String> areas = plans
        .map(_areaOf)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'pakistan')
        .toList();

    // Geocode in parallel
    final futures = <Future<_GeoResult>>[];
    for (int i = 0; i < areas.length; i++) {
      futures.add(_geocodeOne(areas[i], i));
    }
    final results = await Future.wait(futures);

    // Separate identical coordinates
    final samePosCounter = <String, int>{}; // "lat,lng" -> count
    final newMarkers = <Marker>{};

    for (final r in results) {
      if (r.pos == null) continue;

      final roundedKey =
          '${r.pos!.latitude.toStringAsFixed(5)},${r.pos!.longitude.toStringAsFixed(5)}';
      final idxOnSame =
          samePosCounter.update(roundedKey, (v) => v + 1, ifAbsent: () => 0);

      final effectivePos = _withJitter(r.pos!, idxOnSame);
      final markerId = '${r.area}#${r.index}'; // unique id

      newMarkers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: effectivePos,
          infoWindow: InfoWindow(
            title: r.area,
            snippet: 'Entry #${r.index + 1}',
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

  Future<_GeoResult> _geocodeOne(String area, int index) async {
    final pos = await _geocodeArea(area);
    if (pos == null) {
      _geocodeFail++;
    } else {
      _geocodeOk++;
    }
    return _GeoResult(area: area, index: index, pos: pos);
  }

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

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Areas'),
        actions: [
          IconButton(
            tooltip: 'Reload markers',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await _loadAndPlaceAll();
              if (_markers.isNotEmpty) await _fitAllMarkers();
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
            onMapCreated: (c) => _mapCtl.complete(c),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: _markers,
          ),
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
          if (!_loading && _markers.isEmpty)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'No markers found. Make sure JourneyPlan.areaName has values other than "Pakistan".',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (!_loading && _markers.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ),
                child: Text(
                  'Markers: $_geocodeOk  •  Failed: $_geocodeFail   (tap ⛶ to view all)',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
}

class _GeoResult {
  final String area;
  final int index;
  final LatLng? pos;
  _GeoResult({required this.area, required this.index, required this.pos});
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
