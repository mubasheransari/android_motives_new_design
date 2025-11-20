import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
import 'package:motives_new_ui_conversion/widgets/centered_customize_toast_widget.dart';


class MarkAttendanceView extends StatefulWidget {
  const MarkAttendanceView({super.key});

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  final loc.Location location = loc.Location();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _currentMarkerIcon;

  LatLng? _currentLatLng;
  CameraPosition? _initialCameraPosition;
  String distanceInfo = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMapReady = false;

  String _dateTime = "";
  Timer? _clockTimer;

  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF2F3F5);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);

  String _currentAddress = "Fetching location...";

  final box = GetStorage();

  // 🔑 Keys for GetStorage flags
  static const String kAttendanceFlagKey = 'attendance_marked_flag';
  static const String kAttendanceDateKey = 'attendance_marked_date';
  static const String kRouteLockKey = 'route_complete_lock_date';

  // ✅ handy getter you can reuse in other screens if needed
  bool get isAttendanceMarkedToday => box.read(kAttendanceFlagKey) == true;

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat("EEEE, dd-MMM-yyyy HH:mm:ss").format(now);
    if (mounted) {
      setState(() => _dateTime = formatted);
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ Reset attendance flag when the calendar day changes
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedDate = box.read<String>(kAttendanceDateKey);
    if (storedDate != todayKey) {
      box.write(kAttendanceDateKey, todayKey);
      box.write(kAttendanceFlagKey, false); // new day → not marked
    }

    context.read<GlobalBloc>().add(Activity(activity: 'Attendance Details'));
    _initMap();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _loadCustomMarkers();
    await _requestPermissionAndFetchLocation();
    if (mounted) {
      setState(() => distanceInfo = '');
    }
  }

  Future<void> _loadCustomMarkers() async {
    _currentMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/g_marker_no_badge_cropped_v2.png',
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks =
          await geo.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _currentAddress =
                "${place.thoroughfare}, ${place.subLocality}, ${place.locality},";
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _currentAddress = "Unable to fetch address");
      }
    }
  }

  Future<void> _requestPermissionAndFetchLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();
    _currentLatLng = LatLng(
      currentLocation.latitude ?? 24.8607,
      currentLocation.longitude ?? 67.0011,
    );
    _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 14);

    if (_currentMarkerIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLatLng!,
          icon: _currentMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    await _getAddressFromLatLng(_currentLatLng!);
  }

  void _recenterToCurrentLocation() {
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    LatLngBounds? visibleRegion;
    do {
      visibleRegion = await _mapController.getVisibleRegion();
    } while (visibleRegion.southwest.latitude == -90.0);
    if (mounted) {
      setState(() => _isMapReady = true);
    }
  }

  String _formatToHms(String input) {
    var s = input.replaceAll(RegExp(r'\D'), '');
    s = s.length > 6 ? s.substring(0, 6) : s.padLeft(6, '0');
    final hh = s.substring(0, 2);
    final mm = s.substring(2, 4);
    final ss = s.substring(4, 6);
    return '$hh:$mm:$ss';
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  int dedupJourneyCount(List<JourneyPlan> plans) {
    final seen = <String>{};
    for (final p in plans) {
      final accode = p.accode.trim();
      final key = accode.isNotEmpty
          ? 'ID:${accode.toLowerCase()}'
          : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
      seen.add(key);
    }
    return seen.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final global = context.read<GlobalBloc>();
    final loginModel = global.state.loginModel;

    // If you still want to show punch time, use log only (no statusAttendance condition)
    String? formattedTimeDate;
    if (loginModel?.log?.tim != null) {
      formattedTimeDate = _formatToHms(loginModel!.log!.tim.toString());
    }

    final hasAttendanceTime = loginModel?.log?.tim != null;
    final attendanceStatus =
        hasAttendanceTime ? "ATTENDANCE OUT" : "ATTENDANCE IN";

    // ==== ROUTE COMPLETION COUNT ====
    final coveredRoutesCount = _asInt(box.read('covered_routes_count'));
    final jpCount = dedupJourneyCount(loginModel!.journeyPlan);
    final bool routeCompleted = (jpCount == coveredRoutesCount);

    // ==== SAME-DAY LOCK BASED ON ROUTE COMPLETION ====
    final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lockedDate = box.read<String>(kRouteLockKey);

    bool routeLockedToday = (lockedDate == todayKey);

    // If today’s route just got completed and not yet locked, lock it now.
    if (routeCompleted && !routeLockedToday) {
      box.write(kRouteLockKey, todayKey);
      routeLockedToday = true;
    }

    // ==== LOCAL ATTENDANCE FLAG (GetStorage true/false) ====
    final bool attendanceMarkedFlag = isAttendanceMarkedToday;

    // ==== BUTTON TEXT + ENABLE/DISABLE ====
    String btnText;
    bool disableBtn;

    /*
      Final rules:
      1) If attendance already marked (local flag) => disabled + "Attendance is marked".
      2) Else if today’s route is completed (locked) => disabled until tomorrow.
      3) Else => enabled (user can mark attendance).
    */
    if (attendanceMarkedFlag) {
      btnText = "Attendance is marked";
      disableBtn = true;
    } else if (routeLockedToday) {
      btnText = "Route completed — Attendance available tomorrow";
      disableBtn = true;
    } else {
      btnText = "Mark Attendance";
      disableBtn = false;
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          if (_initialCameraPosition != null)
            GoogleMap(
              padding: const EdgeInsets.only(bottom: 60),
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition!,
              mapType: MapType.normal,
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

          if (distanceInfo.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distanceInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    decoration: BoxDecoration(
                      color: field,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: orange.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: t.bodyMedium?.copyWith(color: muted),
                          ),
                        ),
                        IconButton(
                          onPressed: _recenterToCurrentLocation,
                          icon: const Icon(
                            Icons.my_location,
                            color: orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.50,
                      height: 50,
                      child: BlocBuilder<GlobalBloc, GlobalState>(
                        builder: (context, state) {
                          final isLoading =
                              state.markAttendanceStatus ==
                                  MarkAttendanceStatus.loading;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (isLoading || disableBtn)
                                ? null
                                : () async {
                                    // This block only runs when:
                                    // - attendance not already marked (local flag)
                                    // - route NOT locked today

                                    final current =
                                        await location.getLocation();
                                    final lat = current.latitude;
                                    final lng = current.longitude;

                                    if (lat == null || lng == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Could not get your location'),
                                        ),
                                      );
                                      return;
                                    }

                                    final bloc = context.read<GlobalBloc>();
                                    final userId = bloc
                                        .state.loginModel?.userinfo?.userId
                                        ?.toString();
                                    if (userId == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('User session missing'),
                                        ),
                                      );
                                      return;
                                    }

                                    bloc.add(
                                      MarkAttendanceEvent(
                                        action: 'IN',
                                        lat: lat.toString(),
                                        lng: lng.toString(),
                                        type: '1',
                                        userId: userId,
                                      ),
                                    );

                                    final attendStatus = await bloc.stream
                                        .map((s) => s.markAttendanceStatus)
                                        .distinct()
                                        .firstWhere(
                                          (st) =>
                                              st ==
                                                  MarkAttendanceStatus.success ||
                                              st ==
                                                  MarkAttendanceStatus.failure,
                                        );

                                    if (attendStatus !=
                                        MarkAttendanceStatus.success) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Attendance failed'),
                                        ),
                                      );
                                      return;
                                    }

                                    // Optional: refresh login model if you still need latest log/time etc.
                                    final email =
                                        box.read<String>("email");
                                    final password =
                                        box.read<String>("password");
                                    if (email != null && password != null) {
                                      bloc.add(
                                        LoginEvent(
                                          email: email,
                                          password: password,
                                        ),
                                      );
                                      final loginStatus = await bloc.stream
                                          .map((s) => s.status)
                                          .distinct()
                                          .firstWhere(
                                            (st) =>
                                                st == LoginStatus.success ||
                                                st == LoginStatus.failure,
                                          );

                                      if (loginStatus !=
                                          LoginStatus.success) {
                                        if (!mounted) return;
                                        final msg =
                                            bloc.state.loginModel?.message ??
                                                'Login refresh failed';
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                        return;
                                      }
                                    }

                                    // ✅ Mark local bool as true in GetStorage
                                    box.write(kAttendanceFlagKey, true);

                                    if (!mounted) return;
                                    showCenteredToast(
                                      context,
                                      'Attendance Marked Successfully',
                                    );

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const HomeUpdated(),
                                      ),
                                    );
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    btnText.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      _dateTime,
                      style: t.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchCard extends StatelessWidget {
  final String title;
  final String time;
  const _PunchCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          title,
          style: t.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEA7A3B),
          ),
        ),
      ],
    );
  }
}





