import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'dart:ui';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Models/login_model.dart';


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

  static const String routeKey = 'isRouteStarted';
  bool isRouteStarted = false;

  // ✅ NEW: live “Done” value
  int _coveredRoutesCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'Routes Details'));
    _loadRouteStatus();

    // ✅ seed current count
    _coveredRoutesCount = _asInt(storage.read('covered_routes_count'));

    // ✅ auto-update when JourneyPlanScreen writes new count
    storage.listenKey('covered_routes_count', (v) {
      if (!mounted) return;
      setState(() => _coveredRoutesCount = _asInt(v));
    });
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  void _loadRouteStatus() {
    final saved = storage.read(routeKey) ?? false;
    setState(() => isRouteStarted = saved);
  }

  Future<void> _setRouteStatus(bool value) async {
    await storage.write(routeKey, value);
    if (!mounted) return;
    setState(() => isRouteStarted = value);
  }

  Future<void> _startRoute(BuildContext context, String userId) async {
    final currentLocation = await location.getLocation();
    context.read<GlobalBloc>().add(
          StartRouteEvent(
            action: 'IN',
            type: '1',
            userId: userId,
            lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
          ),
        );
    await _setRouteStatus(true);
  }

  Future<void> _endRoute(BuildContext context, String userId) async {
    final currentLocation = await location.getLocation();

    
    context.read<GlobalBloc>().add(MarkAttendanceEvent(
      action: 'OUT',
      lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
      type: '0',
      userId: userId,
    ));
    context.read<GlobalBloc>().add(
          StartRouteEvent(
            action: 'OUT',
            type: '0',
            userId: userId,
            lat: currentLocation.latitude.toString(),
            lng: currentLocation.longitude.toString(),
          ),
        );
    await _setRouteStatus(false);

        final box = GetStorage();
    final email = box.read<String>("email");
    final password = box.read<String>("password");
        final bloc = context.read<GlobalBloc>();
    if (email != null && password != null) {
      bloc.add(LoginEvent(email: email, password: password));
      final loginStatus = await bloc.stream
          .map((s) => s.status) // LoginStatus from your bloc
          .distinct()
          .firstWhere((st) =>
              st == LoginStatus.success || st == LoginStatus.failure);

      if (loginStatus != LoginStatus.success) {
        if (!mounted) return;
        final msg = bloc.state.loginModel?.message ?? 'Login refresh failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
    }
  }

  // same dedupe logic you used elsewhere — no UI change
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

        // Planned (dedup) — updates via BlocBuilder; unchanged UI
        final jpCount = _dedupJourneyCount(login.journeyPlan);

        // Done comes from GetStorage and now updates live via listenKey
        final covereRouteCount = _coveredRoutesCount;

        // end-route gate uses live values
        final canEndRoute = isRouteStarted && (jpCount == covereRouteCount);

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
                                  border: Border.all(color: Colors.white, width: 1.2),
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
                                      isRouteStarted
                                          ? 'Route is started'
                                          : 'Start your route',
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
                          label: '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}',
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (!isRouteStarted || canEndRoute)
                                  ? orange
                                  : orange.withOpacity(.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: !isRouteStarted
                                ? () => _startRoute(context, userId)
                                : (canEndRoute ? () => _endRoute(context, userId) : null),
                            child: Text(
                              !isRouteStarted ? 'Start your route' : 'End Route',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isRouteStarted && !canEndRoute)
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
                                  isRouteStarted
                                      ? (canEndRoute
                                          ? 'You can now end the route.'
                                          : 'Route is started. Finish your visits to enable End Route.')
                                      : 'Tap “Start your route” to begin and share your location.',
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
                color: Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFFEA7A3B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.bodySmall?.copyWith(color: Color(0xFF707883)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E1E),
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
//   GetStorage storage = GetStorage();

//   static const String routeKey = 'isRouteStarted';
//   bool isRouteStarted = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadRouteStatus();
//   }

//   void _loadRouteStatus() {
//     final saved = storage.read(routeKey) ?? false;
//     setState(() => isRouteStarted = saved);
//   }

//   Future<void> _setRouteStatus(bool value) async {
//     await storage.write(routeKey, value);
//     setState(() => isRouteStarted = value);
//   }

//   Future<void> _startRoute(BuildContext context, String userId) async {
//     final currentLocation = await location.getLocation();
//     context.read<GlobalBloc>().add(
//           StartRouteEvent(
//             action: 'IN',
//             type: '1',
//             userId: userId,
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//           ),
//         );
//     await _setRouteStatus(true);
//   }

//   Future<void> _endRoute(BuildContext context, String userId) async {
//     final currentLocation = await location.getLocation();
//     context.read<GlobalBloc>().add(
//           StartRouteEvent(
//             action: 'OUT',
//             type: '0',
//             userId: userId,
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//           ),
//         );
//     await _setRouteStatus(false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//         int dedupJourneyCount(List<JourneyPlan> plans) {
//   final seen = <String>{};
//   for (final p in plans) {
//     final accode = p.accode.trim();
//     final key = accode.isNotEmpty
//         ? 'ID:${accode.toLowerCase()}'
//         : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
//     seen.add(key);
//   }
//   return seen.length;
// }

// // use it:
// final jpCount = dedupJourneyCount(
//   context.read<GlobalBloc>().state.loginModel!.journeyPlan,
// );



//     return BlocBuilder<GlobalBloc, GlobalState>(
//       buildWhen: (p, c) =>
//           p.loginModel?.reasons.length != c.loginModel?.reasons.length ||
//           p.loginModel?.journeyPlan.length != c.loginModel?.journeyPlan.length,
//       builder: (context, state) {
//         final login = state.loginModel!;
//         final userId = login.userinfo!.userId.toString();
//        // final jpCount = login.journeyPlan.length;
//         final done = login.reasons.length;
//          var covereRouteCount =  storage.read('covered_routes_count');

//         final canEndRoute = isRouteStarted && (jpCount == covereRouteCount);

//           // var covereRouteCount =  storage.read('covered_routes_count');

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
//                                 child: _MiniStatCard(
//                                     title: 'Planned',
//                                     value: '$jpCount',
//                                     icon: Icons.alt_route)),
//                             const SizedBox(width: 12),
//                             Expanded(
//                                 child: _MiniStatCard(
//                                     title: 'Done',
//                                     value:covereRouteCount.toString(), //context.read<GlobalBloc>().state.routesCovered.toString(),//'$done',
//                                     icon: Icons.check_circle_rounded)),
//                           ],
//                         ),
//                         const SizedBox(height: 18),
//                         SizedBox(
//                           height: 54,
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: (!isRouteStarted || canEndRoute)
//                                   ? orange
//                                   : orange.withOpacity(.5),
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12)),
//                               elevation: 0,
//                             ),
//                             onPressed: !isRouteStarted
//                                 ? () => _startRoute(context, userId)
//                                 : (canEndRoute
//                                     ? () => _endRoute(context, userId)
//                                     : null),
//                             child: Text(
//                               !isRouteStarted
//                                   ? 'Start your route'
//                                   : 'End Route',
//                               style: t.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.white,
//                                 letterSpacing: .2,
//                               ),
//                             ),
//                           ),
//                         ),
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
//                                   color: _shadow,
//                                   blurRadius: 16,
//                                   offset: Offset(0, 10)),
//                             ],
//                             border: Border.all(
//                                 color:
//                                     const Color(0xFFFFB07A).withOpacity(.35),
//                                 width: 1),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 46,
//                                 height: 46,
//                                 decoration: BoxDecoration(
//                                     color: field,
//                                     borderRadius: BorderRadius.circular(12)),
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
//                                   style:
//                                       t.bodyMedium?.copyWith(color: muted),
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


