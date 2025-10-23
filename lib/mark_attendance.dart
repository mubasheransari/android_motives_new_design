import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/capture_selfie.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';

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
                                  .loginModel!
                                  .journeyPlan!
                                  .length !=
                              0) {
                            if (context
                                    .read<GlobalBloc>()
                                    .state
                                    .loginModel!
                                    .reasons
                                    .length !=
                                context
                                    .read<GlobalBloc>()
                                    .state
                                    .loginModel!
                                    .journeyPlan
                                    .length) {
                              toastWidget(
                                'Complete your journey plan first',
                                Colors.red,
                              );
                            } else if (context
                                    .read<GlobalBloc>()
                                    .state
                                    .loginModel!
                                    .reasons!
                                    .length ==
                                context
                                    .read<GlobalBloc>()
                                    .state
                                    .loginModel!
                                    .journeyPlan!
                                    .length) {
                              final currentLocation = await location
                                  .getLocation();

                              // context.read<GlobalBloc>().add(
                              //   MarkAttendanceEvent(
                              //     lat: currentLocation.latitude.toString(),
                              //     lng: currentLocation.longitude.toString(),
                              //     type: '0',
                              //     userId: context
                              //         .read<GlobalBloc>()
                              //         .state
                              //         .loginModel!
                              //         .userinfo!
                              //         .userId
                              //         .toString(),
                              //   ),
                              // );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelfieCaptureScreen(),
                              ),
                            );
                          }
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