// class MarkAttendanceView extends StatefulWidget {
//   const MarkAttendanceView({super.key});

//   @override
//   State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
// }

// class _MarkAttendanceViewState extends State<MarkAttendanceView> {
//   final loc.Location location = loc.Location();
//   late GoogleMapController _mapController;
//   Set<Marker> _markers = {};
//   BitmapDescriptor? _currentMarkerIcon;

//   LatLng? _currentLatLng;
//   CameraPosition? _initialCameraPosition;
//   String distanceInfo = "";

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   bool _isMapReady = false;

//   String _dateTime = "";
//   Timer? _clockTimer;

//   final ImagePicker _picker = ImagePicker();
//   File? _capturedImage;

//   static const Color orange = Color(0xFFEA7A3B);
//   static const Color text = Color(0xFF1E1E1E);
//   static const Color muted = Color(0xFF707883);
//   static const Color field = Color(0xFFF2F3F5);
//   static const Color card = Colors.white;
//   static const Color accent = Color(0xFFE97C42);
//   static const Color _shadow = Color(0x14000000);

//   String _currentAddress = "Fetching location...";

//   final box = GetStorage();

//   // 🔑 Keys for GetStorage flags
//   static const String kAttendanceFlagKey = 'attendance_marked_flag';
//   static const String kAttendanceDateKey = 'attendance_marked_date';
//   static const String kRouteLockKey = 'route_complete_lock_date';

//   void _updateTime() {
//     final now = DateTime.now();
//     final formatted = DateFormat("EEEE, dd-MMM-yyyy HH:mm:ss").format(now);
//     setState(() => _dateTime = formatted);
//   }

//   @override
//   void initState() {
//     super.initState();

//     // ✅ Reset attendance flag when the day changes
//     final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final storedDate = box.read<String>(kAttendanceDateKey);
//     if (storedDate != todayKey) {
//       box.write(kAttendanceDateKey, todayKey);
//       box.write(kAttendanceFlagKey, false); // new day → not marked
//     }

//     context.read<GlobalBloc>().add(Activity(activity: 'Attendance Details'));
//     _initMap();
//     _updateTime();
//     _clockTimer =
//         Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
//   }

//   @override
//   void dispose() {
//     _clockTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initMap() async {
//     await _loadCustomMarkers();
//     await _requestPermissionAndFetchLocation();
//     setState(() => distanceInfo = '');
//   }

//   Future<void> _loadCustomMarkers() async {
//     _currentMarkerIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(devicePixelRatio: 2.5),
//       'assets/g_marker_no_badge_cropped_v2.png',
//     );
//   }