// class _MiniStatCard extends StatelessWidget {
//   const _MiniStatCard(
//       {required this.title, required this.value, required this.icon});
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
//                 color: Color(0x14000000),
//                 blurRadius: 16,
//                 offset: Offset(0, 10))
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                   color: const Color(0xFFF5F5F7),
//                   borderRadius: BorderRadius.circular(12)),
//               child: Icon(icon, color: const Color(0xFFEA7A3B)),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style:
//                           t.bodySmall?.copyWith(color: const Color(0xFF707883))),
//                   const SizedBox(height: 2),
//                   Text(value,
//                       style: t.titleLarge?.copyWith(
//                           fontWeight: FontWeight.w800,
//                           color: const Color(0xFF1E1E1E))),
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
//         Text('ATTENDANCE-IN : '.toUpperCase(),
//             style: t.bodySmall?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: .3)),
//         Text(label,
//             style: t.bodySmall?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: .3)),
//       ]),
//     );
//   }
// }




/*class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});
  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const Color orange = Color(0xFFEA7A3B);
  static const Color muted  = Color(0xFF707883);
  static const Color field  = Color(0xFFF5F5F7);
  static const Color card   = Colors.white;
  static const Color _shadow= Color(0x14000000);

  final loc.Location location = loc.Location();
  bool isRouteStarted = false; // stays true until end-route succeeds

  Future<void> _startRoute(BuildContext context, String userId) async {
    final currentLocation = await location.getLocation();
    context.read<GlobalBloc>().add(
      StartRouteEvent(
        action: 'IN',
        type: '1',
        userId: userId,
        lat: currentLocation.latitude.toString(),
        lng: currentLocation.longitude.toString(),
      ),
    );
    setState(() => isRouteStarted = true); // lock as started
  }

  Future<void> _endRoute(BuildContext context, String userId) async {
    final currentLocation = await location.getLocation();
    context.read<GlobalBloc>().add(
      StartRouteEvent(
        action: 'OUT',
        type: '0',
        userId: userId,
        lat: currentLocation.latitude.toString(),
        lng: currentLocation.longitude.toString(),
      ),
    );
    setState(() => isRouteStarted = false); // reset after successful end
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocBuilder<GlobalBloc, GlobalState>(
      buildWhen: (p, c) => p.loginModel?.reasons.length != c.loginModel?.reasons.length
                          || p.loginModel?.journeyPlan.length != c.loginModel?.journeyPlan.length,
      builder: (context, state) {
        final login   = state.loginModel!;
        final userId  = login.userinfo!.userId.toString();
        final jpCount = login.journeyPlan.length;
        final done    = login.reasons.length;

        // Allow ending only when condition is met AND route has been started.
        final canEndRoute = isRouteStarted && (jpCount == done);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header (same theme)
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.20),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                    child: const Icon(Icons.alt_route, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Routes',
                                          style: t.titleMedium?.copyWith(
                                            color: Colors.white.withOpacity(.95),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          isRouteStarted ? 'Route is started' : 'Start your route',
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
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 115,
                        left: 20,
                        child: _StatusPill(
                          icon: Icons.access_time,
                          label: '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}',
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _MiniStatCard(title: 'Planned', value: '$jpCount', icon: Icons.alt_route)),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStatCard(title: 'Done', value: '$done',    icon: Icons.check_circle_rounded)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Button has 3 states:
                        // 1) Not started -> enabled "Start your route"
                        // 2) Started but cannot end -> disabled "End Route"
                        // 3) Started and can end -> enabled "End Route"
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canEndRoute || !isRouteStarted
                                  ? const Color(0xFFEA7A3B)
                                  : const Color(0xFFEA7A3B).withOpacity(.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: !isRouteStarted
                                ? () => _startRoute(context, userId)                  // start
                                : (canEndRoute ? () => _endRoute(context, userId)     // end
                                               : null),                               // locked
                            child: Text(
                              !isRouteStarted ? 'Start your route' : 'End Route',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Helper text when locked
                        if (isRouteStarted && !canEndRoute)
                          Text(
                            'Complete all planned visits before ending route.',
                            style: t.bodyMedium?.copyWith(color: muted),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 28),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10)),
                            ],
                            border: Border.all(color: const Color(0xFFFFB07A).withOpacity(.35), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.info_outline, color: Color(0xFFEA7A3B)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  isRouteStarted
                                      ? (canEndRoute
                                          ? 'You can now end the route.'
                                          : 'Route is started. Finish your visits to enable End Route.')
                                      : 'Tap “Start your route” to begin and share your location.',
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
    });
  }
}

// --- Reused themed helpers (same as earlier) ---

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.title, required this.value, required this.icon});
  final String title; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(12)),
              child:  Icon(icon, color: Color(0xFFEA7A3B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.bodySmall?.copyWith(color: const Color(0xFF707883))),
                const SizedBox(height: 2),
                Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1E1E1E))),
              ]),
            ),
           // Icon(icon, color: const Color(0xFFEA7A3B)),
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
  final IconData icon; final String label;
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
        Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 8),
                 Text('Attendance-In : '.toUpperCase(), style: t.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: .3)),

        Text(label, style: t.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: .3)),
      ]),
    );
  }
}

*/










