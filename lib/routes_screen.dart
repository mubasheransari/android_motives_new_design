import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm; // 👈 add this
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';

// // 👇 move enum to top-level
// enum _DialogResult { tryAgain, openSettings, cancel }

// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});
//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   static const Color orange = Color(0xFFEA7A3B);
//   static const Color muted = Color(0xFF707883);
//   static const Color field = Color(0xFFF5F5F7);
//   static const Color card = Colors.white;
//   static const Color _shadow = Color(0x14000000);

//   final loc.Location location = loc.Location();
//   final GetStorage storage = GetStorage();

//   static const String routeKey = 'isRouteStarted';
//   bool isRouteStarted = false;

//   int _coveredRoutesCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     context.read<GlobalBloc>().add(Activity(activity: 'Routes Details'));
//     _loadRouteStatus();

//     _coveredRoutesCount = _asInt(storage.read('covered_routes_count'));
//     storage.listenKey('covered_routes_count', (v) {
//       if (!mounted) return;
//       setState(() => _coveredRoutesCount = _asInt(v));
//     });
//   }

//   int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

//   void _loadRouteStatus() {
//     final saved = storage.read("routeKey") ?? false;
//     setState(() => isRouteStarted = saved);
//   }

//   Future<void> _setRouteStatus(bool value) async {
//     await storage.write("routeKey", value);
//     if (!mounted) return;
//     setState(() => isRouteStarted = value);
//   }

//   // ─────────────────────────────────────────────
//   // LOCATION GUARD
//   // ─────────────────────────────────────────────
//   Future<loc.LocationData?> _ensureLocationReady() async {
//     // 1) PERMISSION LOOP
//     while (true) {
//       // ask OS via plugin
//       var permStatus = await location.hasPermission();

//       if (permStatus != loc.PermissionStatus.granted &&
//           permStatus != loc.PermissionStatus.grantedLimited) {
//         permStatus = await location.requestPermission();
//       }

//       // granted → continue
//       if (permStatus == loc.PermissionStatus.granted ||
//           permStatus == loc.PermissionStatus.grantedLimited) {
//         break;
//       }

//       // denied (not forever) → show dialog with "Try again"
//       if (permStatus == loc.PermissionStatus.denied) {
//         final r = await _showLocationRequiredDialog(
//           title: 'Location Required',
//           message:
//               'Location permission is required to start your route.\n\nPlease allow location and try again.',
//           showSettings: false,
//         );
//         if (r == _DialogResult.tryAgain) {
//           // loop again, will call requestPermission again
//           continue;
//         } else {
//           return null;
//         }
//       }

//       // deniedForever → only app settings can fix
//       if (permStatus == loc.PermissionStatus.deniedForever) {
//         final r = await _showLocationRequiredDialog(
//           title: 'Permission Blocked',
//           message:
//               'Location permission is blocked by the system.\n\nOpen settings, enable location for this app, then come back.',
//           showSettings: true,
//         );
//         if (r == _DialogResult.openSettings) {
//           // open OS settings via permission_handler
//           await perm.openAppSettings();
//           // after user comes back → loop again
//           continue;
//         } else if (r == _DialogResult.tryAgain) {
//           // will attempt again, may still be deniedForever
//           continue;
//         } else {
//           return null;
//         }
//       }
//     }

//     // 2) SERVICE (GPS)
//     while (true) {
//       var serviceEnabled = await location.serviceEnabled();
//       if (serviceEnabled) break;

//       final r = await _showLocationRequiredDialog(
//         title: 'Location Service',
//         message: 'Location (GPS) is OFF.\n\nPlease turn it ON to continue.',
//         showSettings: true,
//       );

//       // first try native request
//       serviceEnabled = await location.requestService();
//       if (serviceEnabled) break;

//       if (r == _DialogResult.openSettings) {
//         // we don’t have location.openLocationSettings() on this plugin,
//         // so tell user to open device settings manually
//         await perm.openAppSettings();
//         continue;
//       } else {
//         // keep looping to force user
//         continue;
//       }
//     }

//     // 3) TRY TO GET LOCATION (with retry)
//     while (true) {
//       try {
//         return await location.getLocation();
//       } catch (_) {
//         final r = await _showLocationRequiredDialog(
//           title: 'Location Error',
//           message: 'Unable to get current location. Please try again.',
//           showSettings: false,
//         );
//         if (r == _DialogResult.tryAgain) {
//           continue;
//         } else {
//           return null;
//         }
//       }
//     }
//   }