//   Future<void> _getAddressFromLatLng(LatLng position) async {
//     try {
//       final placemarks =
//           await geo.placemarkFromCoordinates(position.latitude, position.longitude);
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         setState(() {
//           _currentAddress =
//               "${place.thoroughfare}, ${place.subLocality}, ${place.locality},";
//         });
//       }
//     } catch (_) {
//       setState(() => _currentAddress = "Unable to fetch address");
//     }
//   }

//   Future<void> _requestPermissionAndFetchLocation() async {
//     bool serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) return;
//     }

//     var permissionGranted = await location.hasPermission();
//     if (permissionGranted == loc.PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != loc.PermissionStatus.granted) return;
//     }

//     final currentLocation = await location.getLocation();
//     _currentLatLng = LatLng(
//       currentLocation.latitude ?? 24.8607,
//       currentLocation.longitude ?? 67.0011,
//     );
//     _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 14);

//     if (_currentMarkerIcon != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLatLng!,
//           icon: _currentMarkerIcon!,
//           infoWindow: const InfoWindow(title: 'Your Location'),
//         ),
//       );
//     }

//     await _getAddressFromLatLng(_currentLatLng!);
//   }

//   void _recenterToCurrentLocation() {
//     if (_currentLatLng != null) {
//       _mapController.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
//       );
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) async {
//     _mapController = controller;
//     LatLngBounds? visibleRegion;
//     do {
//       visibleRegion = await _mapController.getVisibleRegion();
//     } while (visibleRegion.southwest.latitude == -90.0);
//     setState(() => _isMapReady = true);
//   }

//   String _formatToHms(String input) {
//     var s = input.replaceAll(RegExp(r'\D'), '');
//     s = s.length > 6 ? s.substring(0, 6) : s.padLeft(6, '0');
//     final hh = s.substring(0, 2);
//     final mm = s.substring(2, 4);
//     final ss = s.substring(4, 6);
//     return '$hh:$mm:$ss';
//   }

//   int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

//   int dedupJourneyCount(List<JourneyPlan> plans) {
//     final seen = <String>{};
//     for (final p in plans) {
//       final accode = p.accode.trim();
//       final key = accode.isNotEmpty
//           ? 'ID:${accode.toLowerCase()}'
//           : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
//       seen.add(key);
//     }
//     return seen.length;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final global = context.read<GlobalBloc>();
//     final loginModel = global.state.loginModel;

//     String? formattedTimeDate;
//     if (loginModel?.statusAttendance.toString() == "1") {
//       formattedTimeDate = _formatToHms(loginModel!.log!.tim.toString());
//     }

//     final hasAttendanceOut = loginModel?.log?.tim != null;
//     final attendanceStatus =
//         hasAttendanceOut ? "ATTENDANCE OUT" : "ATTENDANCE IN";

//     // ==== ROUTE COMPLETION COUNT ====
//     final coveredRoutesCount = _asInt(box.read('covered_routes_count'));
//     final jpCount = dedupJourneyCount(loginModel!.journeyPlan);
//     final bool routeCompleted = (jpCount == coveredRoutesCount);

//     // ==== SAME-DAY LOCK BASED ON ROUTE COMPLETION ====
//     final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final String? lockedDate = box.read<String>(kRouteLockKey);

//     bool routeLockedToday = (lockedDate == todayKey);

//     // If today’s route just got completed and not yet locked, lock it now.
//     if (routeCompleted && !routeLockedToday) {
//       box.write(kRouteLockKey, todayKey);
//       routeLockedToday = true;
//     }

//     // ==== LOCAL ATTENDANCE FLAG (GetStorage true/false) ====
//     final bool attendanceMarkedFlag =
//         box.read(kAttendanceFlagKey) == true; // <- your requested flag

//     // ==== BUTTON TEXT + ENABLE/DISABLE ====
//     final bool statusAttendanceIsOne =
//         (global.state.loginModel?.statusAttendance.toString() == "1");

//     String btnText = "Attendance In".toUpperCase();
//     bool disableBtn = false;

//     /*
//       Final rules:
//       1) If attendance already marked (backend OR local flag) => disabled.
//       2) Else if today’s route is completed (locked) => disabled until tomorrow.
//       3) Else => enabled (user can mark attendance).
//     */
//     if (statusAttendanceIsOne || attendanceMarkedFlag) {
//       btnText = "Attendance is marked";
//       disableBtn = true;
//     } else if (routeLockedToday) {
//       btnText = "Route completed — Attendance available tomorrow";
//       disableBtn = true;
//     } else {
//       btnText = "Mark Attendance";
//       disableBtn = false;
//     }

//     return Scaffold(
//       key: _scaffoldKey,
//       body: Stack(
//         children: [
//           if (_initialCameraPosition != null)
//             GoogleMap(
//               padding: const EdgeInsets.only(bottom: 60),
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: _initialCameraPosition!,
//               mapType: MapType.normal,
//               markers: _markers,
//               myLocationButtonEnabled: false,
//               zoomControlsEnabled: false,
//             ),

//           if (distanceInfo.isNotEmpty)
//             Positioned(
//               bottom: 30,
//               left: 16,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(0),
//                 decoration: BoxDecoration(
//                   color: Colors.white70,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   distanceInfo,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),

//           Positioned(
//             bottom: 60,
//             left: 16,
//             right: 16,
//             child: Container(
//               height: 250,
//               width: double.infinity,
//               decoration: const BoxDecoration(
//                 color: card,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _shadow,
//                     blurRadius: 10,
//                     offset: Offset(0, -2),
//                   )
//                 ],
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Location",
//                     style: t.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: text,
//                     ),
//                   ),
//                   const SizedBox(height: 6),

//                   Container(
//                     decoration: BoxDecoration(
//                       color: field,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: orange.withOpacity(0.3)),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 14,
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             _currentAddress,
//                             style: t.bodyMedium?.copyWith(color: muted),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: _recenterToCurrentLocation,
//                           icon: const Icon(
//                             Icons.my_location,
//                             color: orange,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.50,
//                       height: 50,
//                       child: BlocBuilder<GlobalBloc, GlobalState>(
//                         builder: (context, state) {
//                           final isLoading =
//                               state.markAttendanceStatus ==
//                                   MarkAttendanceStatus.loading;

//                           return ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: orange,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             onPressed: (isLoading || disableBtn)
//                                 ? null
//                                 : () async {
//                                     // This block only runs when:
//                                     // - attendance not already marked (backend or flag)
//                                     // - route NOT locked today

//                                     final current =
//                                         await location.getLocation();
//                                     final lat = current.latitude;
//                                     final lng = current.longitude;

//                                     if (lat == null || lng == null) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                               'Could not get your location'),
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     final bloc = context.read<GlobalBloc>();
//                                     final userId = bloc
//                                         .state.loginModel?.userinfo?.userId
//                                         ?.toString();
//                                     if (userId == null) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content:
//                                               Text('User session missing'),
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     bloc.add(
//                                       MarkAttendanceEvent(
//                                         action: 'IN',
//                                         lat: lat.toString(),
//                                         lng: lng.toString(),
//                                         type: '1',
//                                         userId: userId,
//                                       ),
//                                     );

//                                     final attendStatus = await bloc.stream
//                                         .map((s) => s.markAttendanceStatus)
//                                         .distinct()
//                                         .firstWhere(
//                                           (st) =>
//                                               st ==
//                                                   MarkAttendanceStatus.success ||
//                                               st ==
//                                                   MarkAttendanceStatus.failure,
//                                         );

//                                     if (attendStatus !=
//                                         MarkAttendanceStatus.success) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content:
//                                               Text('Attendance failed'),
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     final email =
//                                         box.read<String>("email");
//                                     final password =
//                                         box.read<String>("password");
//                                     if (email != null && password != null) {
//                                       bloc.add(
//                                         LoginEvent(
//                                           email: email,
//                                           password: password,
//                                         ),
//                                       );
//                                       final loginStatus = await bloc.stream
//                                           .map((s) => s.status)
//                                           .distinct()
//                                           .firstWhere(
//                                             (st) =>
//                                                 st == LoginStatus.success ||
//                                                 st == LoginStatus.failure,
//                                           );

//                                       if (loginStatus !=
//                                           LoginStatus.success) {
//                                         if (!mounted) return;
//                                         final msg =
//                                             bloc.state.loginModel?.message ??
//                                                 'Login refresh failed';
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(
//                                           SnackBar(content: Text(msg)),
//                                         );
//                                         return;
//                                       }
//                                     }

//                                     // ✅ Mark local flag as true in GetStorage
//                                     box.write(kAttendanceFlagKey, true);

//                                     if (!mounted) return;
//                                     showCenteredToast(
//                                       context,
//                                       'Attendance Marked Successfully',
//                                     );

//                                     Navigator.pushReplacement(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const HomeUpdated(),
//                                       ),
//                                     );
//                                   },
//                             child: isLoading
//                                 ? const SizedBox(
//                                     width: 22,
//                                     height: 22,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2.4,
//                                       valueColor:
//                                           AlwaysStoppedAnimation<Color>(
//                                         Colors.white,
//                                       ),
//                                     ),
//                                   )
//                                 : Text(
//                                     btnText.toUpperCase(),
//                                     textAlign: TextAlign.center,
//                                     style: t.titleSmall?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   Center(
//                     child: Text(
//                       _dateTime,
//                       style: t.bodySmall?.copyWith(color: muted),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PunchCard extends StatelessWidget {
//   final String title;
//   final String time;
//   const _PunchCard({required this.title, required this.time});

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Column(
//       children: [
//         Text(
//           title,
//           style: t.bodyMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: const Color(0xFF1E1E1E),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           time,
//           style: t.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFFEA7A3B),
//           ),
//         ),
//       ],
//     );
//   }
// }



/*
class MarkAttendanceView extends StatefulWidget {
  const MarkAttendanceView({super.key});

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  final loc.Location location = loc.Location();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _currentMarkerIcon;

  LatLng? _currentLatLng;
  CameraPosition? _initialCameraPosition;
  String distanceInfo = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMapReady = false;

  String _dateTime = "";
  Timer? _clockTimer;

  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF2F3F5);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);

  String _currentAddress = "Fetching location...";

  final box = GetStorage();

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat("EEEE, dd-MMM-yyyy HH:mm:ss").format(now);
    setState(() => _dateTime = formatted);
  }

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'Attendance Details'));
    _initMap();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _loadCustomMarkers();
    await _requestPermissionAndFetchLocation();
    setState(() => distanceInfo = '');
  }

  Future<void> _loadCustomMarkers() async {
    _currentMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/g_marker_no_badge_cropped_v2.png',
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress =
              "${place.thoroughfare}, ${place.subLocality}, ${place.locality},";
        });
      }
    } catch (_) {
      setState(() => _currentAddress = "Unable to fetch address");
    }
  }

  Future<void> _requestPermissionAndFetchLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();
    _currentLatLng = LatLng(
      currentLocation.latitude ?? 24.8607,
      currentLocation.longitude ?? 67.0011,
    );
    _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 14);

    if (_currentMarkerIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLatLng!,
          icon: _currentMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    await _getAddressFromLatLng(_currentLatLng!);
  }

  void _recenterToCurrentLocation() {
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    LatLngBounds? visibleRegion;
    do {
      visibleRegion = await _mapController.getVisibleRegion();
    } while (visibleRegion.southwest.latitude == -90.0);
    setState(() => _isMapReady = true);
  }

  String _formatToHms(String input) {
    var s = input.replaceAll(RegExp(r'\D'), '');
    s = s.length > 6 ? s.substring(0, 6) : s.padLeft(6, '0');
    final hh = s.substring(0, 2);
    final mm = s.substring(2, 4);
    final ss = s.substring(4, 6);
    return '$hh:$mm:$ss';
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  int dedupJourneyCount(List<JourneyPlan> plans) {
    final seen = <String>{};
    for (final p in plans) {
      final accode = p.accode.trim();
      final key = accode.isNotEmpty
          ? 'ID:${accode.toLowerCase()}'
          : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
      seen.add(key);
    }
    return seen.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final global = context.read<GlobalBloc>();
    final loginModel = global.state.loginModel;

    String? formattedTimeDate;
    if (loginModel?.statusAttendance.toString() == "1") {
      formattedTimeDate = _formatToHms(loginModel!.log!.tim.toString());
    }

    final hasAttendanceOut = loginModel?.log?.tim != null;
    final attendanceStatus = hasAttendanceOut ? "ATTENDANCE OUT" : "ATTENDANCE IN";

    // ==== ROUTE COMPLETION COUNT ====
    // covered_routes_count is written elsewhere in your app (JourneyPlan screen)
    final coveredRoutesCount = _asInt(box.read('covered_routes_count'));
    final jpCount = dedupJourneyCount(loginModel!.journeyPlan);
    final bool routeCompleted = (jpCount == coveredRoutesCount);

    // ==== SAME-DAY LOCK BASED ON ROUTE COMPLETION ====
    // When route is completed for today, we lock the attendance button until tomorrow.
    const String routeLockKey = 'route_complete_lock_date';
    final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lockedDate = box.read<String>(routeLockKey);

    bool routeLockedToday = (lockedDate == todayKey);

    // If today’s route just got completed and not yet locked, lock it now.
    if (routeCompleted && !routeLockedToday) {
      box.write(routeLockKey, todayKey);
      routeLockedToday = true;
    }

    // If date changed, routeLockedToday will automatically become false
    // because lockedDate != todayKey.

    // ==== BUTTON TEXT + ENABLE/DISABLE ====
    final bool statusAttendanceIsOne =
        (global.state.loginModel?.statusAttendance.toString() == "1");

    String btnText = "Attendance In".toUpperCase();
    bool disableBtn = false;

    /// Final rules:
    /// 1) If attendance already marked => disabled.
    /// 2) Else if today’s route is completed (locked) => disabled until tomorrow.
    /// 3) Else => enabled (user can mark attendance).
   /* if (statusAttendanceIsOne) {
      btnText = "Attendance is marked";
      disableBtn = true;
    } else if (routeLockedToday) {
      btnText = "Route completed — Attendance available tomorrow";
      disableBtn = true;
    } else {
      btnText = "Mark Attendance";
      disableBtn = false;
    }*/

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          if (_initialCameraPosition != null)
            GoogleMap(
              padding: const EdgeInsets.only(bottom: 60),
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition!,
              mapType: MapType.normal,
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

          if (distanceInfo.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distanceInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    decoration: BoxDecoration(
                      color: field,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: orange.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: t.bodyMedium?.copyWith(color: muted),
                          ),
                        ),
                        IconButton(
                          onPressed: _recenterToCurrentLocation,
                          icon: const Icon(
                            Icons.my_location,
                            color: orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BlocBuilder<GlobalBloc, GlobalState>(
                  //   builder: (context, state) {
                  //     return state.loginModel!.statusAttendance == "1"
                  //         ? Row(
                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             children: [
                  //               _PunchCard(
                  //                 title: "Punch In",
                  //                 time: formattedTimeDate ?? "--:--",
                  //               ),
                  //               const _PunchCard(
                  //                 title: "Punch Out",
                  //                 time: "--:--",
                  //               ),
                  //             ],
                  //           )
                  //         : Row(
                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             children: const [
                  //               _PunchCard(
                  //                 title: "Punch In",
                  //                 time: "--:--",
                  //               ),
                  //               _PunchCard(
                  //                 title: "Punch Out",
                  //                 time: "--:--",
                  //               ),
                  //             ],
                  //           );
                  //   },
                  // ),
                  // const SizedBox(height: 5),

                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.50,
                      height: 50,
                      child: BlocBuilder<GlobalBloc, GlobalState>(
                        builder: (context, state) {
                          final isLoading =
                              state.markAttendanceStatus == MarkAttendanceStatus.loading;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (isLoading || disableBtn)
                                ? null
                                : () async {
                                    // This block only runs when:
                                    // - attendance not already marked
                                    // - route NOT locked today (route not completed OR new day)

                                    final current = await location.getLocation();
                                    final lat = current.latitude;
                                    final lng = current.longitude;

                                    if (lat == null || lng == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Could not get your location'),
                                        ),
                                      );
                                      return;
                                    }

                                    final bloc = context.read<GlobalBloc>();
                                    final userId = bloc
                                        .state.loginModel?.userinfo?.userId
                                        ?.toString();
                                    if (userId == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('User session missing'),
                                        ),
                                      );
                                      return;
                                    }

                                    bloc.add(
                                      MarkAttendanceEvent(
                                        action: 'IN',
                                        lat: lat.toString(),
                                        lng: lng.toString(),
                                        type: '1',
                                        userId: userId,
                                      ),
                                    );

                                    final attendStatus = await bloc.stream
                                        .map((s) => s.markAttendanceStatus)
                                        .distinct()
                                        .firstWhere(
                                          (st) =>
                                              st == MarkAttendanceStatus.success ||
                                              st == MarkAttendanceStatus.failure,
                                        );

                                    if (attendStatus != MarkAttendanceStatus.success) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Attendance failed'),
                                        ),
                                      );
                                      return;
                                    }

                                    final email = box.read<String>("email");
                                    final password = box.read<String>("password");
                                    if (email != null && password != null) {
                                      bloc.add(
                                        LoginEvent(
                                          email: email,
                                          password: password,
                                        ),
                                      );
                                      final loginStatus = await bloc.stream
                                          .map((s) => s.status)
                                          .distinct()
                                          .firstWhere(
                                            (st) =>
                                                st == LoginStatus.success ||
                                                st == LoginStatus.failure,
                                          );

                                      if (loginStatus != LoginStatus.success) {
                                        if (!mounted) return;
                                        final msg = bloc
                                                .state.loginModel?.message ??
                                            'Login refresh failed';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                        return;
                                      }
                                    }

                                    if (!mounted) return;
                                    showCenteredToast(
                                      context,
                                      'Attendance Marked Successfully',
                                    );

                                    // Optional: if you ALSO want to lock after marking attendance,
                                    // uncomment this line:
                                    // box.write(routeLockKey, todayKey);

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HomeUpdated(),
                                      ),
                                    );
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    btnText,
                                    textAlign: TextAlign.center,
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      _dateTime,
                      style: t.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchCard extends StatelessWidget {
  final String title;
  final String time;
  const _PunchCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          title,
          style: t.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEA7A3B),
          ),
        ),
      ],
    );
  }
}
*/