// Reuse your HomeUpdated color palette
// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});

//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   static const Color orange = Color(0xFFEA7A3B);
//   static const Color text = Color(0xFF1E1E1E);
//   static const Color muted = Color(0xFF707883);
//   static const Color field = Color(0xFFF5F5F7);
//   static const Color card = Colors.white;
//   static const Color _shadow = Color(0x14000000);

//   final loc.Location location = loc.Location();
//   bool isRouteStarted = false;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     final state = context.read<GlobalBloc>().state;
//     final login = state.loginModel!;
//     final userId = login.userinfo!.userId.toString();
//     final jpCount = login.journeyPlan.length;
//     final reasonsCount = login.reasons.length;

//     Future<void> _startRoute() async {
//       final currentLocation = await location.getLocation();
//       context.read<GlobalBloc>().add(
//         StartRouteEvent(
//           action: 'IN',
//           type: '1',
//           userId: userId,
//           lat: currentLocation.latitude.toString(),
//           lng: currentLocation.longitude.toString(),
//         ),
//       );
//       setState(() => isRouteStarted = true);
//     }

//     Future<void> _endRoute() async {
//       if (jpCount == reasonsCount) {
//         final currentLocation = await location.getLocation();
//         context.read<GlobalBloc>().add(
//           StartRouteEvent(
//             action: 'OUT',
//             type: '0',
//             userId: userId,
//             lat: currentLocation.latitude.toString(),
//             lng: currentLocation.longitude.toString(),
//           ),
//         );
//         setState(() => isRouteStarted = false);
//       } else {
//         toastWidget("Please complete your routes first!", Colors.red);
//       }
//     }

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.grey,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           child: CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               // THEMED HEADER (same as HomeUpdated)
//               SliverToBoxAdapter(
//                 child: Stack(
//                   children: [
//                     Container(
//                       height: 160,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                       child: _GlassHeader(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   width: 40,
//                                   height: 40,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(.20),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white,
//                                       width: 1.2,
//                                     ),
//                                   ),
//                                   child: const Icon(
//                                     Icons.alt_route,
//                                     color: Colors.white,
//                                     size: 20,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Routes',
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.95),
//                                           fontWeight: FontWeight.w700,
//                                           height: 1.1,
//                                         ),
//                                       ),
//                                       Text(
//                                         isRouteStarted
//                                             ? 'Route in progress'
//                                             : 'Start your route',
//                                         overflow: TextOverflow.ellipsis,
//                                         style: t.headlineSmall?.copyWith(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.w800,
//                                           height: 1.05,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 // your logo slot (optional)
//                                 // Image.asset('assets/logo-bg.png', height: 50, width: 110),
//                               ],
//                             ),
//                             const SizedBox(height: 6),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 115,
//                       left: 20,
//                       child: _StatusPill(
//                         icon: Icons.access_time,
//                         label:
//                             '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // MAIN CONTENT
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // Summary cards (optional; themed)
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _MiniStatCard(
//                               title: 'Planned',
//                               value: '$jpCount',
//                               icon: Icons.alt_route,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _MiniStatCard(
//                               title: 'Done',
//                               value: '$reasonsCount',
//                               icon: Icons.check_circle_rounded,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 18),

//                       // Big Action Button
//                       SizedBox(
//                         height: 54,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: orange,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           onPressed: () async {
//                             if (!isRouteStarted) {
//                               await _startRoute(); // IN / 1
//                             } else {
//                               await _endRoute(); // OUT / 0 (if counts match)
//                             }
//                           },
//                           child: Text(
//                             isRouteStarted ? 'End Route' : 'Start your route',
//                             style: t.titleMedium?.copyWith(
//                               fontWeight: FontWeight.w800,
//                               color: Colors.white,
//                               letterSpacing: .2,
//                             ),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       // Info card (keeps theme vibe)
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: card,
//                           borderRadius: BorderRadius.circular(14),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: _shadow,
//                               blurRadius: 16,
//                               offset: Offset(0, 10),
//                             ),
//                           ],
//                           border: Border.all(
//                             color: const Color(0xFFFFB07A).withOpacity(.35),
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 46,
//                               height: 46,
//                               decoration: BoxDecoration(
//                                 color: field,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: const Icon(Icons.info_outline, color: orange),
//                             ),
//                             const SizedBox(width: 14),
//                             Expanded(
//                               child: Text(
//                                 isRouteStarted
//                                     ? 'Tap “End Route” after completing all planned visits.'
//                                     : 'Tap “Start your route” to begin and share your current location.',
//                                 style: t.bodyMedium?.copyWith(color: muted),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 28),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Mini stat cards to match theme
// class _MiniStatCard extends StatelessWidget {
//   const _MiniStatCard({required this.title, required this.value, required this.icon});
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
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: Color(0xFFF5F5F7),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child:  Icon(icon, color: Color(0xFFEA7A3B)),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: t.bodySmall?.copyWith(color: const Color(0xFF707883))),
//                   const SizedBox(height: 2),
//                   Text(value,
//                       style: t.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF1E1E1E),
//                         height: 1.0,
//                       )),
//                 ],
//               ),
//             ),
//           //  Icon(icon, color: const Color(0xFFEA7A3B)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ===== Reuse your helpers from HomeUpdated =====