//   Future<_DialogResult> _showLocationRequiredDialog({
//     required String title,
//     required String message,
//     required bool showSettings,
//   }) async {
//     _DialogResult result = _DialogResult.cancel;
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogCtx) => _GlassDialog(
//         title: title,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 message,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(color: const Color(0xFF1E1E1E)),
//               ),
//               const SizedBox(height: 14),
//               if (showSettings) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: orange,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       elevation: 0,
//                     ),
//                     onPressed: () {
//                       result = _DialogResult.openSettings;
//                       Navigator.of(dialogCtx).pop();
//                     },
//                     child: const Text('Open Settings'),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: muted,
//                     side: BorderSide(color: muted.withOpacity(.35)),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                   ),
//                   onPressed: () {
//                     result = _DialogResult.tryAgain;
//                     Navigator.of(dialogCtx).pop();
//                   },
//                   child: const Text('Try Again'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//     return result;
//   }

//   // ─────────────────────────────────────────────
//   // START / END
//   // ─────────────────────────────────────────────
//   Future<void> _startRoute(
//       BuildContext context, String userId, String disid) async {
//     final currentLocation = await _ensureLocationReady();
//     if (currentLocation == null) return;

//     context.read<GlobalBloc>().add(
//           StartRouteEvent(
//             action: 'IN',
//             type: '3',
//             userId: userId,
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//             disid: disid,
//           ),
//         );
//     await _setRouteStatus(true);
//   }

//   Future<void> _endRoute(
//       BuildContext context, String userId, String disid) async {
//     final currentLocation = await _ensureLocationReady();
//     if (currentLocation == null) return;

//     context.read<GlobalBloc>().add(
//           MarkAttendanceEvent(
//             action: 'OUT',
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//             type: '2',
//             userId: userId,
//           ),
//         );

//     context.read<GlobalBloc>().add(
//           StartRouteEvent(
//             disid: disid,
//             action: 'OUT',
//             type: '4',
//             userId: userId,
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//           ),
//         );
//     await _setRouteStatus(false);

//     // refresh login
//     final box = GetStorage();
//   //  box.remove('covered_routes_count');
//     final email = box.read<String>("email");
//     final password = box.read<String>("password");
//     final bloc = context.read<GlobalBloc>();
//     if (email != null && password != null) {
//       bloc.add(LoginEvent(email: email, password: password));
//       final loginStatus = await bloc.stream
//           .map((s) => s.status)
//           .distinct()
//           .firstWhere(
//               (st) => st == LoginStatus.success || st == LoginStatus.failure);
//       if (loginStatus != LoginStatus.success) {
//         if (!mounted) return;
//         final msg = bloc.state.loginModel?.message ?? 'Login refresh failed';
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text(msg)));
//         return;
//       }
//     }
//   }

//   int _dedupJourneyCount(List<JourneyPlan> plans) {
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

//     return BlocBuilder<GlobalBloc, GlobalState>(
//       buildWhen: (p, c) =>
//           p.loginModel?.reasons.length != c.loginModel?.reasons.length ||
//           p.loginModel?.journeyPlan.length != c.loginModel?.journeyPlan.length,
//       builder: (context, state) {
//         final login = state.loginModel!;
//         final userId = login.userinfo!.userId.toString();
//         final distributionId = login.userinfo!.disid.toString();

//         final jpCount = _dedupJourneyCount(login.journeyPlan);
//         final covereRouteCount = _coveredRoutesCount;
//         final canEndRoute = isRouteStarted && (jpCount == covereRouteCount);

//         bool _btnBusy = false;