// class MarkAttendanceView extends StatefulWidget {
//   const MarkAttendanceView({super.key});

//   @override
//   State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
// }

// class _MarkAttendanceViewState extends State<MarkAttendanceView> {
//   final loc.Location location = loc.Location();
//   late GoogleMapController _mapController;
//   Set<Marker> _markers = {};
//   BitmapDescriptor? _currentMarkerIcon;
//   BitmapDescriptor? _shopMarkerIcon;
//   LatLng? _currentLatLng;
//   CameraPosition? _initialCameraPosition;
//   String distanceInfo = "";
// //  var box = GetStorage();

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   bool _isMapReady = false;

//   String _dateTime = "";
//   Timer? _clockTimer;
//   //  bool _routeStarted = false;

//   void _updateTime() {
//     final now = DateTime.now();
//     final formatted = DateFormat("EEEE, dd-MMM-yyyy HH:mm:ss").format(now);
//     setState(() => _dateTime = formatted);
//   }

//   @override
//   void initState() {
//     super.initState();
//     //     _routeStarted = box.read('routeKey') == true;
//     //        box.listenKey('routeKey', (v) {
//     //   if (!mounted) return;
//     //   setState(() => _routeStarted = v == true);
//     // });

//     context.read<GlobalBloc>().add(Activity(activity: 'Attendance Details'));
//     _initMap();
//     _updateTime();
//     _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
//   }