// // Frosted glass header container
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

// // White pill showing status text (time/activity etc.)
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
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: Colors.white),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: t.bodySmall?.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w700,
//               letterSpacing: .3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



/*class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  String buttonText = "Break"; // unchanged (not used in the main button)
  String? selectedBreak;
  final loc.Location location = loc.Location();

  bool isRouteStarted = false; // NEW: only for UI toggle

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const Color orange = Color(0xFFEA7A3B);

    final global = context.read<GlobalBloc>().state;
    final login = global.loginModel!;
    final userId = login.userinfo!.userId.toString();

    final jpCount = login.journeyPlan.length;                  // compare as ints
    final reasonsCount = login.reasons.length;                 // compare as ints

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'Routes',
          style: t.titleLarge?.copyWith(
            color: const Color(0xFF1E1E1E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              children: [
                const Icon(Icons.person, size: 35, color: orange),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'ATTENDANCE-IN TIME',
                    style: t.titleSmall?.copyWith(
                      color: const Color(0xFF1E1E1E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 35, color: orange),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "${login.log!.tim} , ${login.log!.time}",
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: const Color(0xFF1E1E1E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.20,
            ),
            child: Center(
              // CHANGED: default message
              child: Text(
                isRouteStarted ? 'Route In Progress' : 'Start Your Route',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.80,
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
                    final currentLocation = await location.getLocation();

                    if (!isRouteStarted) {
                      // START: action IN, type '1'
                      context.read<GlobalBloc>().add(
                        StartRouteEvent(
                          action: 'IN',
                          type: '1',
                          userId: userId,
                          lat: currentLocation.latitude.toString(),
                          lng: currentLocation.longitude.toString(),
                        ),
                      );
                      setState(() => isRouteStarted = true);
                    } else {
                      // END: only if all routes done
                      if (jpCount == reasonsCount) {
                        context.read<GlobalBloc>().add(
                          StartRouteEvent(
                            action: 'OUT',
                            type: '0',
                            userId: userId,
                            lat: currentLocation.latitude.toString(),
                            lng: currentLocation.longitude.toString(),
                          ),
                        );
                        setState(() => isRouteStarted = false);
                      } else {
                        toastWidget(
                          "Please complete your routes first!",
                          Colors.red,
                        );
                      }
                    }
                  },
                  child: Text(
                    isRouteStarted ? 'End Route' : 'Start your route',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
*/

// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});
//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   final loc.Location location = loc.Location();
//   bool isRouteStarted = false; // default: not started → "Start your route"

//   Future<void> _startRoute() async {
//     final currentLocation = await location.getLocation();
//     final userId = context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString();

//     context.read<GlobalBloc>().add(
//       StartRouteEvent(
//         action: 'IN',
//         type: '1',
//         userId: userId,
//         lat: currentLocation.latitude.toString(),
//         lng: currentLocation.longitude.toString(),
//       ),
//     );

//     setState(() => isRouteStarted = true); // optional: flip UI to "Route in progress"
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     const orange = Color(0xFFEA7A3B);

//     return Scaffold(
//       body: Column(
//         children: [
//           // ...
//           Padding(
//             padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.20),
//             child: Center(
//               child: Text(
//                 isRouteStarted ? 'Route in progress' : 'Start your route',
//                 style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(26.0),
//         child: SizedBox(
//           width: MediaQuery.of(context).size.width * 0.80,
//           height: 50,
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: orange,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             ),
//             onPressed: () async {
//               if (!isRouteStarted) {
//                 await _startRoute(); // fires IN / type '1'
//               } else {
//                 // (optional) handle "End Route" here if you add that later
//               }
//             },
//             child: Text(
//               isRouteStarted ? 'End Route' : 'Start your route',
//               style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});