//         return Scaffold(
//           backgroundColor: Colors.white,
//           body: SafeArea(
//             child: CustomScrollView(
//               physics: const BouncingScrollPhysics(),
//               slivers: [
//                 // HEADER
//                 SliverToBoxAdapter(
//                   child: Stack(
//                     children: [
//                       Container(
//                         height: 160,
//                         decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                         child: _GlassHeader(
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(.20),
//                                   shape: BoxShape.circle,
//                                   border:
//                                       Border.all(color: Colors.white, width: 1.2),
//                                 ),
//                                 child: const Icon(Icons.alt_route,
//                                     color: Colors.white, size: 20),
//                               ),
//                               const SizedBox(width: 14),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Routes',
//                                       style: t.titleMedium?.copyWith(
//                                         color: Colors.white.withOpacity(.95),
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                     Text(
//                                       isRouteStarted
//                                           ? 'Route is started'
//                                           : 'Start your route',
//                                       overflow: TextOverflow.ellipsis,
//                                       style: t.headlineSmall?.copyWith(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w800,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 115,
//                         left: 20,
//                         child: _StatusPill(
//                           icon: Icons.access_time,
//                           label:
//                               '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // BODY
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _MiniStatCard(
//                                 title: 'Planned',
//                                 value: '$jpCount',
//                                 icon: Icons.alt_route,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _MiniStatCard(
//                                 title: 'Done',
//                                 value: covereRouteCount.toString(),
//                                 icon: Icons.check_circle_rounded,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 18),
//                         SizedBox(
//   height: 54,
//   width: double.infinity,
//   child: Builder(
//     builder: (context) {
//       // listen to bloc loading states
//       final state = context.watch<GlobalBloc>().state;
//       final blocLoading =
//           state.startRouteStatus == StartRouteStatus.loading ||
//           state.markAttendanceStatus == MarkAttendanceStatus.loading;

//       final isLoading = _btnBusy || blocLoading;

//       final canEndRoute = isRouteStarted &&
//           (_dedupJourneyCount(state.loginModel!.journeyPlan) == _coveredRoutesCount);

//       return ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: (!isRouteStarted || canEndRoute)
//               ? const Color(0xFFEA7A3B)
//               : const Color(0xFFEA7A3B).withOpacity(.5),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: 0,
//         ),
//         onPressed: isLoading
//             ? null
//             : (!isRouteStarted
//                 ? () => _startRoute(context,
//                     state.loginModel!.userinfo!.userId.toString(),
//                     state.loginModel!.userinfo!.disid.toString())
//                 : (canEndRoute
//                     ? () => _endRoute(context,
//                         state.loginModel!.userinfo!.userId.toString(),
//                         state.loginModel!.userinfo!.disid.toString())
//                     : null)),
//         child: isLoading
//             ? const SizedBox(
//                 width: 22,
//                 height: 22,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.4,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             : Text(
//                 !isRouteStarted ? 'Start your route' : 'End Route',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                       letterSpacing: .2,
//                     ),
//               ),
//       );
//     },
//   ),
// ),


//                        /* SizedBox(
//                           height: 54,
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: (!isRouteStarted || canEndRoute)
//                                   ? orange
//                                   : orange.withOpacity(.5),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 0,
//                             ),
//                             onPressed: !isRouteStarted
//                                 ? () =>
//                                     _startRoute(context, userId, distributionId)
//                                 : (canEndRoute
//                                     ? () => _endRoute(
//                                           context,
//                                           userId,
//                                           distributionId,
//                                         )
//                                     : null),
//                             child: Text(
//                               !isRouteStarted ? 'Start your route' : 'End Route',
//                               style: t.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.white,
//                                 letterSpacing: .2,
//                               ),
//                             ),
//                           ),
//                         ),*/
//                         const SizedBox(height: 12),
//                         if (isRouteStarted && !canEndRoute)
//                           Text(
//                             'Complete all planned visits before ending route.',
//                             style: t.bodyMedium?.copyWith(color: muted),
//                             textAlign: TextAlign.center,
//                           ),
//                         const SizedBox(height: 28),
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: card,
//                             borderRadius: BorderRadius.circular(14),
//                             boxShadow: const [
//                               BoxShadow(
//                                 color: _shadow,
//                                 blurRadius: 16,
//                                 offset: Offset(0, 10),
//                               ),
//                             ],
//                             border: Border.all(
//                               color: const Color(0xFFFFB07A).withOpacity(.35),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 46,
//                                 height: 46,
//                                 decoration: BoxDecoration(
//                                   color: field,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(Icons.info_outline,
//                                     color: Color(0xFFEA7A3B)),
//                               ),
//                               const SizedBox(width: 14),
//                               Expanded(
//                                 child: Text(
//                                   isRouteStarted
//                                       ? (canEndRoute
//                                           ? 'You can now end the route.'
//                                           : 'Route is started. Finish your visits to enable End Route.')
//                                       : 'Tap “Start your route” to begin and share your location.',
//                                   style: t.bodyMedium?.copyWith(color: muted),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ── small widgets ─────────────────────────────────────────────

// class _MiniStatCard extends StatelessWidget {
//   const _MiniStatCard({
//     required this.title,
//     required this.value,
//     required this.icon,
//   });
//   final String title;
//   final String value;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 16,
//               offset: Offset(0, 10),
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
//               child: Icon(icon, color: const Color(0xFFEA7A3B)),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style:
//                         t.bodySmall?.copyWith(color: const Color(0xFF707883)),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     value,
//                     style: t.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w800,
//                       color: const Color(0xFF1E1E1E),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _StatusPill extends StatelessWidget {
//   const _StatusPill({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.16),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withOpacity(.45), width: .8),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 16, color: Colors.white),
//         const SizedBox(width: 8),
//         Text(
//           'ATTENDANCE-IN : '.toUpperCase(),
//           style: t.bodySmall?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             letterSpacing: .3,
//           ),
//         ),
//         Text(
//           label,
//           style: t.bodySmall?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             letterSpacing: .3,
//           ),
//         ),
//       ]),
//     );
//   }
// }

// class _GlassDialog extends StatelessWidget {
//   final String title;
//   final Widget child;
//   const _GlassDialog({required this.title, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       backgroundColor: Colors.transparent,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFFEA7A3B), Color(0xFFFFB07A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(1.8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [
//               BoxShadow(
//                   color: Color(0x14000000),
//                   blurRadius: 16,
//                   offset: Offset(0, 10))
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF2F3F5),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                 ),
//                 child: Text(
//                   title,
//                   textAlign: TextAlign.center,
//                   style: t.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w800,
//                     color: const Color(0xFF1E1E1E),
//                   ),
//                 ),
//               ),
//               child,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