//   @override
//   void dispose() {
//     _clockTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initMap() async {
//     await _loadCustomMarkers();
//     await _requestPermissionAndFetchLocation();
//     setState(() => distanceInfo = '');
//   }

//   Future<void> _loadCustomMarkers() async {
//     _currentMarkerIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(devicePixelRatio: 2.5),
//       'assets/g_marker_no_badge_cropped_v2.png',
//     );
//   }

//   String _currentAddress = "Fetching location...";

//   Future<void> _getAddressFromLatLng(LatLng position) async {
//     try {
//       final placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         setState(() {
//           _currentAddress = "${place.thoroughfare}, ${place.subLocality}, ${place.locality},";
//         });
//       }
//     } catch (_) {
//       setState(() => _currentAddress = "Unable to fetch address");
//     }
//   }

//   Future<void> _requestPermissionAndFetchLocation() async {
//     bool serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) return;
//     }

//     var permissionGranted = await location.hasPermission();
//     if (permissionGranted == loc.PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != loc.PermissionStatus.granted) return;
//     }

//     final currentLocation = await location.getLocation();
//     _currentLatLng = LatLng(currentLocation.latitude ?? 24.8607, currentLocation.longitude ?? 67.0011);
//     _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 14);

//     if (_currentMarkerIcon != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLatLng!,
//           icon: _currentMarkerIcon!,
//           infoWindow: const InfoWindow(title: 'Your Location'),
//         ),
//       );
//     }

//     await _getAddressFromLatLng(_currentLatLng!);
//   }

//   void _recenterToCurrentLocation() {
//     if (_currentLatLng != null) {
//       _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) async {
//     _mapController = controller;
//     LatLngBounds? visibleRegion;
//     do {
//       visibleRegion = await _mapController.getVisibleRegion();
//     } while (visibleRegion.southwest.latitude == -90.0);
//     setState(() => _isMapReady = true);
//   }

//   final ImagePicker _picker = ImagePicker();
//   File? _capturedImage;