//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   String buttonText = "Break";
//   String? selectedBreak;
//   final loc.Location location = loc.Location();

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     const Color orange = Color(0xFFEA7A3B);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: false,
//         title: Text(
//           'Routes',
//           style: t.titleLarge?.copyWith(
//             color: Color(0xFF1E1E1E),
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),

//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//             child: Row(
//               children: [
//                 Icon(Icons.person, size: 35, color: orange),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     'ATTENDANCE-IN TIME',
//                     style: t.titleSmall?.copyWith(
//                       color: Color(0xFF1E1E1E),
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//             child: Row(
//               children: [
//                 Icon(Icons.access_time, size: 35, color: orange),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     "${context.read<GlobalBloc>().state.loginModel!.log!.tim.toString()} , ${context.read<GlobalBloc>().state.loginModel!.log!.time.toString()}",
//                     overflow: TextOverflow.ellipsis,
//                     style: t.titleSmall?.copyWith(
//                       color: Color(0xFF1E1E1E),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).size.height * 0.20,
//             ),
//             child: Center(child: Text('Route Started!')),
//           ),
//         ],
//       ),

//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(26.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 10),

//             Center(
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.80,
//                 height: 50,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: orange,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onPressed: () async {
//                     final currentLocation = await location.getLocation();

//                     if (context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .journeyPlan
//                             .length
//                             .toString() ==
//                         context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .reasons
//                             .length
//                             .toString()) {
//                       context.read<GlobalBloc>().add(
//                         StartRouteEvent(
//                           action: 'IN',
//                           type: '0',
//                           userId: context
//                               .read<GlobalBloc>()
//                               .state
//                               .loginModel!
//                               .userinfo!
//                               .userId
//                               .toString(),
//                           lat: currentLocation.latitude.toString(),
//                           lng: currentLocation.longitude.toString(),
//                         ),
//                       );
//                     } else {
//                       toastWidget(
//                         "Please complete your routes first!",
//                         Colors.red,
//                       );
//                     }
//                   },
//                   child: Text(
//                     'End Route',
//                     style: t.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             /*    SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   final currentLocation = await location.getLocation();

//                   if(context.read<GlobalBloc>().state.loginModel!.journeyPlan.length.toString() == context.read<GlobalBloc>().state.loginModel!.reasons!.length.toString()){

//                    context.read<GlobalBloc>().add(
//                       StartRouteEvent(
//                         type: '0',
//                         userId: context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .userinfo!
//                             .userId
//                             .toString(),
//                         lat: currentLocation.latitude.toString(),
//                         lng: currentLocation.longitude.toString(),
//                       ),
//                     );
//                   }
//                   else{
//                     toastWidget("Please visit all the shops of your PJP", Colors.red);
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//             'End Route',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),*/
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }
// }