enum _DialogResult { tryAgain, openSettings, cancel }

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});
  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const Color orange = Color(0xFFEA7A3B);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF5F5F7);
  static const Color card = Colors.white;
  static const Color _shadow = Color(0x14000000);

  final loc.Location location = loc.Location();
  final GetStorage storage = GetStorage();

  static const String routeKey = 'routeKey'; // same as in HomeUpdated
  bool isRouteStarted = false;

  int _coveredRoutesCount = 0;

  // same keys as MarkAttendance & HomeUpdated
  static const String kAttendanceFlagKey = 'attendance_marked_flag';
  static const String kAttendanceDateKey = 'attendance_marked_date';
  static const String kRouteLockKey = 'route_complete_lock_date';

  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'Routes Details'));
    _syncDailyFlagsAndRouteStatus();

    _coveredRoutesCount = _asInt(storage.read('covered_routes_count'));
    storage.listenKey('covered_routes_count', (v) {
      if (!mounted) return;
      setState(() => _coveredRoutesCount = _asInt(v));
    });
  }

  void _syncDailyFlagsAndRouteStatus() {
    final todayKey = _todayKey();

    // attendance date sync (same as MarkAttendanceView)
    final storedDate = storage.read<String>(kAttendanceDateKey);
    if (storedDate != todayKey) {
      storage.write(kAttendanceDateKey, todayKey);
      storage.write(kAttendanceFlagKey, false);
    }

    final saved = storage.read(routeKey) ?? false;
    final lockedDate = storage.read<String>(kRouteLockKey);
    final routeLockedToday = lockedDate == todayKey;

    // if route is locked for today, force isRouteStarted = false
    setState(() => isRouteStarted = routeLockedToday ? false : saved);
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  Future<void> _setRouteStatus(bool value) async {
    await storage.write(routeKey, value);
    if (!mounted) return;
    setState(() => isRouteStarted = value);
  }

  // ─────────────────────────────────────────────
  // LOCATION GUARD
  // ─────────────────────────────────────────────
  Future<loc.LocationData?> _ensureLocationReady() async {
    // 1) PERMISSION LOOP
    while (true) {
      var permStatus = await location.hasPermission();

      if (permStatus != loc.PermissionStatus.granted &&
          permStatus != loc.PermissionStatus.grantedLimited) {
        permStatus = await location.requestPermission();
      }

      if (permStatus == loc.PermissionStatus.granted ||
          permStatus == loc.PermissionStatus.grantedLimited) {
        break;
      }

      if (permStatus == loc.PermissionStatus.denied) {
        final r = await _showLocationRequiredDialog(
          title: 'Location Required',
          message:
              'Location permission is required to start or end your route.\n\nPlease allow location and try again.',
          showSettings: false,
        );
        if (r == _DialogResult.tryAgain) {
          continue;
        } else {
          return null;
        }
      }

      if (permStatus == loc.PermissionStatus.deniedForever) {
        final r = await _showLocationRequiredDialog(
          title: 'Permission Blocked',
          message:
              'Location permission is blocked by the system.\n\nOpen settings, enable location for this app, then come back.',
          showSettings: true,
        );
        if (r == _DialogResult.openSettings) {
          await perm.openAppSettings();
          continue;
        } else if (r == _DialogResult.tryAgain) {
          continue;
        } else {
          return null;
        }
      }
    }

    // 2) SERVICE (GPS)
    while (true) {
      var serviceEnabled = await location.serviceEnabled();
      if (serviceEnabled) break;

      final r = await _showLocationRequiredDialog(
        title: 'Location Service',
        message: 'Location (GPS) is OFF.\n\nPlease turn it ON to continue.',
        showSettings: true,
      );

      serviceEnabled = await location.requestService();
      if (serviceEnabled) break;

      if (r == _DialogResult.openSettings) {
        await perm.openAppSettings();
        continue;
      } else {
        continue;
      }
    }

    // 3) TRY TO GET LOCATION (with retry)
    while (true) {
      try {
        return await location.getLocation();
      } catch (_) {
        final r = await _showLocationRequiredDialog(
          title: 'Location Error',
          message: 'Unable to get current location. Please try again.',
          showSettings: false,
        );
        if (r == _DialogResult.tryAgain) {
          continue;
        } else {
          return null;
        }
      }
    }
  }

  Future<_DialogResult> _showLocationRequiredDialog({
    required String title,
    required String message,
    required bool showSettings,
  }) async {
    _DialogResult result = _DialogResult.cancel;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: const Color(0xFF1E1E1E)),
              ),
              const SizedBox(height: 14),
              if (showSettings) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      result = _DialogResult.openSettings;
                      Navigator.of(dialogCtx).pop();
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: muted,
                    side: BorderSide(color: muted.withOpacity(.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    result = _DialogResult.tryAgain;
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  // ─────────────────────────────────────────────
  // START / END (manual)
  // ─────────────────────────────────────────────
  Future<void> _startRoute(
      BuildContext context, String userId, String disid) async {
    final todayKey = _todayKey();
    final lockedDate = storage.read<String>(kRouteLockKey);
    final routeLockedToday = lockedDate == todayKey;
    if (routeLockedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today’s route is locked.')),
      );
      return;
    }

    final currentLocation = await _ensureLocationReady();
    if (currentLocation == null) return;

    context.read<GlobalBloc>().add(
          StartRouteEvent(
            action: 'IN',
            type: '3',
            userId: userId,
            lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
            disid: disid,
          ),
        );
    await _setRouteStatus(true);
  }

  Future<void> _endRoute(
      BuildContext context, String userId, String disid) async {
    final currentLocation = await _ensureLocationReady();
    if (currentLocation == null) return;

    // Attendance OUT
    context.read<GlobalBloc>().add(
          MarkAttendanceEvent(
            action: 'OUT',
            lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
            type: '2',
            userId: userId,
          ),
        );

    // Route OUT
    context.read<GlobalBloc>().add(
          StartRouteEvent(
            disid: disid,
            action: 'OUT',
            type: '4',
            userId: userId,
            lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
          ),
        );

    await _setRouteStatus(false);

    // 🔒 Lock route for today (this will disable Routes / Punch Order / Attendance on Home)
    final todayKey = _todayKey();
    storage.write(kRouteLockKey, todayKey);

    // refresh login (optional – keeps log/time fresh)
    final email = storage.read<String>("email");
    final password = storage.read<String>("password");
    final bloc = context.read<GlobalBloc>();
    if (email != null && password != null) {
      bloc.add(LoginEvent(email: email, password: password));
      final loginStatus = await bloc.stream
          .map((s) => s.status)
          .distinct()
          .firstWhere(
              (st) => st == LoginStatus.success || st == LoginStatus.failure);
      if (loginStatus != LoginStatus.success) {
        if (!mounted) return;
        final msg = bloc.state.loginModel?.message ?? 'Login refresh failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route ended and locked for today.')),
    );
  }

  int _dedupJourneyCount(List<JourneyPlan> plans) {
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

    return BlocBuilder<GlobalBloc, GlobalState>(
      buildWhen: (p, c) =>
          p.loginModel?.reasons.length != c.loginModel?.reasons.length ||
          p.loginModel?.journeyPlan.length != c.loginModel?.journeyPlan.length,
      builder: (context, state) {
        final login = state.loginModel!;
        final userId = login.userinfo!.userId.toString();
        final distributionId = login.userinfo!.disid.toString();

        final jpCount = _dedupJourneyCount(login.journeyPlan);
        final covereRouteCount = _coveredRoutesCount;

        final todayKey = _todayKey();
        final lockedDate = storage.read<String>(kRouteLockKey);
        final routeLockedToday = lockedDate == todayKey;

        final canEndRoute =
            isRouteStarted && !routeLockedToday && (jpCount == covereRouteCount);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 160,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _GlassHeader(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.alt_route,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Routes',
                                      style: t.titleMedium?.copyWith(
                                        color: Colors.white.withOpacity(.95),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      routeLockedToday
                                          ? 'Route locked for today'
                                          : (isRouteStarted
                                              ? 'Route is started'
                                              : 'Start your route'),
                                      overflow: TextOverflow.ellipsis,
                                      style: t.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 115,
                        left: 20,
                        child: _StatusPill(
                          icon: Icons.access_time,
                          label:
                              '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}',
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Planned',
                                value: '$jpCount',
                                icon: Icons.alt_route,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Done',
                                value: covereRouteCount.toString(),
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: Builder(
                            builder: (context) {
                              final state = context.watch<GlobalBloc>().state;
                              final blocLoading =
                                  state.startRouteStatus ==
                                          StartRouteStatus.loading ||
                                      state.markAttendanceStatus ==
                                          MarkAttendanceStatus.loading;

                              final isLoading = blocLoading;

                              String buttonLabel;
                              VoidCallback? onPressed;

                              if (routeLockedToday) {
                                buttonLabel = 'Route closed for today';
                                onPressed = null;
                              } else if (!isRouteStarted) {
                                buttonLabel = 'Start your route';
                                onPressed = isLoading
                                    ? null
                                    : () => _startRoute(
                                          context,
                                          state.loginModel!.userinfo!.userId
                                              .toString(),
                                          state.loginModel!.userinfo!.disid
                                              .toString(),
                                        );
                              } else {
                                buttonLabel = 'End Route';
                                if (!canEndRoute || isLoading) {
                                  onPressed = null;
                                } else {
                                  onPressed = () => _endRoute(
                                        context,
                                        state.loginModel!.userinfo!.userId
                                            .toString(),
                                        state.loginModel!.userinfo!.disid
                                            .toString(),
                                      );
                                }
                              }

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (onPressed != null)
                                      ? const Color(0xFFEA7A3B)
                                      : const Color(0xFFEA7A3B)
                                          .withOpacity(.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: onPressed,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        buttonLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: .2,
                                            ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!routeLockedToday && isRouteStarted && !canEndRoute)
                          Text(
                            'Complete all planned visits before ending route.',
                            style: t.bodyMedium?.copyWith(color: muted),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: _shadow,
                                blurRadius: 16,
                                offset: Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFFFB07A).withOpacity(.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: field,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.info_outline,
                                    color: Color(0xFFEA7A3B)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  routeLockedToday
                                      ? 'Today’s route has been ended and locked. You cannot start a new route until tomorrow.'
                                      : (!isRouteStarted
                                          ? 'Tap “Start your route” to begin and share your location.'
                                          : (canEndRoute
                                              ? 'You can now end the route.'
                                              : 'Route is started. Finish your visits to enable End Route.')),
                                  style: t.bodyMedium?.copyWith(color: muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── small widgets ─────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 10),
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
              child: Icon(icon, color: const Color(0xFFEA7A3B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        t.bodySmall?.copyWith(color: const Color(0xFF707883)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.45), width: .8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'ATTENDANCE-IN : '.toUpperCase(),
          style: t.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
        Text(
          label,
          style: t.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
      ]),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEA7A3B), Color(0xFFFFB07A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