//   static const Color orange = Color(0xFFEA7A3B);
//   static const Color text = Color(0xFF1E1E1E);
//   static const Color muted = Color(0xFF707883);
//   static const Color field = Color(0xFFF2F3F5);
//   static const Color card = Colors.white;
//   static const Color accent = Color(0xFFE97C42);
//   static const Color _shadow = Color(0x14000000);

//   String _formatToHms(String input) {
//     var s = input.replaceAll(RegExp(r'\D'), '');
//     s = s.length > 6 ? s.substring(0, 6) : s.padLeft(6, '0');
//     final hh = s.substring(0, 2);
//     final mm = s.substring(2, 4);
//     final ss = s.substring(4, 6);
//     return '$hh:$mm:$ss';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     String? formattedTimeDate;
//     final global = context.read<GlobalBloc>();
//     final loginModel = global.state.loginModel;

//     if (loginModel?.statusAttendance.toString() == "1") {
//       formattedTimeDate = _formatToHms(loginModel!.log!.tim.toString());
//     }

//     final hasAttendanceOut = loginModel?.log?.tim != null;
//     final attendanceStatus = hasAttendanceOut ? "ATTENDANCE OUT" : "ATTENDANCE IN";

//     int dedupJourneyCount(List<JourneyPlan> plans) {
//       final seen = <String>{};
//       for (final p in plans) {
//         final accode = p.accode.trim();
//         final key = accode.isNotEmpty
//             ? 'ID:${accode.toLowerCase()}'
//             : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
//         seen.add(key);
//       }
//       return seen.length;
//     }

//     int _coveredRoutesCount = 0;
//     int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

//     final box = GetStorage();
//     _coveredRoutesCount = _asInt(box.read('covered_routes_count'));

//     final jpCount = dedupJourneyCount(loginModel!.journeyPlan);
//     final bool routeCompleted = (jpCount == _coveredRoutesCount);

//     // ======== SAME-DAY LOCK ========
//     const String lockKey = 'attendance_lock_date';
//     final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final String? lastLockedDate = box.read<String>(lockKey);
//     final bool isLockedToday = (lastLockedDate == todayKey);

//     // Per your rule: when routeCompleted == true, show message and prevent marking today
//     if (routeCompleted && !isLockedToday) {
//       box.write(lockKey, todayKey);
//     }

//     // ======== BUTTON TEXT + ENABLE STATE (EXACTLY AS YOU ASKED) ========
//     final bool statusAttendanceIsOne =
//         (context.read<GlobalBloc>().state.loginModel?.statusAttendance.toString() == "1");

//     String btnText;
//     bool disableBtn = isLockedToday; // locked day is always disabled

//     if (statusAttendanceIsOne) {
//       btnText = "Attendance is marked";
//       disableBtn = true;
//     } else if (!routeCompleted) {
//       btnText = "Complete your route";
//       disableBtn = true;
//     } else if (routeCompleted) {
//       btnText = "Route completed — Attendance cannot be marked again today";
//       disableBtn = true;
//     } else {
//       btnText = "Mark Attendance";
//       disableBtn = false;
//     }

//     return Scaffold(
//       key: _scaffoldKey,
//       body: Stack(
//         children: [
//           if (_initialCameraPosition != null)
//             GoogleMap(
//               padding: const EdgeInsets.only(bottom: 60),
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: _initialCameraPosition!,
//               mapType: MapType.normal,
//               markers: _markers,
//               myLocationButtonEnabled: false,
//               zoomControlsEnabled: false,
//             ),

//           if (distanceInfo.isNotEmpty)
//             Positioned(
//               bottom: 30,
//               left: 16,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(0),
//                 decoration: BoxDecoration(
//                   color: Colors.white70,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   distanceInfo,
//                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ),

//           Positioned(
//             bottom: 60,
//             left: 16,
//             right: 16,
//             child: Container(
//               height: 310,
//               width: double.infinity,
//               decoration: const BoxDecoration(
//                 color: card,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 boxShadow: [BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, -2))],
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Location", style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: text)),
//                   const SizedBox(height: 6),

