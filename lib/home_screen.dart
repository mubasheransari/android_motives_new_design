import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Constants/constants.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/journey_plan_screen.dart';
import 'package:motives_new_ui_conversion/mark_attendance.dart';
import 'package:motives_new_ui_conversion/peofile_screen.dart';
import 'package:motives_new_ui_conversion/routes_screen.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';
import 'dart:ui';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';
import 'main.dart';

class _LiveDateTimeBar extends StatefulWidget {
  const _LiveDateTimeBar();

  @override
  State<_LiveDateTimeBar> createState() => _LiveDateTimeBarState();
}

class _LiveDateTimeBarState extends State<_LiveDateTimeBar> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';
  String _time() =>
      '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

  String _date() {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${w[_now.weekday - 1]}, ${m[_now.month - 1]} ${_now.day}, ${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(
                color: HomeUpdated.cShadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Constants.themeColor, size: 38),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 31.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _time(),
                        textAlign: TextAlign.center,
                        style: t.titleLarge?.copyWith(
                          color: HomeUpdated.cText,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _date(),
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(
                          color: HomeUpdated.cMuted,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeUpdated extends StatefulWidget {
  const HomeUpdated({super.key});

  static const cBg = Color(0xFFEEEEEE);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);

  @override
  State<HomeUpdated> createState() => _HomeUpdatedState();
}

class _HomeUpdatedState extends State<HomeUpdated> {
  final box = GetStorage();
  int _coveredRoutesCount = 0;
      var routes ;

  @override
  void initState() {
    super.initState();
   routes= box.read("routeKey");
    _coveredRoutesCount = _asInt(box.read('covered_routes_count'));

    box.listenKey('covered_routes_count', (v) {
      if (!mounted) return;
      // Defer setState until after the current build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _coveredRoutesCount = _asInt(v));
      });
    });
    // _coveredRoutesCount = _asInt(box.read('covered_routes_count')); // seed

    // // ✅ auto-refresh when JourneyPlanScreen writes the new count
    // box.listenKey('covered_routes_count', (v) {
    //   if (!mounted) return;
    //   setState(() => _coveredRoutesCount = _asInt(v));
    // });
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  String _niceDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // var routes = box.read("routeKey");
    final t = Theme.of(context).textTheme;
    final state = context.read<GlobalBloc>().state;
    final model = state.loginModel;

    final userName =
        (model?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
        ? model!.userinfo!.userName.toString()
        : (model?.userinfo?.userName ?? 'User');

    final todayLabel = _niceDate(DateTime.now());
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

    // use it:
    final jpCount = dedupJourneyCount(
      context.read<GlobalBloc>().state.loginModel!.journeyPlan,
    );

    final routeCompleted = (jpCount == _coveredRoutesCount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: HomeUpdated.cBg,
        body: Stack(
          children: [
            const WatermarkTiledSmall(tileScale: 3.0),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Enter(
                        delayMs: 0,
                        child: Row(
                          children: const [Expanded(child: _LiveDateTimeBar())],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _Enter(
                        delayMs: 70,
                        child: _HeroGlass(
                          left: const _MiniBadge(),
                          titleBottom: userName,
                          right: Image.asset(
                            'assets/logo-bg.png',
                            height: 54,
                            width: 120,
                            color: const Color(0xfffc8020),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (state.loginModel?.statusAttendance.toString() == "1")
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Row(
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
                                value: '$_coveredRoutesCount',
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (routeCompleted)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Center(
                          child: Text(
                            'Route completed! You can end today’s route now',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: HomeUpdated.cPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Container(
                        margin: const EdgeInsets.all(1.8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.40),
                          borderRadius: BorderRadius.circular(14.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 10),
                            ),
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
                              child: Icon(
                                Icons.assignment_turned_in_rounded,
                                color: const Color(0xFFEA7A3B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Action Performed',
                                    style: t.bodySmall?.copyWith(
                                      color: const Color(0xFF707883),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${state.activity!.isEmpty ? "—" : state.activity}',
                                    style: t.titleMedium?.copyWith(
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

                      // _Enter(
                      //   delayMs: 120,
                      //   child: _StatusGlass(
                      //     text: 'Last Action · ${state.activity!.isEmpty ? "—" : state.activity}',
                      //   ),
                      // ),
                    ),
                  ),

                  const _SectionLabel(title: 'Quick Actions', delayMs: 220),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.04,
                          ),
                      delegate: SliverChildListDelegate.fixed([
                        _Enter(
                          delayMs: 260,
                          child: _GlassActionCard(
                            icon: Icons.access_time,
                            title: 'Mark / Review',
                            subtitle: 'Attendance', // 'Mark / Review',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MarkAttendanceView(),
                              ),
                            ),
                          ),
                        ),
                        _Enter(
                          delayMs: 300,
                          child: _GlassActionCard(
                            icon: Icons.alt_route,
                            title: 'Daily route plan', //'Routes',
                            subtitle: 'Routes', // 'Daily route plan',
                            onTap: () {
                              if (state.loginModel?.statusAttendance
                                      .toString() ==
                                  "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RouteScreen(),
                                  ),
                                );
                              } else {
                                toastWidget(
                                  'Mark your attendance first',
                                  Colors.red,
                                );
                              }
                            },
                          ),
                        ),
                        _Enter(
                          delayMs: 340,
                          child: _GlassActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Place new order', //'Punch Order',
                            subtitle: 'Punch Order', //'Place new order',
                            onTap: () {
                              if (state.loginModel?.statusAttendance
                                      .toString() ==
                                  "1") {
                                if (routes == null) {
                                  toastWidget(
                                    'Start your route first',
                                    Colors.red,
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JourneyPlanScreen(),
                                    ),
                                  );
                                }

                                //   Navigator.push(context, MaterialPageRoute(builder: (_) => JourneyPlanScreen()));
                              } else {
                                toastWidget(
                                  'Mark your attendance first',
                                  Colors.red,
                                );
                              }
                            },
                          ),
                        ),
                        _Enter(
                          delayMs: 380,
                          child: _GlassActionCard(
                            icon: Icons.insert_drive_file,
                            title: 'History & logs',
                            subtitle: 'Records',
                            onTap: () {},
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const _SectionLabel(title: 'More', delayMs: 420),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _Enter(
                        delayMs: 460,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WideGlassTile(
                                icon: Icons.person,
                                title: 'Profile',
                                caption: 'View profile',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WideGlassTile(
                                icon: Icons.upload,
                                title: 'Sync Out',
                                caption: 'Push updates',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: _Enter(
                        delayMs: 500,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WideGlassTile(
                                icon: Icons.download,
                                title: 'Sync In',
                                caption: 'Pull latest',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WideGlassTile(
                                icon: Icons.add_business_rounded,
                                title: 'Add Shops',
                                caption: 'Create outlet',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _HeroGlass extends StatelessWidget {
  const _HeroGlass({
    required this.left,
    required this.titleBottom,
    required this.right,
  });

  final Widget left;
  final String titleBottom;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(
                color: HomeUpdated.cShadow,
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        titleBottom,
                        overflow: TextOverflow.ellipsis,
                        style: t.headlineSmall?.copyWith(
                          color: HomeUpdated.cText,
                          fontWeight: FontWeight.w900,
                          height: 1.06,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              right,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: HomeUpdated.cStroke, width: 1),
        boxShadow: const [
          BoxShadow(
            color: HomeUpdated.cShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.person, color: Constants.themeColor, size: 26),
    );
  }
}

class _StatusGlass extends StatelessWidget {
  const _StatusGlass({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(
                color: HomeUpdated.cShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: Constants.themeColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    color: HomeUpdated.cText,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.delayMs = 0});
  final String title;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: _Enter(
          delayMs: delayMs,
          child: Row(
            children: [
              Text(
                title,
                style: t.titleMedium?.copyWith(
                  color: HomeUpdated.cText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x22000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassActionCard extends StatelessWidget {
  const _GlassActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;

  /// Shown like `_MiniStatCard.title` (small, muted)
  final String title;

  /// Shown like `_MiniStatCard.value` (big, bold)
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SizedBox(
      child: _Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.30),
            borderRadius: BorderRadius.circular(14.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            //  mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // small muted title
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: const Color(0xFF707883),
                      ),
                    ),
                    //  const SizedBox(height: 2),
                    // big bold subtitle (acts like the "value" in MiniStatCard)
                    // Text(
                    //   subtitle,
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: t.titleSmall?.copyWith(
                    //     fontWeight: FontWeight.w800,
                    //     color: const Color(0xFF1E1E1E),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class _GlassActionCard extends StatelessWidget {
  const _GlassActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withOpacity(.84),
              border: Border.all(color: HomeUpdated.cStroke),
              boxShadow: const [
                BoxShadow(
                  color: HomeUpdated.cShadow,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Orange aura
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: RadialGradient(
                        colors: [
                          HomeUpdated.cPrimary.withOpacity(.12),
                          Colors.transparent,
                        ],
                        radius: 1.1,
                        center: const Alignment(-1, -1),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: -24,
                  left: -20,
                  child: Transform.rotate(
                    angle: -.6,
                    child: Container(
                      width: 160,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(.38),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon tile (orange)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              HomeUpdated.cPrimary,
                              HomeUpdated.cPrimarySoft,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(.55),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: HomeUpdated.cShadow,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: t.titleMedium?.copyWith(
                          color: HomeUpdated.cText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                color: HomeUpdated.cMuted,
                              ),
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Container(
                          //   width: 28,
                          //   height: 28,
                          //   decoration: BoxDecoration(
                          //     gradient: const LinearGradient(
                          //       colors: [
                          //         HomeUpdated.cPrimary,
                          //         HomeUpdated.cPrimarySoft,
                          //       ],
                          //     ),
                          //     shape: BoxShape.circle,
                          //     border: Border.all(
                          //       color: Colors.white.withOpacity(.55),
                          //     ),
                          //   ),
                          //   child: const Icon(
                          //     Icons.chevron_right,
                          //     size: 18,
                          //     color: Colors.white,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
// class _WideGlassTile extends StatelessWidget {
//   const _WideGlassTile({
//     required this.icon,
//     required this.title,
//     required this.caption,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String title;
//   final String caption;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return _Pressable(
//       onTap: onTap,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//           child: Container(
//             height: 90,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               color: Colors.white.withOpacity(.84),
//               border: Border.all(color: HomeUpdated.cStroke),
//               boxShadow: const [
//                 BoxShadow(
//                   color: HomeUpdated.cShadow,
//                   blurRadius: 14,
//                   offset: Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       gradient: RadialGradient(
//                         colors: [
//                           HomeUpdated.cPrimarySoft.withOpacity(.30),
//                           Colors.transparent,
//                         ],
//                         radius: 1.3,
//                         center: const Alignment(.9, -.9),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 14),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           gradient: const LinearGradient(
//                             colors: [
//                               HomeUpdated.cPrimary,
//                               HomeUpdated.cPrimarySoft,
//                             ],
//                           ),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(.55),
//                           ),
//                         ),
//                         child: Icon(icon, color: Colors.white, size: 26),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               title,
//                               overflow: TextOverflow.ellipsis,
//                               style: t.titleSmall?.copyWith(
//                                 color: HomeUpdated.cText,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               caption,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: t.bodySmall?.copyWith(
//                                 color: HomeUpdated.cMuted,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _WideGlassTile extends StatelessWidget {
  const _WideGlassTile({
    required this.icon,
    required this.title, // small, muted
    required this.caption, // big, bold
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SizedBox(
      child: _Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.30),
            borderRadius: BorderRadius.circular(14.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
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
                child: SizedBox(
                  height: 60, // keeps vertical alignment tidy
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Small, muted (acts like "title" in your target design)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: const Color(0xFF707883),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _Enter extends StatefulWidget {
  const _Enter({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;
  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _ac,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, .1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), _ac.forward);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _offset, child: widget.child),
  );
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
    return Container(
      margin: const EdgeInsets.all(1.8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.40),
        borderRadius: BorderRadius.circular(14.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
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
                  style: t.bodySmall?.copyWith(color: const Color(0xFF707883)),
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
    );
  }
}
