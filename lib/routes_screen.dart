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
    final saved = storage.read("routeKey") ?? false;
    setState(() => isRouteStarted = saved);
  }

  Future<void> _setRouteStatus(bool value) async {
    await storage.write("routeKey", value);
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
    final saved =storage.read("routeKey");
 

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
                                      'Routes $saved',
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