//                   Container(
//                     decoration: BoxDecoration(
//                       color: field,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: orange.withOpacity(0.3)),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                     child: Row(
//                       children: [
//                         Expanded(child: Text(_currentAddress, style: t.bodyMedium?.copyWith(color: muted))),
//                         IconButton(onPressed: _recenterToCurrentLocation, icon: const Icon(Icons.my_location, color: orange)),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   BlocBuilder<GlobalBloc, GlobalState>(
//                     builder: (context, state) {
//                       return state.loginModel!.statusAttendance == "1"
//                           ? Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 _PunchCard(title: "Punch In", time: formattedTimeDate ?? "--:--"),
//                                 const _PunchCard(title: "Punch Out", time: "--:--"),
//                               ],
//                             )
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: const [
//                                 _PunchCard(title: "Punch In", time: "--:--"),
//                                 _PunchCard(title: "Punch Out", time: "--:--"),
//                               ],
//                             );
//                     },
//                   ),
//                   const SizedBox(height: 5),

//                   Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.50,
//                       height: 50,
//                       child: BlocBuilder<GlobalBloc, GlobalState>(
//                         builder: (context, state) {
//                           final isLoading = state.markAttendanceStatus == MarkAttendanceStatus.loading;

//                           return ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: orange,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             ),
//                             onPressed: (isLoading || disableBtn)
//                                 ? null
//                                 : () async {
//                                     // NOTE: With the above rules, this block will only run
//                                     // if you ever decide to enable "Mark Attendance" in some state.
//                                     // Keeping your original body here in case needed later.

//                                     final current = await location.getLocation();
//                                     final lat = current.latitude;
//                                     final lng = current.longitude;
//                                     if (lat == null || lng == null) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Could not get your location')),
//                                       );
//                                       return;
//                                     }

//                                     final bloc = context.read<GlobalBloc>();
//                                     final userId = bloc.state.loginModel?.userinfo?.userId?.toString();
//                                     if (userId == null) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('User session missing')),
//                                       );
//                                       return;
//                                     }

//                                     bloc.add(MarkAttendanceEvent(
//                                       action: 'IN',
//                                       lat: lat.toString(),
//                                       lng: lng.toString(),
//                                       type: '1',
//                                       userId: userId,
//                                     ));

//                                     final attendStatus = await bloc.stream
//                                         .map((s) => s.markAttendanceStatus)
//                                         .distinct()
//                                         .firstWhere((st) =>
//                                             st == MarkAttendanceStatus.success ||
//                                             st == MarkAttendanceStatus.failure);

//                                     if (attendStatus != MarkAttendanceStatus.success) {
//                                       if (!mounted) return;
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(content: Text('Attendance failed')),
//                                       );
//                                       return;
//                                     }

//                                     final email = box.read<String>("email");
//                                     final password = box.read<String>("password");
//                                     if (email != null && password != null) {
//                                       bloc.add(LoginEvent(email: email, password: password));
//                                       final loginStatus = await bloc.stream
//                                           .map((s) => s.status)
//                                           .distinct()
//                                           .firstWhere((st) =>
//                                               st == LoginStatus.success || st == LoginStatus.failure);

//                                       if (loginStatus != LoginStatus.success) {
//                                         if (!mounted) return;
//                                         final msg = bloc.state.loginModel?.message ?? 'Login refresh failed';
//                                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//                                         return;
//                                       }
//                                     }

//                                     if (!mounted) return;
//                                     showCenteredToast(context, 'Attendance Marked Successfully');

//                                     // After success, also lock same day (defensive).
//                                     box.write(lockKey, todayKey);

//                                     Navigator.pushReplacement(
//                                       context,
//                                       MaterialPageRoute(builder: (_) => const HomeUpdated()),
//                                     );
//                                   },
//                             child: isLoading
//                                 ? const SizedBox(
//                                     width: 22,
//                                     height: 22,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2.4,
//                                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                     ),
//                                   )
//                                 : Text(
//                                     btnText,
//                                     textAlign: TextAlign.center,
//                                     style: t.titleSmall?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   Center(child: Text(_dateTime, style: t.bodySmall?.copyWith(color: muted))),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PunchCard extends StatelessWidget {
//   final String title;
//   final String time;
//   const _PunchCard({required this.title, required this.time});

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Column(
//       children: [
//         Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1E1E1E))),
//         const SizedBox(height: 6),
//         Text(time, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFEA7A3B))),
//       ],
//     );
//   }
// }



/*

class MarkAttendanceView extends StatefulWidget {
  const MarkAttendanceView({super.key});

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  final loc.Location location = loc.Location();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _currentMarkerIcon;
  BitmapDescriptor? _shopMarkerIcon;
  LatLng? _currentLatLng;
  CameraPosition? _initialCameraPosition;
  String distanceInfo = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMapReady = false;
  String _dateTime = "";
  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat("EEEE, dd-MMM-yyyy HH:mm:ss").format(now);
    setState(() {
      _dateTime = formatted;
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'Attendance Details'));
    _initMap();
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  Future<void> _initMap() async {
    await _loadCustomMarkers();
    await _requestPermissionAndFetchLocation();
    setState(() {
      distanceInfo = '';
    });
  }

  Future<void> _loadCustomMarkers() async {
    _currentMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/g_marker_no_badge_cropped_v2.png',
    );
  }

  // Inside your State class
  String _currentAddress = "Fetching location...";

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          _currentAddress =
              "${place.thoroughfare}, ${place.subLocality}, ${place.locality},";
        });
        print("STREET ${place.street}");
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Unable to fetch address";
      });
    }
  }

  Future<void> _requestPermissionAndFetchLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();
    _currentLatLng = LatLng(
      currentLocation.latitude ?? 24.8607,
      currentLocation.longitude ?? 67.0011,
    );

    _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 14);

    if (_currentMarkerIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLatLng!,
          icon: _currentMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    await _getAddressFromLatLng(_currentLatLng!);
  }

  void _recenterToCurrentLocation() {
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    LatLngBounds? visibleRegion;
    do {
      visibleRegion = await _mapController.getVisibleRegion();
    } while (visibleRegion.southwest.latitude == -90.0);

    setState(() {
      _isMapReady = true;
    });
  }

  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF2F3F5);
  static const Color card = Colors.white;
  static const accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    var formattedTimeDate;

    String formatToHms(String input) {
      // keep only digits
      var s = input.replaceAll(RegExp(r'\D'), '');
      // cap at 6 and left-pad with zeros
      s = s.length > 6 ? s.substring(0, 6) : s.padLeft(6, '0');
      final hh = s.substring(0, 2);
      final mm = s.substring(2, 4);
      final ss = s.substring(4, 6);
      return '$hh:$mm:$ss';
    }

    if (context
            .read<GlobalBloc>()
            .state
            .loginModel
            ?.statusAttendance
            .toString() ==
        "1") {
      formattedTimeDate = formatToHms(
        context.read<GlobalBloc>().state.loginModel!.log!.tim.toString(),
      );
    }

    final loginModel = context.read<GlobalBloc>().state.loginModel;
    final hasAttendanceOut = loginModel?.log?.tim != null;

    final attendanceStatus = hasAttendanceOut
        ? "ATTENDANCE OUT"
        : "ATTENDANCE IN";

            int dedupJourneyCount(List<JourneyPlan> plans) {
      final seen = <String>{};
      for (final p in plans) {
        final accode = p.accode.trim();
        final key = accode.isNotEmpty
            ? 'ID:${accode.toLowerCase()}'
            : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
        seen.add(key);
      }
      return seen.length;
    }

      int _coveredRoutesCount = 0;
        int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
        
                    final box = GetStorage();
        _coveredRoutesCount = _asInt(box.read('covered_routes_count'));


           final jpCount = dedupJourneyCount(
      context.read<GlobalBloc>().state.loginModel!.journeyPlan,
    );

    final routeCompleted = (jpCount == _coveredRoutesCount);
    return Scaffold(
      body: Stack(
        children: [
          if (_initialCameraPosition != null)
            GoogleMap(
              padding: const EdgeInsets.only(bottom: 60),
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition!,
              mapType: MapType.normal,
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

          if (distanceInfo.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distanceInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Container(
              height: 310,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    decoration: BoxDecoration(
                      color: field,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: orange.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: t.bodyMedium?.copyWith(color: muted),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _recenterToCurrentLocation();
                          },
                          icon: Icon(Icons.my_location, color: orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  BlocBuilder<GlobalBloc, GlobalState>(
                    builder: (context, state) {
                      return state.loginModel!.statusAttendance == "1"
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PunchCard(
                                  title: "Punch In",
                                  time: formattedTimeDate ?? "--:--",
                                ),
                                _PunchCard(title: "Punch Out", time: "--:--"),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PunchCard(title: "Punch In", time: "--:--"),
                                _PunchCard(title: "Punch Out", time: "--:--"),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 5),

                  Center(
  child: SizedBox(
    width: MediaQuery.of(context).size.width * 0.50,
    height: 50,
    child: BlocBuilder<GlobalBloc, GlobalState>(
      builder: (context, state) {
        final isLoading =
            state.markAttendanceStatus == MarkAttendanceStatus.loading;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isLoading
              ? null
              : () async {
                
                  // your existing onPressed body stays the same 👇
                  if (context
                          .read<GlobalBloc>()
                          .state
                          .loginModel
                          ?.statusAttendance
                          .toString() ==
                      "1") {
                    toastWidget(
                      'Complete your journey plan first',
                      Colors.red,
                    );
                  } else {
                    final current = await location.getLocation();
                    final lat = current.latitude;
                    final lng = current.longitude;
                    if (lat == null || lng == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not get your location'),
                        ),
                      );
                      return;
                    }

                    final bloc = context.read<GlobalBloc>();
                    final userId =
                        bloc.state.loginModel?.userinfo?.userId?.toString();
                    if (userId == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User session missing'),
                        ),
                      );
                      return;
                    }

                    bloc.add(
                      MarkAttendanceEvent(
                        action: 'IN',
                        lat: lat.toString(),
                        lng: lng.toString(),
                        type: '1',
                        userId: userId,
                      ),
                    );

                    final attendStatus = await bloc.stream
                        .map((s) => s.markAttendanceStatus)
                        .distinct()
                        .firstWhere(
                          (st) =>
                              st == MarkAttendanceStatus.success ||
                              st == MarkAttendanceStatus.failure,
                        );

                    if (attendStatus != MarkAttendanceStatus.success) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attendance failed'),
                        ),
                      );
                      return;
                    }

                    final box = GetStorage();
                    final email = box.read<String>("email");
                    final password = box.read<String>("password");
                    if (email != null && password != null) {
                      bloc.add(
                        LoginEvent(email: email, password: password),
                      );
                      final loginStatus = await bloc.stream
                          .map((s) => s.status)
                          .distinct()
                          .firstWhere(
                            (st) =>
                                st == LoginStatus.success ||
                                st == LoginStatus.failure,
                          );

                      if (loginStatus != LoginStatus.success) {
                        if (!mounted) return;
                        final msg =
                            bloc.state.loginModel?.message ??
                            'Login refresh failed';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                        return;
                      }
                    }

                    if (!mounted) return;
                    showCenteredToast(
                      context,
                      'Attendance Marked Successfully',
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeUpdated(),
                      ),
                    );
                  }
                },
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                routeCompleted== true ?
                "Route Done".toUpperCase(): "Mark attendance".toUpperCase(),

                  // context
                  //             .read<GlobalBloc>()
                  //             .state
                  //             .loginModel
                  //             ?.log
                  //             ?.tim !=
                  //         null
                  //     ? "ATTENDANCE OUT"
                  //     : "ATTENDANCE IN",
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        );
      },
    ),
  ),
),


                /*  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.50,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (context
                                  .read<GlobalBloc>()
                                  .state
                                  .loginModel
                                  ?.statusAttendance
                                  .toString() ==
                              "1") {
                            toastWidget(
                              'Complete your journey plan first',
                              Colors.red,
                            );

                            // showCenteredToast(context, 'Complete Your Journey Plan First');
                          } else {
                            final current = await location.getLocation();
                            final lat = current.latitude;
                            final lng = current.longitude;
                            if (lat == null || lng == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not get your location'),
                                ),
                              );
                              return;
                            }

                            final bloc = context.read<GlobalBloc>();
                            final userId = bloc
                                .state
                                .loginModel
                                ?.userinfo
                                ?.userId
                                ?.toString();
                            if (userId == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User session missing'),
                                ),
                              );
                              return;
                            }

                            bloc.add(
                              MarkAttendanceEvent(
                                action: 'IN',
                                lat: lat.toString(),
                                lng: lng.toString(),
                                type: '1',
                                userId: userId,
                              ),
                            );

                            final attendStatus = await bloc.stream
                                .map((s) => s.markAttendanceStatus)
                                .distinct()
                                .firstWhere(
                                  (st) =>
                                      st == MarkAttendanceStatus.success ||
                                      st == MarkAttendanceStatus.failure,
                                );

                            if (attendStatus != MarkAttendanceStatus.success) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attendance failed'),
                                ),
                              );
                              return;
                            }

                            final box = GetStorage();
                            final email = box.read<String>("email");
                            final password = box.read<String>("password");
                            if (email != null && password != null) {
                              bloc.add(
                                LoginEvent(email: email, password: password),
                              );
                              final loginStatus = await bloc.stream
                                  .map((s) => s.status)
                                  .distinct()
                                  .firstWhere(
                                    (st) =>
                                        st == LoginStatus.success ||
                                        st == LoginStatus.failure,
                                  );

                              if (loginStatus != LoginStatus.success) {
                                if (!mounted) return;
                                final msg =
                                    bloc.state.loginModel?.message ??
                                    'Login refresh failed';
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                                return;
                              }
                            }

                            if (!mounted) return;

                            showCenteredToast(
                              context,
                              'Attendance Marked Successfully',
                            );
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(content: Text('Attendance marked successfully')),
                            // );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeUpdated(),
                              ),
                            );
                          }
                          // if (context
                          //         .read<GlobalBloc>()
                          //         .state
                          //         .loginModel!
                          //         .journeyPlan!
                          //         .length !=
                          //     0) {
                          //   if (context
                          //           .read<GlobalBloc>()
                          //           .state
                          //           .loginModel!
                          //           .reasons
                          //           .length !=
                          //       context
                          //           .read<GlobalBloc>()
                          //           .state
                          //           .loginModel!
                          //           .journeyPlan
                          //           .length) {
                          // toastWidget(
                          //   'Complete your journey plan first',
                          //   Colors.red,
                          // );
                          //   } else if (context
                          //           .read<GlobalBloc>()
                          //           .state
                          //           .loginModel!
                          //           .reasons!
                          //           .length ==
                          //       context
                          //           .read<GlobalBloc>()
                          //           .state
                          //           .loginModel!
                          //           .journeyPlan!
                          //           .length) {
                          //     final currentLocation = await location
                          //         .getLocation();

                          //     // context.read<GlobalBloc>().add(
                          //     //   MarkAttendanceEvent(
                          //     //     lat: currentLocation.latitude.toString(),
                          //     //     lng: currentLocation.longitude.toString(),
                          //     //     type: '0',
                          //     //     userId: context
                          //     //         .read<GlobalBloc>()
                          //     //         .state
                          //     //         .loginModel!
                          //     //         .userinfo!
                          //     //         .userId
                          //     //         .toString(),
                          //     //   ),
                          //     // );
                          //   }
                          // } else {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => SelfieCaptureScreen(),
                          //   ),
                          // );
                          // }
                        },
                        child: Text(
                          attendanceStatus,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),*/
                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      _dateTime,
                      style: t.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchCard extends StatelessWidget {
  final String title;
  final String time;
  const _PunchCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          title,
          style: t.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Color(0xFFEA7A3B),
          ),
        ),
      ],
    );
  }
}
*/