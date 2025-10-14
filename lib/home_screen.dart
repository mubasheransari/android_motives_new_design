import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Constants/constants.dart';
import 'package:motives_new_ui_conversion/journey_plan_screen.dart';
import 'package:motives_new_ui_conversion/mark_attendance.dart';
import 'package:motives_new_ui_conversion/peofile_screen.dart';
import 'package:motives_new_ui_conversion/routes_screen.dart';
import 'package:motives_new_ui_conversion/take_order.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';
import 'dart:ui';

import 'dart:async';
import 'dart:ui'; // ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';

import 'main.dart';

// import your own app files as needed:
// import 'package:your_app/bloc/global_bloc.dart';
// import 'package:your_app/mark_attendance_view.dart';
// import 'package:your_app/route_screen.dart';
// import 'package:your_app/journey_plan_screen.dart';
// import 'package:your_app/take_order_page.dart';
// import 'package:your_app/profile_screen.dart';
// import 'package:your_app/utils/toast_widget.dart';

/// ================== LIVE DATE/TIME BAR ==================
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
                      const SizedBox(height: 2), //
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

/// ================== HOME SCREEN ==================
class HomeUpdated extends StatefulWidget {
  const HomeUpdated({super.key});

  // Palette
  static const cBg = Color(0xFFEEEEEE); // changed to grey
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B); // Orange core
  static const cPrimarySoft = Color(0xFFFFB07A); // Soft orange
  static const cShadow = Color(0x14000000);

  @override
  State<HomeUpdated> createState() => _HomeUpdatedState();
}

class _HomeUpdatedState extends State<HomeUpdated> with RouteAware {
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

  late final GetStorage _box;
  int _coveredRoutes = 0;

  @override
  void initState() {
    super.initState();
    _box = GetStorage();
    _coveredRoutes = _coerceToInt(_box.read('covered_routes_count'));
  }

  int _coerceToInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // --- Listen for when user returns from another screen (like JourneyPlanScreen)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
      final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route); // ✅ types match
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when user returns to this screen
    _refreshCoveredRoutes();
  }

  void _refreshCoveredRoutes() {
    final newValue = _coerceToInt(_box.read('covered_routes_count'));
    if (mounted && newValue != _coveredRoutes) {
      setState(() => _coveredRoutes = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GlobalBloc>().state;
    final model = state.loginModel;

    final userName =
        (model?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
        ? model!.userinfo!.userName.toString()
        : (model?.userinfo?.userName ?? 'User');

    final todayLabel = _niceDate(DateTime.now());
    final jpCount = context
        .read<GlobalBloc>()
        .state
        .loginModel!
        .journeyPlan
        .length;
    // var box = GetStorage();
    // var totalCoveredRoutes = box.read('covered_routes_count');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: HomeUpdated.cBg,
        body: Stack(
          children: [
            // Watermark tiled across entire screen (unlimited)
            WatermarkTiledSmall(tileScale: 3.0),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ===== Top bar =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Enter(
                        delayMs: 0,
                        child: Row(
                          children: [Expanded(child: _LiveDateTimeBar())],
                        ),
                      ),
                    ),
                  ),

                  // ===== Hero =====
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
                            color: Color(0xfffc8020),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),

                  state.loginModel?.statusAttendance.toString() == "1"
                      ? SliverToBoxAdapter(
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
                                        value: _coveredRoutes
                                            .toString(), //context.read<GlobalBloc>().state.routesCovered.toString(),//'$done',
                                        icon: Icons.check_circle_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: _Enter(
                        delayMs: 120,
                        child: _StatusGlass(
                          text:
                              'Last Action · ${state.activity!.isEmpty ? "—" : state.activity}',
                        ),
                      ),
                    ),
                  ),

                  _SectionLabel(title: 'Quick Actions', delayMs: 220),

                  // ===== Actions grid (glass cards) =====
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
                            title: 'Attendance',
                            subtitle: 'Mark / Review',
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
                            title: 'Routes',
                            subtitle: 'Daily route plan',
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
                            title: 'Punch Order',
                            subtitle: 'Place new order',
                            onTap: () {
                              if (state.loginModel?.statusAttendance
                                      .toString() ==
                                  "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JourneyPlanScreen(),
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
                          delayMs: 380,
                          child: _GlassActionCard(
                            icon: Icons.insert_drive_file,
                            title: 'Records',
                            subtitle: 'History & logs',
                            onTap: () {},
                          ),
                        ),
                      ]),
                    ),
                  ),

                  _SectionLabel(title: 'More', delayMs: 420),

                  // ===== Wide tiles =====
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

/// ================== WATERMARK (TILED / UNLIMITED) ==================
///
/// ================== WATERMARK (TILED, SMALLER TILES) ==================
/// ================== WATERMARK (TILED + SMALL) ==================
// class _WatermarkTiledSmall extends StatelessWidget {
//   const _WatermarkTiledSmall({this.tileScale = 3.0});
//   // Bigger value => smaller tile (3.0 draws the image at 1/3 size)
//   final double tileScale;

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: Container(
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: const AssetImage('assets/logo-bg.png'),
//               repeat: ImageRepeat.repeat, // tile infinitely
//               fit: BoxFit.none, // no scaling by fit
//               // Make watermark subtle & dark-ish
//               colorFilter: ColorFilter.mode(
//                 Colors.black.withOpacity(0.06),
//                 BlendMode.srcIn,
//               ),
//               // ↓ This controls tile size. Higher = smaller tiles.
//               scale: tileScale,
//               alignment: Alignment.topLeft,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _WatermarkTiled extends StatelessWidget {
//   const _WatermarkTiled();
//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: Opacity(
//           opacity: 1.0, // overall watermark alpha
//           child: ColorFiltered(
//             colorFilter: ColorFilter.mode(
//               Colors.black.withOpacity(0.06), // watermark strength
//               BlendMode.srcIn,
//             ),
//             child: Image.asset(
//               'assets/logo-bg.png',
//               repeat: ImageRepeat.repeat, // tile infinitely
//               alignment: Alignment.topLeft,
//               fit: BoxFit.none, // no scaling; rely on repeat tiling
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

/// ================== HEADER WIDGETS ==================
class _IconGlass extends StatelessWidget {
  const _IconGlass({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.70),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(
                color: HomeUpdated.cShadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: HomeUpdated.cPrimary),
        ),
      ),
    );
  }
}

class _TopGlassBar extends StatelessWidget {
  const _TopGlassBar({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              const Icon(
                Icons.calendar_month_rounded,
                color: HomeUpdated.cPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(
                    color: HomeUpdated.cText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                caption,
                style: t.bodyMedium?.copyWith(
                  color: HomeUpdated.cMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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

/// ================== STATUS / STATS / SHORTCUTS ==================
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

class _ChipStatGlass extends StatelessWidget {
  const _ChipStatGlass({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(16),
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      HomeUpdated.cPrimary.withOpacity(.24),
                      HomeUpdated.cPrimarySoft.withOpacity(.34),
                    ],
                  ),
                  border: Border.all(color: HomeUpdated.cStroke),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.bodySmall?.copyWith(
                        color: HomeUpdated.cMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        color: HomeUpdated.cText,
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
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: HomeUpdated.cShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Quick',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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

/// ================== CARDS (Glassmorphism) ==================
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
                // Sheen strip
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
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  HomeUpdated.cPrimary,
                                  HomeUpdated.cPrimarySoft,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(.55),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
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

class _WideGlassTile extends StatelessWidget {
  const _WideGlassTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(.84),
              border: Border.all(color: HomeUpdated.cStroke),
              boxShadow: const [
                BoxShadow(
                  color: HomeUpdated.cShadow,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [
                          HomeUpdated.cPrimarySoft.withOpacity(.30),
                          Colors.transparent,
                        ],
                        radius: 1.3,
                        center: const Alignment(.9, -.9),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              HomeUpdated.cPrimary,
                              HomeUpdated.cPrimarySoft,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(.55),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleSmall?.copyWith(
                                color: HomeUpdated.cText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                color: HomeUpdated.cMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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

/// ================== EFFECTS / ANIMATIONS ==================
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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
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
                    style: t.bodySmall?.copyWith(
                      color: const Color(0xFF707883),
                    ),
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


/*class _LiveDateTimeBar extends StatefulWidget {
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

  String _time() => '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

  String _date() {
    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    // DateTime.weekday: 1=Mon ... 7=Sun
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
           // mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.access_time, color: HomeUpdated.cPrimary, size: 38),
            //  const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right:31.0),
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



class HomeUpdated extends StatelessWidget {
  const HomeUpdated({super.key});

  // Palette
  static const cBg = Color(0xFFFFFFFF);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B); // Orange core
  static const cPrimarySoft = Color(0xFFFFB07A); // Soft orange
  static const cShadow = Color(0x14000000);

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _niceDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GlobalBloc>().state;
    final model = state.loginModel;

    final userName = (model?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
        ? model!.userinfo!.userName.toString()
        : (model?.userinfo?.userName ?? 'User');

    final todayLabel = _niceDate(DateTime.now());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cBg,
        body: Stack(
          children: [
            // Animated orange gradient fog
            const _AnimatedOrangeFog(),

            // Subtle watermark (won't interfere with interactions)
            const _Watermark(),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ===== Top bar =====
              SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: _Enter(
      delayMs: 0,
      child: Row(
        children: [
      //    const _IconGlass(icon: Icons.menu_rounded),
         // const SizedBox(width: 12),

          // ⏱ Live time & date (center)
          const Expanded(child: _LiveDateTimeBar()),

       //   const SizedBox(width: 12),
        //  const _IconGlass(icon: Icons.notifications_outlined),
        ],
      ),
    ),
  ),
),


                  // ===== Hero =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _Enter(
                        delayMs: 70,
                        child: _HeroGlass(
                          left: const _MiniBadge(),
                        //  titleTop: 'Welcome back,',
                          titleBottom: userName,
                          right: Image.asset(
                            'assets/logo-bg.png',
                            height: 54,
                            width: 120,
                            color: Colors.orange,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ===== Status pill =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: _Enter(
                        delayMs: 120,
                        child: _StatusGlass(
                          text:
                              'Last Action · ${state.activity!.isEmpty ? "—" : state.activity}',
                        ),
                      ),
                    ),
                  ),

                  // ===== Quick stats =====
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  //     child: _Enter(
                  //       delayMs: 160,
                  //       child: Row(
                  //         children: [
                  //           Expanded(
                  //             child: _ChipStatGlass(
                  //               icon: Icons.how_to_reg,
                  //               label: 'Attendance',
                  //               value: state.loginModel?.statusAttendance == '1'
                  //                   ? 'Marked'
                  //                   : 'Pending',
                  //               accent: state.loginModel?.statusAttendance == '1'
                  //                   ? const Color(0xFF10B981)
                  //                   : const Color(0xFFEF4444),
                  //             ),
                  //           ),
                  //           const SizedBox(width: 12),
                  //           const Expanded(
                  //             child: _ChipStatGlass(
                  //               icon: Icons.alt_route,
                  //               label: 'Routes',
                  //               value: 'Today',
                  //               accent: Color(0xFF3B82F6),
                  //             ),
                  //           ),
                  //           const SizedBox(width: 12),
                  //           const Expanded(
                  //             child: _ChipStatGlass(
                  //               icon: Icons.receipt_long,
                  //               label: 'Orders',
                  //               value: 'New',
                  //               accent: Color(0xFFF59E0B),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // ===== Quick shortcuts =====
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  //     child: _Enter(
                  //       delayMs: 190,
                  //       child: Wrap(
                  //         spacing: 10,
                  //         runSpacing: 10,
                  //         children: const [
                  //           _ActionPill(text: 'Check-in'),
                  //           _ActionPill(text: 'Route Map'),
                  //           _ActionPill(text: 'New Order'),
                  //           _ActionPill(text: 'Reports'),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  _SectionLabel(title: 'Quick Actions', delayMs: 220),

                  // ===== Actions grid (glass cards) =====
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            title: 'Attendance',
                            subtitle: 'Mark / Review',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MarkAttendanceView()),
                            ),
                          ),
                        ),
                        _Enter(
                          delayMs: 300,
                          child: _GlassActionCard(
                            icon: Icons.alt_route,
                            title: 'Routes',
                            subtitle: 'Daily route plan',
                            onTap: () {
                              if (state.loginModel?.statusAttendance == "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RouteScreen()),
                                );
                              } else {
                                toastWidget('Mark your attendance first', Colors.red);
                              }
                            },
                          ),
                        ),
                        _Enter(
                          delayMs: 340,
                          child: _GlassActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Punch Order',
                            subtitle: 'Place new order',
                            onTap: () {
                              if (state.loginModel?.statusAttendance == "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => JourneyPlanScreen()),
                                );
                              } else {
                                toastWidget('Mark your attendance first', Colors.red);
                              }
                            },
                          ),
                        ),
                        _Enter(
                          delayMs: 380,
                          child: _GlassActionCard(
                            icon: Icons.insert_drive_file,
                            title: 'Records',
                            subtitle: 'History & logs',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TakeOrderPage()),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  _SectionLabel(title: 'More', delayMs: 420),

                  // ===== Wide tiles =====
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
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
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

/// ================== ANIMATED ORANGE FOG BACKGROUND ==================

class _AnimatedOrangeFog extends StatefulWidget {
  const _AnimatedOrangeFog();

  @override
  State<_AnimatedOrangeFog> createState() => _AnimatedOrangeFogState();
}

class _AnimatedOrangeFogState extends State<_AnimatedOrangeFog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _ac,
        builder: (context, _) {
          return CustomPaint(
            painter: _FogPainter(progress: _ac.value),
          );
        },
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final double progress;
  _FogPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Base light wash
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Orange blobs (soft)
    void blob(Offset center, double radius, List<Color> colors, double opacity) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors.map((c) => c.withOpacity(opacity)).toList(),
          stops: const [0.0, 0.7, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    final t = progress * 2 * math.pi;

    // Move 3 blobs in smooth orbits
    final c1 = Offset(size.width * (0.20 + 0.05 * math.sin(t * 0.9)),
        size.height * (0.22 + 0.06 * math.cos(t * 1.1)));
    final c2 = Offset(size.width * (0.80 + 0.04 * math.cos(t * 1.2)),
        size.height * (0.25 + 0.05 * math.sin(t * 0.8)));
    final c3 = Offset(size.width * (0.50 + 0.06 * math.sin(t * 0.7)),
        size.height * (0.85 + 0.04 * math.cos(t * 0.9)));

    blob(
      c1,
      size.shortestSide * 0.55,
      const [Color(0xFFFFEDD5), Color(0xFFFFB07A), Colors.transparent],
      0.70,
    );
    blob(
      c2,
      size.shortestSide * 0.50,
      const [Color(0xFFFFF0E0), Color(0xFFEA7A3B), Colors.transparent],
      0.55,
    );
    blob(
      c3,
      size.shortestSide * 0.60,
      const [Color(0xFFFFE6CC), Color(0xFFFFA35E), Colors.transparent],
      0.40,
    );
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ================== WATERMARK ==================

class _Watermark extends StatelessWidget {
  const _Watermark();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: 0.06,
            child: Transform.rotate(
              angle: -0.20,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/logo-bg.png',
                  width: MediaQuery.of(context).size.width * 0.78,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================== HEADER WIDGETS ==================

class _IconGlass extends StatelessWidget {
  const _IconGlass({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.70),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.menu_rounded, color: HomeUpdated.cPrimary),
        ),
      ),
    );
  }
}

class _TopGlassBar extends StatelessWidget {
  const _TopGlassBar({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: HomeUpdated.cPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(
                    color: HomeUpdated.cText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                caption,
                style: t.bodyMedium?.copyWith(
                  color: HomeUpdated.cMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroGlass extends StatelessWidget {
  const _HeroGlass({
    required this.left,
  //  required this.titleTop,
    required this.titleBottom,
    required this.right,
  });

  final Widget left;
//  final String titleTop;
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
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 22, offset: Offset(0, 12)),
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
                    // Text(
                    //   titleTop,
                    //   style: t.titleMedium?.copyWith(
                    //     color: HomeUpdated.cMuted,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top:12.0),
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
          BoxShadow(color: HomeUpdated.cShadow, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: const Icon(Icons.person, color: HomeUpdated.cPrimary, size: 22),
    );
  }
}

/// ================== STATUS / STATS / SHORTCUTS ==================

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
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in_rounded,
                  color: HomeUpdated.cPrimary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    color: HomeUpdated.cText,
                    fontWeight: FontWeight.w700,
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

class _ChipStatGlass extends StatelessWidget {
  const _ChipStatGlass({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(color: HomeUpdated.cShadow, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      HomeUpdated.cPrimary.withOpacity(.24),
                      HomeUpdated.cPrimarySoft.withOpacity(.34),
                    ],
                  ),
                  border: Border.all(color: HomeUpdated.cStroke),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: t.bodySmall?.copyWith(
                          color: HomeUpdated.cMuted,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          color: HomeUpdated.cText,
                          fontWeight: FontWeight.w800,
                        )),
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

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: HomeUpdated.cShadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Quick',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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

/// ================== CARDS (Glassmorphism with Orange Accents) ==================

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
                BoxShadow(color: HomeUpdated.cShadow, blurRadius: 18, offset: Offset(0, 10)),
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
                          Colors.transparent
                        ],
                        radius: 1.1,
                        center: const Alignment(-1, -1),
                      ),
                    ),
                  ),
                ),

                // Sheen strip
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
                            Colors.transparent
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
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white.withOpacity(.55)),
                          boxShadow: const [
                            BoxShadow(color: HomeUpdated.cShadow, blurRadius: 12, offset: Offset(0, 6)),
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
                              style: t.bodySmall?.copyWith(color: HomeUpdated.cMuted),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(.55)),
                            ),
                            child: const Icon(Icons.chevron_right, size: 18, color: Colors.white),
                          ),
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

class _WideGlassTile extends StatelessWidget {
  const _WideGlassTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(.84),
              border: Border.all(color: HomeUpdated.cStroke),
              boxShadow: const [
                BoxShadow(color: HomeUpdated.cShadow, blurRadius: 14, offset: Offset(0, 8)),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        colors: [
                          HomeUpdated.cPrimarySoft.withOpacity(.30),
                          Colors.transparent,
                        ],
                        radius: 1.3,
                        center: const Alignment(.9, -.9),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
                          ),
                          border: Border.all(color: Colors.white.withOpacity(.55)),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleSmall?.copyWith(
                                color: HomeUpdated.cText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                color: HomeUpdated.cMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    /*  const SizedBox(width: 3),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimarySoft],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(.55)),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // SizedBox(width: 6),
                            // Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),*/
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

/// ================== EFFECTS / ANIMATIONS ==================

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
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  late final Animation<Offset> _offset =
      Tween(begin: const Offset(0, .1), end: Offset.zero).animate(
    CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
  );

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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}*/



// class HomeUpdated extends StatelessWidget {
//   const HomeUpdated({super.key});

//   // Brand palette
//   static const cPrimary = Color(0xFFEA7A3B);
//   static const cPrimaryLight = Color(0xFFFFB07A);
//   static const cText = Color(0xFF101827);
//   static const cMuted = Color(0xFF6B7280);
//   static const cStroke = Color(0x33FFFFFF);
//   static const cShadow = Color(0x14000000);

//   String _greet() {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good morning';
//     if (h < 17) return 'Good afternoon';
//     return 'Good evening';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = context.read<GlobalBloc>().state;
//     final model = state.loginModel;

//     final userName = (model?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
//         ? model!.userinfo!.userName.toString()
//         : (model?.userinfo?.userName ?? 'User');

//     final todayLabel = _niceDate(DateTime.now());

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.light,
//       ),
//       child: Scaffold(
//         backgroundColor: const Color(0xFF0B0E13),
//         body: Stack(
//           children: [
//             // Layer 1: Animated gradient & floating fog blobs
//             const _GlassBackdrop(),

//             // Layer 2: Big grey logo watermark (non-interactive)
//             const _GlassWatermark(),

//             // Layer 3: Content
//             SafeArea(
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 slivers: [
//                   // ===== Top head row =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                       child: _Enter(
//                         delayMs: 0,
//                         child: Row(
//                           children: [
//                             const _IconGlass(icon: Icons.menu_rounded),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _TopGlassBar(
//                                 title: '${_greet()}, $userName',
//                                 caption: todayLabel,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const _IconGlass(icon: Icons.notifications_outlined),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ===== Hero Header =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//                       child: _Enter(
//                         delayMs: 80,
//                         child: _HeroGlass(
//                           left: const _MiniBadge(),
//                           titleTop: 'Welcome back,',
//                           titleBottom: userName,
//                           right: Image.asset(
//                             'assets/logo-bg.png',
//                             height: 52,
//                             width: 118,
//                             color: Colors.white.withOpacity(.95),
//                             colorBlendMode: BlendMode.srcIn,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ===== Status Chip =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//                       child: _Enter(
//                         delayMs: 140,
//                         child: _StatusGlass(
//                           text:
//                               'Last Action · ${state.activity!.isEmpty ? "—" : state.activity}',
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ===== Quick Stats =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//                       child: _Enter(
//                         delayMs: 180,
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _ChipStatGlass(
//                                 icon: Icons.how_to_reg,
//                                 label: 'Attendance',
//                                 value: state.loginModel?.statusAttendance == '1'
//                                     ? 'Marked'
//                                     : 'Pending',
//                                 color: state.loginModel?.statusAttendance == '1'
//                                     ? const Color(0xFF34D399)
//                                     : const Color(0xFFF87171),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const Expanded(
//                               child: _ChipStatGlass(
//                                 icon: Icons.alt_route,
//                                 label: 'Routes',
//                                 value: 'Today',
//                                 color: Color(0xFF60A5FA),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const Expanded(
//                               child: _ChipStatGlass(
//                                 icon: Icons.receipt_long,
//                                 label: 'Orders',
//                                 value: 'New',
//                                 color: Color(0xFFFBBF24),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ===== Shortcuts =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
//                       child: _Enter(
//                         delayMs: 220,
//                         child: Wrap(
//                           spacing: 10,
//                           runSpacing: 10,
//                           children: const [
//                             _ActionPill(text: 'Check-in'),
//                             _ActionPill(text: 'Route Map'),
//                             _ActionPill(text: 'New Order'),
//                             _ActionPill(text: 'Reports'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   _SectionLabel(title: 'Quick Actions', delayMs: 260),

//                   // ===== Glass Cards Grid =====
//                   SliverPadding(
//                     padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
//                     sliver: SliverGrid(
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 14,
//                         mainAxisSpacing: 14,
//                         childAspectRatio: 1.04,
//                       ),
//                       delegate: SliverChildListDelegate.fixed([
//                         _Enter(
//                           delayMs: 300,
//                           child: _GlassActionCard(
//                             icon: Icons.access_time,
//                             title: 'Attendance',
//                             subtitle: 'Mark / Review',
//                             onTap: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => MarkAttendanceView()),
//                             ),
//                           ),
//                         ),
//                         _Enter(
//                           delayMs: 340,
//                           child: _GlassActionCard(
//                             icon: Icons.alt_route,
//                             title: 'Routes',
//                             subtitle: 'Daily route plan',
//                             onTap: () {
//                               if (state.loginModel?.statusAttendance == "1") {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (_) => RouteScreen()),
//                                 );
//                               } else {
//                                 toastWidget('Mark your attendance first', Colors.red);
//                               }
//                             },
//                           ),
//                         ),
//                         _Enter(
//                           delayMs: 380,
//                           child: _GlassActionCard(
//                             icon: Icons.shopping_cart,
//                             title: 'Punch Order',
//                             subtitle: 'Place new order',
//                             onTap: () {
//                               if (state.loginModel?.statusAttendance == "1") {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (_) => JourneyPlanScreen()),
//                                 );
//                               } else {
//                                 toastWidget('Mark your attendance first', Colors.red);
//                               }
//                             },
//                           ),
//                         ),
//                         _Enter(
//                           delayMs: 420,
//                           child: _GlassActionCard(
//                             icon: Icons.insert_drive_file,
//                             title: 'Records',
//                             subtitle: 'History & logs',
//                             onTap: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => TakeOrderPage()),
//                             ),
//                           ),
//                         ),
//                       ]),
//                     ),
//                   ),

//                   _SectionLabel(title: 'More', delayMs: 460),

//                   // ===== Wide tiles A =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
//                       child: _Enter(
//                         delayMs: 500,
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _WideGlassTile(
//                                 icon: Icons.person,
//                                 title: 'Profile',
//                                 caption: 'View profile',
//                                 onTap: () => Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (_) => const ProfileScreen()),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _WideGlassTile(
//                                 icon: Icons.upload,
//                                 title: 'Sync Out',
//                                 caption: 'Push updates',
//                                 onTap: () {},
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ===== Wide tiles B =====
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//                       child: _Enter(
//                         delayMs: 540,
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _WideGlassTile(
//                                 icon: Icons.download,
//                                 title: 'Sync In',
//                                 caption: 'Pull latest',
//                                 onTap: () {},
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _WideGlassTile(
//                                 icon: Icons.add_business_rounded,
//                                 title: 'Add Shops',
//                                 caption: 'Create outlet',
//                                 onTap: () {},
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
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

//   String _niceDate(DateTime d) {
//     const months = [
//       'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
//     ];
//     return '${months[d.month - 1]} ${d.day}, ${d.year}';
//   }
// }

// /// ================== LAYERS (Backdrop + Watermark) ==================

// class _GlassBackdrop extends StatefulWidget {
//   const _GlassBackdrop();
//   @override
//   State<_GlassBackdrop> createState() => _GlassBackdropState();
// }

// class _GlassBackdropState extends State<_GlassBackdrop>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ac =
//       AnimationController(vsync: this, duration: const Duration(seconds: 12))
//         ..repeat(reverse: true);

//   @override
//   void dispose() {
//     _ac.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: AnimatedBuilder(
//         animation: _ac,
//         builder: (_, __) {
//           final t = _ac.value;
//           return Stack(
//             children: [
//               // Aurora-ish gradient
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment(-.6 + .6 * t, -1),
//                     end: Alignment(1, 1),
//                     colors: const [
//                       Color(0xFF0C0F14),
//                       Color(0xFF121623),
//                       Color(0xFF181C2D),
//                     ],
//                   ),
//                 ),
//               ),
//               // Soft color bloom
//               _FogBlob(
//                 size: 320,
//                 dx: -0.35 + 0.10 * math.sin(t * math.pi * 2),
//                 dy: -0.85 + 0.08 * math.cos(t * math.pi * 2),
//                 color: const Color(0xFFEA7A3B).withOpacity(.26),
//               ),
//               _FogBlob(
//                 size: 260,
//                 dx: 0.6 + 0.08 * math.sin(t * math.pi * 2 + 1.1),
//                 dy: -0.6 + 0.06 * math.cos(t * math.pi * 2 + 1.4),
//                 color: const Color(0xFFFFB07A).withOpacity(.22),
//               ),
//               _FogBlob(
//                 size: 360,
//                 dx: 0.0 + 0.07 * math.sin(t * math.pi * 2 + 2.2),
//                 dy: -0.35 + 0.06 * math.cos(t * math.pi * 2 + 2.4),
//                 color: const Color(0xFF60A5FA).withOpacity(.12),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _FogBlob extends StatelessWidget {
//   const _FogBlob({
//     required this.size,
//     required this.dx,
//     required this.dy,
//     required this.color,
//   });

//   final double size;
//   final double dx;
//   final double dy;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
//     final h = MediaQuery.of(context).size.height;
//     return Positioned(
//       left: (dx + 1) * 0.5 * w - size / 2,
//       top: (dy + 1) * 0.5 * h - size / 2,
//       child: IgnorePointer(
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color,
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(.6),
//                 blurRadius: 60,
//                 spreadRadius: 16,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _GlassWatermark extends StatelessWidget {
//   const _GlassWatermark();
//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: Center(
//           child: Opacity(
//             opacity: 0.06,
//             child: Transform.rotate(
//               angle: -0.2,
//               child: ColorFiltered(
//                 colorFilter: const ColorFilter.mode(
//                   Colors.white70,
//                   BlendMode.srcIn,
//                 ),
//                 child: Image.asset(
//                   'assets/logo-bg.png',
//                   width: MediaQuery.of(context).size.width * 0.8,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// ================== HEADER WIDGETS ==================

// class _IconGlass extends StatelessWidget {
//   const _IconGlass({required this.icon});
//   final IconData icon;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//         child: Container(
//           height: 44,
//           width: 44,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.10),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.white.withOpacity(.25)),
//           ),
//           child: Icon(icon, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

// class _TopGlassBar extends StatelessWidget {
//   const _TopGlassBar({required this.title, required this.caption});
//   final String title;
//   final String caption;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.10),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.white.withOpacity(.25)),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   overflow: TextOverflow.ellipsis,
//                   style: t.titleMedium?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: .2,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 caption,
//                 style: t.bodyMedium?.copyWith(
//                   color: Colors.white.withOpacity(.92),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _HeroGlass extends StatelessWidget {
//   const _HeroGlass({
//     required this.left,
//     required this.titleTop,
//     required this.titleBottom,
//     required this.right,
//   });

//   final Widget left;
//   final String titleTop;
//   final String titleBottom;
//   final Widget right;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(22),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.10),
//             borderRadius: BorderRadius.circular(22),
//             border: Border.all(
//               color: Colors.white.withOpacity(.28),
//               width: 1,
//             ),
//             boxShadow: const [
//               BoxShadow(
//                 color: HomeUpdated.cShadow,
//                 blurRadius: 22,
//                 offset: Offset(0, 12),
//               ),
//             ],
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               left,
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       titleTop,
//                       style: t.titleMedium?.copyWith(
//                         color: Colors.white.withOpacity(.95),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       titleBottom,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.headlineSmall?.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         height: 1.06,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               right,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MiniBadge extends StatelessWidget {
//   const _MiniBadge();
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 46,
//       height: 46,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.12),
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white.withOpacity(.50), width: 1.3),
//       ),
//       child: const Icon(Icons.person, color: Colors.white, size: 22),
//     );
//   }
// }

// /// ================== STATUS / STATS / SHORTCUTS ==================

// class _StatusGlass extends StatelessWidget {
//   const _StatusGlass({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.10),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.white.withOpacity(.22)),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
//               const SizedBox(width: 8),
//               Flexible(
//                 child: Text(
//                   text,
//                   overflow: TextOverflow.ellipsis,
//                   style: t.bodyMedium?.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: .2,
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

// class _ChipStatGlass extends StatelessWidget {
//   const _ChipStatGlass({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.color,
//   });

//   final IconData icon;
//   final String label;
//   final String value;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           height: 70,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.10),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.white.withOpacity(.22)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14),
//                   gradient: LinearGradient(
//                     colors: [
//                       color.withOpacity(.22),
//                       color.withOpacity(.10),
//                     ],
//                   ),
//                   border: Border.all(color: Colors.white.withOpacity(.18)),
//                 ),
//                 child: Icon(icon, color: Colors.white),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(label,
//                         style: t.bodySmall?.copyWith(
//                           color: Colors.white70,
//                           fontWeight: FontWeight.w600,
//                         )),
//                     const SizedBox(height: 2),
//                     Text(value,
//                         overflow: TextOverflow.ellipsis,
//                         style: t.titleSmall?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w800,
//                         )),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ActionPill extends StatelessWidget {
//   const _ActionPill({required this.text});
//   final String text;
//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
//         ),
//         borderRadius: BorderRadius.circular(999),
//         boxShadow: const [
//           BoxShadow(
//             color: HomeUpdated.cShadow,
//             blurRadius: 18,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.bolt, color: Colors.white, size: 16),
//             SizedBox(width: 6),
//             _WhiteText(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _WhiteText extends StatelessWidget {
//   const _WhiteText();
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       // The label is supplied by parent via DefaultTextStyle override
//       // but we want consistent look—so we ignore and style directly in parent call
//       // Kept as a mini component to avoid analyzer warning.
//       ' ',
//       style: const TextStyle(color: Colors.white),
//     );
//   }
// }

// /// Section label
// class _SectionLabel extends StatelessWidget {
//   const _SectionLabel({required this.title, this.delayMs = 0});
//   final String title;
//   final int delayMs;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return SliverToBoxAdapter(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
//         child: _Enter(
//           delayMs: delayMs,
//           child: Row(
//             children: [
//               Text(
//                 title,
//                 style: t.titleMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Container(
//                   height: 1,
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0x22FFFFFF), Color(0x00000000)],
//                     ),
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

// /// ================== GLASS CARDS ==================

// class _GlassActionCard extends StatelessWidget {
//   const _GlassActionCard({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return _Pressable(
//       onTap: onTap,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(22),
//               color: Colors.white.withOpacity(.08),
//               border: Border.all(color: Colors.white.withOpacity(.24)),
//               boxShadow: const [
//                 BoxShadow(
//                   color: HomeUpdated.cShadow,
//                   blurRadius: 22,
//                   offset: Offset(0, 12),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Neon gradient border aura (inner glow)
//                 Positioned.fill(
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(22),
//                       gradient: RadialGradient(
//                         colors: [
//                           HomeUpdated.cPrimary.withOpacity(.10),
//                           Colors.transparent
//                         ],
//                         radius: 1.2,
//                         center: const Alignment(-1, -1),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Sheen strip
//                 Positioned(
//                   top: -24,
//                   left: -20,
//                   child: Transform.rotate(
//                     angle: -.6,
//                     child: Container(
//                       width: 160,
//                       height: 64,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.white.withOpacity(.25),
//                             Colors.transparent
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Card content
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Glass icon tile
//                       Container(
//                         width: 58,
//                         height: 58,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           color: Colors.white.withOpacity(.10),
//                           border: Border.all(color: Colors.white.withOpacity(.22)),
//                         ),
//                         child: Icon(icon, color: Colors.white, size: 28),
//                       ),
//                       const Spacer(),
//                       Text(
//                         title,
//                         style: t.titleMedium?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: .2,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               subtitle,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: t.bodySmall?.copyWith(color: Colors.white70),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             width: 28,
//                             height: 28,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(.10),
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white.withOpacity(.24)),
//                             ),
//                             child: const Icon(Icons.chevron_right,
//                                 size: 18, color: Colors.white70),
//                           ),
//                         ],
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
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Container(
//             height: 90,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               color: Colors.white.withOpacity(.08),
//               border: Border.all(color: Colors.white.withOpacity(.22)),
//             ),
//             child: Stack(
//               children: [
//                 // Glow edge
//                 Positioned.fill(
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       gradient: RadialGradient(
//                         colors: [
//                           HomeUpdated.cPrimaryLight.withOpacity(.12),
//                           Colors.transparent
//                         ],
//                         radius: 1.2,
//                         center: const Alignment(.9, -.9),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Content
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 14),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           color: Colors.white.withOpacity(.10),
//                           border: Border.all(color: Colors.white.withOpacity(.22)),
//                         ),
//                         child: Icon(icon, color: Colors.white, size: 26),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               title,
//                               overflow: TextOverflow.ellipsis,
//                               style: t.titleSmall?.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               caption,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: t.bodySmall?.copyWith(
//                                 color: Colors.white70,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         height: 34,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(.10),
//                           borderRadius: BorderRadius.circular(999),
//                           border: Border.all(color: Colors.white.withOpacity(.22)),
//                         ),
//                         child: const Row(
//                           children: [
//                             Text(
//                               'Open',
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                             SizedBox(width: 6),
//                             Icon(Icons.chevron_right, color: Colors.white70),
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

// /// ================== EFFECTS / ANIMATIONS ==================

// class _Pressable extends StatefulWidget {
//   const _Pressable({required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_Pressable> createState() => _PressableState();
// }

// class _PressableState extends State<_Pressable>
//     with SingleTickerProviderStateMixin {
//   double _scale = 1.0;
//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapUp: _up,
//       onTapCancel: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(
//         scale: _scale,
//         duration: const Duration(milliseconds: 100),
//         child: widget.child,
//       ),
//     );
//   }
// }

// class _Enter extends StatefulWidget {
//   const _Enter({required this.child, this.delayMs = 0});
//   final Widget child;
//   final int delayMs;

//   @override
//   State<_Enter> createState() => _EnterState();
// }

// class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
//   late final AnimationController _ac =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
//   late final Animation<double> _opacity =
//       CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
//   late final Animation<Offset> _offset =
//       Tween(begin: const Offset(0, .1), end: Offset.zero).animate(
//     CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
//   );

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration(milliseconds: widget.delayMs), _ac.forward);
//   }

//   @override
//   void dispose() {
//     _ac.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _opacity,
//       child: SlideTransition(position: _offset, child: widget.child),
//     );
//   }
// }


/*
class HomeUpdated extends StatelessWidget {
  const HomeUpdated({super.key});

  // Brand palette
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimaryLight = Color(0xFFFFB07A);
  static const cCard = Colors.white;
  static const cText = Color(0xFF111827);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE5E7EB);
  static const cField = Color(0xFFF6F7FB);
  static const cShadow = Color(0x14000000);

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GlobalBloc>().state;
    final model = state.loginModel;

    final userName = (model?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
        ? model!.userinfo!.userName.toString()
        : (model?.userinfo?.userName ?? 'User');

    final todayLabel = _niceDate(DateTime.now());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            const _AnimatedBackdrop(),

            const _Watermark(),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ===== Top App Row (Greeting + Date + Bell) =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _Entrance(
                        delayMs: 0,
                        child: Row(
                          children: [
                            _GlassIconButton(
                              icon: Icons.menu_rounded,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _GlassHeaderBar(
                                greet: '${_greet()}, $userName',
                                date: todayLabel,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _GlassIconButton(
                              icon: Icons.notifications_outlined,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===== Hero header =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _Entrance(
                        delayMs: 80,
                        child: _GlassHeroHeader(
                          left: _MiniAvatar(),
                          centerTop: Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(.95),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          centerBottom: Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                          ),
                          right: Image.asset(
                            'assets/logo-bg.png',
                            height: 54,
                            width: 120,
                            colorBlendMode: BlendMode.srcIn,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ===== Status chip =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: _Entrance(
                        delayMs: 140,
                        child: _StatusBar(
                          text:
                              'Last Action · ${state.activity!.isEmpty ? "—" : state.activity}',
                        ),
                      ),
                    ),
                  ),

                  // ===== Quick Stats (mini glass chips) =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _Entrance(
                        delayMs: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: _GlassStat(
                                icon: Icons.how_to_reg,
                                label: 'Attendance',
                                value: state.loginModel?.statusAttendance == '1'
                                    ? 'Marked'
                                    : 'Pending',
                                color: state.loginModel?.statusAttendance == '1'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: _GlassStat(
                                icon: Icons.alt_route,
                                label: 'Routes',
                                value: 'Today',
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: _GlassStat(
                                icon: Icons.receipt_long,
                                label: 'Orders',
                                value: 'New',
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===== Action Chips row =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: _Entrance(
                        delayMs: 220,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _ActionChipGrad(text: 'Check-in'),
                            _ActionChipGrad(text: 'Route Map'),
                            _ActionChipGrad(text: 'New Order'),
                            _ActionChipGrad(text: 'Reports'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===== Section title =====
                  _SectionHeader(title: 'Quick Actions', delayMs: 260),

                  // ===== Grid actions =====
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.05,
                      ),
                      delegate: SliverChildListDelegate.fixed([
                        _Entrance(
                          delayMs: 300,
                          child: _NeoActionCard(
                            icon: Icons.access_time,
                            title: 'Attendance',
                            subtitle: 'Mark / Review',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MarkAttendanceView()),
                            ),
                          ),
                        ),
                        _Entrance(
                          delayMs: 340,
                          child: _NeoActionCard(
                            icon: Icons.alt_route,
                            title: 'Routes',
                            subtitle: 'Daily route plan',
                            onTap: () {
                              if (state.loginModel?.statusAttendance == "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RouteScreen()),
                                );
                              } else {
                                toastWidget('Mark your attendance first', Colors.red);
                              }
                            },
                          ),
                        ),
                        _Entrance(
                          delayMs: 380,
                          child: _NeoActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Punch Order',
                            subtitle: 'Place new order',
                            onTap: () {
                              if (state.loginModel?.statusAttendance == "1") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => JourneyPlanScreen()),
                                );
                              } else {
                                toastWidget('Mark your attendance first', Colors.red);
                              }
                            },
                          ),
                        ),
                        _Entrance(
                          delayMs: 420,
                          child: _NeoActionCard(
                            icon: Icons.insert_drive_file,
                            title: 'Records',
                            subtitle: 'History & logs',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TakeOrderPage()),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  _SectionHeader(title: 'More', delayMs: 460),

                  // ===== Wide tiles row A =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                      child: _Entrance(
                        delayMs: 500,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WideNeoTile(
                                icon: Icons.person,
                                title: 'Profile',
                                caption: 'View profile',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WideNeoTile(
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

                  // ===== Wide tiles row B =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                      child: _Entrance(
                        delayMs: 540,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WideNeoTile(
                                icon: Icons.download,
                                title: 'Sync In',
                                caption: 'Pull latest',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WideNeoTile(
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

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _niceDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// =================== LAYERS ===================

/// Animated gradient + floating translucent blobs (no packages)
class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) {
          final t = _ac.value;
          return Stack(
            children: [
              // Sky gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.9 + 0.6 * t, -1),
                    end: Alignment(1, 1),
                    colors: const [
                      Color(0xFFFEA161),
                      Color(0xFFFFC48A),
                      Color(0xFFFFE4C7),
                    ],
                  ),
                ),
              ),
              // Soft blur to unify tones
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const SizedBox(),
                ),
              ),
              // Floating blobs
              _Blob(
                color: Colors.white.withOpacity(.23),
                size: 220,
                dx: -0.35 + 0.08 * math.sin(t * math.pi * 2),
                dy: -0.75 + 0.05 * math.cos(t * math.pi * 2),
              ),
              _Blob(
                color: Colors.white.withOpacity(.17),
                size: 180,
                dx: 0.55 + 0.06 * math.sin(t * math.pi * 2 + 1),
                dy: -0.6 + 0.04 * math.cos(t * math.pi * 2 + 1.2),
              ),
              _Blob(
                color: Colors.white.withOpacity(.16),
                size: 260,
                dx: 0.0 + 0.07 * math.sin(t * math.pi * 2 + 2.1),
                dy: -0.3 + 0.05 * math.cos(t * math.pi * 2 + 2.6),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.dx, // -1..1 viewport fraction
    required this.dy,
  });

  final Color color;
  final double size;
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Positioned(
      left: (dx + 1) * 0.5 * w - size / 2,
      top: (dy + 1) * 0.5 * h - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FFFFFF),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey watermark (safe and subtle)
class _Watermark extends StatelessWidget {
  const _Watermark();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Center(
          child: Opacity(
            opacity: 0.05,
            child: Transform.rotate(
              angle: -0.18,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/logo-bg.png',
                  width: MediaQuery.of(context).size.width * 0.82,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =============== Top bits ===============

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withOpacity(.18),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassHeaderBar extends StatelessWidget {
  const _GlassHeaderBar({required this.greet, required this.date});
  final String greet;
  final String date;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  greet,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                date,
                style: t.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted hero header card
class _GlassHeroHeader extends StatelessWidget {
  const _GlassHeroHeader({
    required this.left,
    required this.centerTop,
    required this.centerBottom,
    required this.right,
  });

  final Widget left;
  final Widget centerTop;
  final Widget centerBottom;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.58), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 10),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [centerTop, const SizedBox(height: 2), centerBottom],
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

class _MiniAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.20),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }
}

/// Status pill (white card)
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeUpdated.cStroke),
        boxShadow: const [
          BoxShadow(
            color: HomeUpdated.cShadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_turned_in_rounded,
              color: HomeUpdated.cPrimary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(
                color: HomeUpdated.cText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini glass stat chip
class _GlassStat extends StatelessWidget {
  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeUpdated.cStroke),
            boxShadow: const [
              BoxShadow(
                color: HomeUpdated.cShadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeUpdated.cStroke),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: t.bodySmall?.copyWith(
                          color: HomeUpdated.cMuted,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          color: HomeUpdated.cText,
                          fontWeight: FontWeight.w800,
                        )),
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

/// Gradient action chip
class _ActionChipGrad extends StatelessWidget {
  const _ActionChipGrad({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: HomeUpdated.cShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.delayMs = 0});
  final String title;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _Entrance(
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
                      colors: [Color(0x22FFFFFF), Color(0x22000000)],
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

/// =============== Cards ===============

/// Neumorphic + Glass action card with gradient border
class _NeoActionCard extends StatelessWidget {
  const _NeoActionCard({
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Glass / soft background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.86),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: HomeUpdated.cStroke),
                  ),
                  padding: const EdgeInsets.all(14),
                ),

                // Diagonal sheen
                Positioned(
                  top: -30,
                  left: -30,
                  child: Transform.rotate(
                    angle: -0.6,
                    child: Container(
                      width: 160,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(.22),
                            Colors.white.withOpacity(0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                // Corner accent ribbon
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.flash_on, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Quick',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                // Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge (glassy)
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9FAFB), Color(0xFFEFF3F8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: HomeUpdated.cStroke),
                          ),
                          child: Icon(icon, color: HomeUpdated.cPrimary, size: 26),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(color: HomeUpdated.cMuted),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                                border: Border.all(color: HomeUpdated.cStroke),
                              ),
                              child: const Icon(Icons.chevron_right,
                                  size: 18, color: HomeUpdated.cMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
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

/// Wide tile with gradient border, glass body and trailing arrow
class _WideNeoTile extends StatelessWidget {
  const _WideNeoTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return _Pressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          height: 86,
          margin: const EdgeInsets.all(2.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Glass body
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.88),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: HomeUpdated.cStroke),
                  ),
                ),

                // Soft sheen
                Positioned(
                  top: -28,
                  right: -20,
                  child: Transform.rotate(
                    angle: 0.55,
                    child: Container(
                      width: 160,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(.20),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        // Leading icon in rounded glass
                        Container(
                          width: 46,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9FAFB), Color(0xFFEFF3F8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: HomeUpdated.cStroke),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: HomeUpdated.cPrimary, size: 26),
                        ),
                        const SizedBox(width: 14),

                        // Texts
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleSmall?.copyWith(
                                  color: HomeUpdated.cText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(
                                  color: HomeUpdated.cMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing arrow chip
                        const SizedBox(width: 8),
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: HomeUpdated.cStroke),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Open',
                                style: TextStyle(
                                  color: HomeUpdated.cMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.chevron_right, color: HomeUpdated.cMuted),
                            ],
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
      ),
    );
  }
}

/// Tap feedback
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

/// Smooth entrance animation
class _Entrance extends StatefulWidget {
  const _Entrance({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  late final Animation<Offset> _offset =
      Tween(begin: const Offset(0, .1), end: Offset.zero).animate(
    CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
  );

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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
*/

// class HomeUpdated extends StatelessWidget {
//   const HomeUpdated({super.key});

//   static const Color orange = Color(0xFFEA7A3B);
//   static const Color text = Color(0xFF1E1E1E);
//   static const Color muted = Color(0xFF707883);
//   static const Color field = Color(0xFFF5F5F7);
//   static const Color card = Colors.white;
//   static const Color accent = Color(0xFFE97C42);
//   static const Color _shadow = Color(0x14000000);

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final loginModel = context.read<GlobalBloc>().state.loginModel;

//     final userName =
//         loginModel?.userinfo?.userName?.toString().trim().isNotEmpty == true
//             ? loginModel!.userinfo!.userName.toString()
//             : (loginModel?.userinfo?.userName ?? 'User');

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.grey,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Stack(
//           children: [
//             // ===== WATERMARK (behind everything, non-interactive) =====
//             const _MotivesWatermark(),

//             // ===== MAIN CONTENT (unchanged UI) =====
//             SafeArea(
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 slivers: [
//                   SliverToBoxAdapter(
//                     child: Stack(
//                       children: [
//                         Container(
//                           height: 160,
//                           decoration: const BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                           child: _GlassHeader(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Container(
//                                       width: 40,
//                                       height: 40,
//                                       decoration: BoxDecoration(
//                                         color: Colors.white.withOpacity(.20),
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                           color: Colors.white,
//                                           width: 1.2,
//                                         ),
//                                       ),
//                                       child: const Icon(
//                                         Icons.person,
//                                         color: Colors.white,
//                                         size: 20,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 14),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             'Welcome back,',
//                                             style: t.titleMedium?.copyWith(
//                                               color:
//                                                   Colors.white.withOpacity(.95),
//                                               fontWeight: FontWeight.w600,
//                                               height: 1.1,
//                                             ),
//                                           ),
//                                           Text(
//                                             userName,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: t.headlineSmall?.copyWith(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.w800,
//                                               height: 1.05,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     Image.asset(
//                                       'assets/logo-bg.png',
//                                       height: 50,
//                                       width: 110,
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 5),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           top: 115,
//                           left: 20,
//                           child: _StatusPill(
//                             icon: Icons.assignment_turned_in_rounded,
//                             label:
//                                 'Last Action Performed : ${context.read<GlobalBloc>().state.activity}',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   SliverPadding(
//                     padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
//                     sliver: SliverGrid(
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 14,
//                         mainAxisSpacing: 14,
//                         childAspectRatio: 1.10,
//                       ),
//                       delegate: SliverChildListDelegate.fixed([
//                         _TapScale(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => MarkAttendanceView(),
//                               ),
//                             );
//                           },
//                           child: const _CategoryCard(
//                             icon: Icons.access_time,
//                             title: 'Attendance',
//                             subtitle: 'Mark / Review',
//                           ),
//                         ),
//                         _TapScale(
//                           onTap: () {
//                             if (context
//                                     .read<GlobalBloc>()
//                                     .state
//                                     .loginModel!
//                                     .statusAttendance ==
//                                 "1") {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => RouteScreen(),
//                                 ),
//                               );
//                             } else {
//                               toastWidget(
//                                   'Mark your attendence first', Colors.red);
//                             }
//                           },
//                           child: const _CategoryCard(
//                             icon: Icons.alt_route,
//                             title: 'Routes',
//                             subtitle: 'Daily route plan',
//                           ),
//                         ),
//                         _TapScale(
//                           onTap: () {
//                             if (context
//                                     .read<GlobalBloc>()
//                                     .state
//                                     .loginModel!
//                                     .statusAttendance ==
//                                 "1") {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => JourneyPlanScreen(),
//                                 ),
//                               );
//                             } else {
//                               toastWidget(
//                                   'Mark your attendence first', Colors.red);
//                             }
//                           },
//                           child: const _CategoryCard(
//                             icon: Icons.shopping_cart,
//                             title: 'Punch Order',
//                             subtitle: 'Place new order',
//                           ),
//                         ),
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => TakeOrderPage(),
//                               ),
//                             );
//                           },
//                           child: const _CategoryCard(
//                             icon: Icons.insert_drive_file,
//                             title: 'Records',
//                             subtitle: 'History & logs',
//                           ),
//                         ),
//                       ]),
//                     ),
//                   ),

//                   SliverToBoxAdapter(
//                     child: SizedBox(
//                       height: 118,
//                       child: _CenteredHScroll(
//                         paddingLR: 18,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _TapScale(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         const ProfileScreen(),
//                                   ),
//                                 );
//                               },
//                               child: const _FeatureCard(
//                                 title: 'Profile',
//                                 icon: Icons.person,
//                                 caption: 'View profile',
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const _FeatureCard(
//                               title: 'Sync Out',
//                               icon: Icons.upload,
//                               caption: 'Push updates',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   SliverToBoxAdapter(
//                     child: SizedBox(
//                       height: 80,
//                       child: _CenteredHScroll(
//                         paddingLR: 12,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: const [
//                             _FeatureCard(
//                               title: 'Sync In',
//                               icon: Icons.download,
//                               caption: 'Pull latest',
//                             ),
//                             SizedBox(width: 12),
//                             _FeatureCard(
//                               title: 'Add Shops',
//                               icon: Icons.add_business_rounded,
//                               caption: 'Create outlet',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SliverToBoxAdapter(child: SizedBox(height: 16)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// ===== WATERMARK WIDGET (safe placement) =====
// class _MotivesWatermark extends StatelessWidget {
//   const _MotivesWatermark();

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill( // must be direct child of the Stack in Scaffold body
//       child: IgnorePointer(
//         ignoring: true, // never intercept gestures
//         child: Center(
//           child: Opacity(
//             opacity: 0.06, // subtle grey
//             child: Transform.rotate(
//               angle: -0.18,
//               child: ColorFiltered(
//                 colorFilter: const ColorFilter.mode(
//                   Colors.black54, // grey-tint the watermark
//                   BlendMode.srcIn,
//                 ),
//                 child: Image.asset(
//                   'assets/logo-bg.png',
//                   width: MediaQuery.of(context).size.width * 0.85,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// ===== Existing widgets below (unchanged UI) =====

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
//           const Icon(
//             Icons.assignment_turned_in_rounded,
//             size: 16,
//             color: Colors.white,
//           ),
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

// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title, this.subtitle});

//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: HomeUpdated.card,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [
//             BoxShadow(
//               color: HomeUpdated._shadow,
//               blurRadius: 16,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Material(
//               color: HomeUpdated.field,
//               shape: const CircleBorder(),
//               child: SizedBox(
//                 width: 46,
//                 height: 46,
//                 child: Icon(icon, color: HomeUpdated.orange),
//               ),
//             ),
//             const Spacer(),
//             Text(
//               title,
//               style: t.titleMedium?.copyWith(
//                 color: HomeUpdated.text,
//                 fontWeight: FontWeight.w800,
//                 letterSpacing: .2,
//               ),
//             ),
//             if (subtitle != null) ...[
//               const SizedBox(height: 2),
//               Text(
//                 subtitle!,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: t.bodySmall?.copyWith(color: HomeUpdated.muted),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _FeatureCard extends StatelessWidget {
//   const _FeatureCard({required this.title, required this.icon, this.caption});

//   final String title;
//   final IconData icon;
//   final String? caption;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.43,
//         height: 70,
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: HomeUpdated.card,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [
//             BoxShadow(
//               color: HomeUpdated._shadow,
//               blurRadius: 16,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: 30,
//               height: 43,
//               decoration: BoxDecoration(
//                 color: HomeUpdated.field,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: HomeUpdated.orange, size: 26),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     overflow: TextOverflow.ellipsis,
//                     style: t.titleSmall?.copyWith(
//                       color: HomeUpdated.text,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   if (caption != null) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       caption!,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.bodySmall?.copyWith(
//                         color: HomeUpdated.muted,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CenteredHScroll extends StatelessWidget {
//   const _CenteredHScroll({required this.child, this.paddingLR = 20});
//   final Widget child;
//   final double paddingLR;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, cns) => SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: paddingLR),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(minWidth: cns.maxWidth - paddingLR * 2),
//             child: child,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _TapScale extends StatefulWidget {
//   const _TapScale({super.key, required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_TapScale> createState() => _TapScaleState();
// }

// class _TapScaleState extends State<_TapScale>
//     with SingleTickerProviderStateMixin {
//   double _scale = 1.0;

//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapCancel: _up,
//       onTapUp: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(
//         duration: const Duration(milliseconds: 100),
//         scale: _scale,
//         child: widget.child,
//       ),
//     );
//   }
// }


// ---- Remaining widgets (_GlassHeader, _StatusPill, _CategoryCard, etc.) ----
// keep your existing versions of _GlassHeader, _StatusPill, _CategoryCard,
// _FeatureCard, _CenteredHScroll, and _TapScale unchanged from your last code.




// class HomeUpdated extends StatelessWidget {
//   const HomeUpdated({super.key});

//   // Palette
//   static const cPrimary = Color(0xFFEA7A3B);
//   static const cPrimaryLight = Color(0xFFFFB07A);
//   static const cText = Color(0xFF1E1E1E);
//   static const cMuted = Color(0xFF707883);
//   static const cField = Color(0xFFF5F6F8);
//   static const cCard = Colors.white;
//   static const cShadow = Color(0x1A000000);

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final loginModel = context.read<GlobalBloc>().state.loginModel;

//     final userName = (loginModel?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
//         ? loginModel!.userinfo!.userName.toString()
//         : (loginModel?.userinfo?.userName ?? 'User');

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.light,
//       ),
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F8FA),
//         body: Stack(
//           children: [
//             // ===== GREY MOTIVES WATERMARK (behind everything) =====
//             const _MotivesWatermark(),

//             // ===== CONTENT =====
//             CustomScrollView(
//               physics: const BouncingScrollPhysics(),
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       // Curved gradient header
//                       const _CurvedHeader(),

//                       // Greeting card (glass)
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
//                         child: _Entrance(
//                           delayMs: 0,
//                           child: _GlassCard(
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _Avatar(),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Welcome back,',
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.95),
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       Text(
//                                         userName,
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
//                                 Image.asset('assets/logo-bg.png', height: 52, width: 120),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Status chip stuck to the header’s bottom
//                       Positioned(
//                         left: 20,
//                         right: 20,
//                         bottom: -20,
//                         child: _Entrance(
//                           delayMs: 120,
//                           child: _StatusChip(
//                             text:
//                                 'Last Action : ${context.read<GlobalBloc>().state.activity}',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SliverToBoxAdapter(child: SizedBox(height: 36)),

//                 // ===== QUICK ACTION GRID =====
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
//                   sliver: SliverGrid(
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 14,
//                       mainAxisSpacing: 14,
//                       childAspectRatio: 1.05,
//                     ),
//                     delegate: SliverChildListDelegate.fixed([
//                       _Entrance(
//                         delayMs: 160,
//                         child: _ActionCard(
//                           title: 'Attendance',
//                           subtitle: 'Mark / Review',
//                           icon: Icons.access_time,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => MarkAttendanceView()),
//                             );
//                           },
//                         ),
//                       ),
//                       _Entrance(
//                         delayMs: 220,
//                         child: _ActionCard(
//                           title: 'Routes',
//                           subtitle: 'Daily route plan',
//                           icon: Icons.alt_route,
//                           onTap: () {
//                             if (context.read<GlobalBloc>().state.loginModel!.statusAttendance == "1") {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => RouteScreen()),
//                               );
//                             } else {
//                               toastWidget('Mark your attendance first', Colors.red);
//                             }
//                           },
//                         ),
//                       ),
//                       _Entrance(
//                         delayMs: 280,
//                         child: _ActionCard(
//                           title: 'Punch Order',
//                           subtitle: 'Place new order',
//                           icon: Icons.shopping_cart,
//                           onTap: () {
//                             if (context.read<GlobalBloc>().state.loginModel!.statusAttendance == "1") {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => JourneyPlanScreen()),
//                               );
//                             } else {
//                               toastWidget('Mark your attendance first', Colors.red);
//                             }
//                           },
//                         ),
//                       ),
//                       _Entrance(
//                         delayMs: 340,
//                         child: _ActionCard(
//                           title: 'Records',
//                           subtitle: 'History & logs',
//                           icon: Icons.insert_drive_file,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => TakeOrderPage()),
//                             );
//                           },
//                         ),
//                       ),
//                     ]),
//                   ),
//                 ),

//                 // ===== SECOND ROW (Profile / Sync) =====
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
//                     child: _Entrance(
//                       delayMs: 380,
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: _WideTile(
//                               icon: Icons.person,
//                               title: 'Profile',
//                               caption: 'View profile',
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (_) => const ProfileScreen()),
//                                 );
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _WideTile(
//                               icon: Icons.upload,
//                               title: 'Sync Out',
//                               caption: 'Push updates',
//                               onTap: () {},
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
//                     child: _Entrance(
//                       delayMs: 420,
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: _WideTile(
//                               icon: Icons.download,
//                               title: 'Sync In',
//                               caption: 'Pull latest',
//                               onTap: () {},
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _WideTile(
//                               icon: Icons.add_business_rounded,
//                               title: 'Add Shops',
//                               caption: 'Create outlet',
//                               onTap: () {},
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//           //      const SliverToBoxAdapter(child: SizedBox(height: 16)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ======= Watermark (fixes ParentData issue by placing Positioned.fill at top) =======
// class _MotivesWatermark extends StatelessWidget {
//   const _MotivesWatermark();

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         ignoring: true,
//         child: LayoutBuilder(
//           builder: (_, cns) {
//             final w = cns.maxWidth;
//             final size = w * 0.9;
//             return Center(
//               child: Opacity(
//                 opacity: 0.06,
//                 child: Transform.rotate(
//                   angle: -0.18,
//                   child: ColorFiltered(
//                     colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
//                     child: Image.asset('assets/logo-bg.png', width: size, fit: BoxFit.contain),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // ======= Curved gradient header =======
// class _CurvedHeader extends StatelessWidget {
//   const _CurvedHeader();

//   @override
//   Widget build(BuildContext context) {
//     final h = 190.0;
//     return SizedBox(
//       height: h,
//       child: Stack(
//         children: [
//           // gradient
//           Container(
//             height: h,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           // curve
//           Positioned(
//             bottom: -24,
//             left: -30,
//             right: -30,
//             child: ClipPath(
//               clipper: _BottomCurveClipper(),
//               child: Container(
//                 height: 70,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(.18),
//                   boxShadow: const [
//                     BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BottomCurveClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final p = Path();
//     p.lineTo(0, size.height);
//     p.quadraticBezierTo(size.width * .5, size.height - 36, size.width, size.height);
//     p.lineTo(size.width, 0);
//     p.close();
//     return p;
//   }

//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }

// // ======= Reusable glass card for header =======
// class _GlassCard extends StatelessWidget {
//   const _GlassCard({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _Avatar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 42,
//       height: 42,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.20),
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white, width: 1.2),
//       ),
//       child: const Icon(Icons.person, color: Colors.white, size: 22),
//     );
//   }
// }

// // ======= Status Chip =======
// class _StatusChip extends StatelessWidget {
//   const _StatusChip({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [BoxShadow(color: HomeUpdated.cShadow, blurRadius: 18, offset: Offset(0, 10))],
//         border: Border.all(color: const Color(0xFFEDEFF2)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.assignment_turned_in_rounded, color: HomeUpdated.cPrimary, size: 18),
//           const SizedBox(width: 8),
//           Text(
//             text,
//             style: t.bodyMedium?.copyWith(
//               color: HomeUpdated.cText,
//               fontWeight: FontWeight.w700,
//               letterSpacing: .2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ======= Action Grid Card =======
// class _ActionCard extends StatelessWidget {
//   const _ActionCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return _Pressable(
//       onTap: onTap,
//       child: DecoratedBox(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(2),
//           decoration: BoxDecoration(
//             color: HomeUpdated.cCard,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [BoxShadow(color: HomeUpdated.cShadow, blurRadius: 18, offset: Offset(0, 10))],
//           ),
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Material(
//                 color: HomeUpdated.cField,
//                 shape: const CircleBorder(),
//                 child: SizedBox(width: 48, height: 48, child: Icon(icon, color: HomeUpdated.cPrimary)),
//               ),
//               const Spacer(),
//               Text(
//                 title,
//                 style: t.titleMedium?.copyWith(
//                   color: HomeUpdated.cText,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: t.bodySmall?.copyWith(color: HomeUpdated.cMuted),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ======= Wide horizontal tiles =======
// class _WideTile extends StatelessWidget {
//   const _WideTile({
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
//       child: DecoratedBox(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [HomeUpdated.cPrimary, HomeUpdated.cPrimaryLight],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Container(
//           height: 78,
//           margin: const EdgeInsets.all(2),
//           decoration: BoxDecoration(
//             color: HomeUpdated.cCard,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [BoxShadow(color: HomeUpdated.cShadow, blurRadius: 18, offset: Offset(0, 10))],
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               Container(
//                 width: 36,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: HomeUpdated.cField,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: HomeUpdated.cPrimary, size: 26),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.titleSmall?.copyWith(
//                         color: HomeUpdated.cText,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       caption,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.bodySmall?.copyWith(color: HomeUpdated.cMuted),
//                     ),
//                   ],
//                 ),
//               ),
//             //  const Icon(Icons.chevron_right, color: HomeUpdated.cMuted),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ======= Small helpers =======
// class _Pressable extends StatefulWidget {
//   const _Pressable({required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_Pressable> createState() => _PressableState();
// }

// class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
//   double _scale = 1;
//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapUp: _up,
//       onTapCancel: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(
//         scale: _scale,
//         duration: const Duration(milliseconds: 90),
//         child: widget.child,
//       ),
//     );
//   }
// }

// class _Entrance extends StatefulWidget {
//   const _Entrance({required this.child, this.delayMs = 0});
//   final Widget child;
//   final int delayMs;

//   @override
//   State<_Entrance> createState() => _EntranceState();
// }

// class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
//   late final AnimationController _ac =
//       AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
//   late final Animation<double> _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
//   late final Animation<Offset> _offset =
//       Tween(begin: const Offset(0, .08), end: Offset.zero).animate(
//         CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
//       );

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration(milliseconds: widget.delayMs), _ac.forward);
//   }

//   @override
//   void dispose() {
//     _ac.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _opacity,
//       child: SlideTransition(position: _offset, child: widget.child),
//     );
//   }
// }


/*
class HomeUpdated extends StatelessWidget {
  const HomeUpdated({super.key});

  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF5F5F7);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loginModel = context.read<GlobalBloc>().state.loginModel;

    final userName = (loginModel?.userinfo?.userName?.toString().trim().isNotEmpty ?? false)
        ? loginModel!.userinfo!.userName.toString()
        : (loginModel?.userinfo?.userName ?? 'User');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.grey,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ===== Subtle grey MOTIVES watermark (behind everything) =====
            const _MotivesWatermark(),

            // ===== Your original content (unchanged) =====
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
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
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back,',
                                            style: t.titleMedium?.copyWith(
                                              color: Colors.white.withOpacity(.95),
                                              fontWeight: FontWeight.w600,
                                              height: 1.1,
                                            ),
                                          ),
                                          Text(
                                            userName,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.headlineSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/logo-bg.png',
                                      height: 50,
                                      width: 110,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 115,
                          left: 20,
                          child: _StatusPill(
                            icon: Icons.assignment_turned_in_rounded,
                            label:
                                'Last Action Performed : ${context.read<GlobalBloc>().state.activity}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.10,
                      ),
                      delegate: SliverChildListDelegate.fixed([
                        _TapScale(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MarkAttendanceView()),
                            );
                          },
                          child: const _CategoryCard(
                            icon: Icons.access_time,
                            title: 'Attendance',
                            subtitle: 'Mark / Review',
                          ),
                        ),
                        _TapScale(
                          onTap: () {
                            if (context.read<GlobalBloc>().state.loginModel!.statusAttendance == "1") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RouteScreen()),
                              );
                            } else {
                              toastWidget('Mark your attendence first', Colors.red);
                            }
                          },
                          child: const _CategoryCard(
                            icon: Icons.alt_route,
                            title: 'Routes',
                            subtitle: 'Daily route plan',
                          ),
                        ),
                        _TapScale(
                          onTap: () {
                            if (context.read<GlobalBloc>().state.loginModel!.statusAttendance == "1") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => JourneyPlanScreen()),
                              );
                            } else {
                              toastWidget('Mark your attendence first', Colors.red);
                            }
                          },
                          child: const _CategoryCard(
                            icon: Icons.shopping_cart,
                            title: 'Punch Order',
                            subtitle: 'Place new order',
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TakeOrderPage()),
                            );
                          },
                          child: const _CategoryCard(
                            icon: Icons.insert_drive_file,
                            title: 'Records',
                            subtitle: 'History & logs',
                          ),
                        ),
                      ]),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 118,
                      child: _CenteredHScroll(
                        paddingLR: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TapScale(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              },
                              child: const _FeatureCard(
                                title: 'Profile',
                                icon: Icons.person,
                                caption: 'View profile',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const _FeatureCard(
                              title: 'Sync Out',
                              icon: Icons.upload,
                              caption: 'Push updates',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                      child: _CenteredHScroll(
                        paddingLR: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _FeatureCard(
                              title: 'Sync In',
                              icon: Icons.download,
                              caption: 'Pull latest',
                            ),
                            SizedBox(width: 12),
                            _FeatureCard(
                              title: 'Add Shops',
                              icon: Icons.add_business_rounded,
                              caption: 'Create outlet',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Watermark (background only) ----------
class _MotivesWatermark extends StatelessWidget {
  const _MotivesWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // do not block touches
      child: Positioned.fill(
        child: LayoutBuilder(
          builder: (context, cns) {
            final w = cns.maxWidth;
            final size = w * 0.80; // responsive scale
            return Center(
              child: Opacity(
                opacity: 0.06, // subtle
                child: Transform.rotate(
                  angle: -0.20, // slight tilt for style
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.black54, // grey tone
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/logo-bg.png', // your PNG
                      width: size,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------- Existing widgets (unchanged) ----------
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: HomeUpdated._shadow, blurRadius: 16, offset: Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: HomeUpdated.field,
              shape: const CircleBorder(),
              child: SizedBox(width: 46, height: 46, child: Icon(icon, color: HomeUpdated.orange)),
            ),
            const Spacer(),
            Text(
              title,
              style: t.titleMedium?.copyWith(
                color: HomeUpdated.text,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: HomeUpdated.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.icon, this.caption});
  final String title;
  final IconData icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.43,
        height: 70,
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: HomeUpdated._shadow, blurRadius: 16, offset: Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 43,
              decoration: BoxDecoration(
                color: HomeUpdated.field,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: HomeUpdated.orange, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: HomeUpdated.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: HomeUpdated.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredHScroll extends StatelessWidget {
  const _CenteredHScroll({required this.child, this.paddingLR = 20});
  final Widget child;
  final double paddingLR;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cns) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingLR),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: cns.maxWidth - paddingLR * 2),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
*/

/*

class HomeUpdated extends StatelessWidget {
  const HomeUpdated({super.key});

  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF5F5F7);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loginModel = context.read<GlobalBloc>().state.loginModel;

    final userName =
        loginModel?.userinfo?.userName?.toString().trim().isNotEmpty == true
        ? loginModel!.userinfo!.userName.toString()
        : (loginModel?.userinfo!.userName ?? 'User');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.grey,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                        // colors: [Colors.grey,Colors.grey],
                          colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
                          //  colors: [orange, Color(0xFFFFB07A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _GlassHeader(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.95),
                                          fontWeight: FontWeight.w600,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        userName,
                                     //   maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          height: 1.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                 Image.asset(
                                  'assets/logo-bg.png',
                                  height: 50,
                                  width: 110,
                                //  color: Colors.white,
                                ),
                              //  OrangePills(),
                              ],
                            ),
                            const SizedBox(height: 5),
                            //  _StatusPill(
                            //   icon: Icons.assignment_turned_in_rounded,
                            //   label: 'Last Action Performed : ${context.read<GlobalBloc>().state.activity}',
                            // ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 115,
                      left: 20,
                      child: _StatusPill(
                        icon: Icons.assignment_turned_in_rounded,
                        label:
                            'Last Action Performed : ${context.read<GlobalBloc>().state.activity}',
                      ),
                    ),
                  ],
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.10,
                  ),
                  delegate: SliverChildListDelegate.fixed([
                    _TapScale(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarkAttendanceView(),
                          ),
                        );
                      },
                      child: const _CategoryCard(
                        icon: Icons.access_time,
                        title: 'Attendance',
                        subtitle: 'Mark / Review',
                      ),
                    ),
                    _TapScale(
                      onTap: () {
                        if (context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .statusAttendance ==
                            "1") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteScreen(),
                            ),
                          );
                        } else {
                          toastWidget('Mark your attendence first', Colors.red);
                        }
                      },
                      child: const _CategoryCard(
                        icon: Icons.alt_route,
                        title: 'Routes',
                        subtitle: 'Daily route plan',
                      ),
                    ),
                    _TapScale(
                      onTap: () {
                        if (context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .statusAttendance ==
                            "1") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JourneyPlanScreen(),
                            ),
                          );
                        } else {
                          toastWidget('Mark your attendence first', Colors.red);
                        }
                      },
                      child: const _CategoryCard(
                        icon: Icons.shopping_cart,
                        title: 'Punch Order',
                        subtitle: 'Place new order',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakeOrderPage(),
                          ),
                        );
                      },
                      child: const _CategoryCard(
                        icon: Icons.insert_drive_file,
                        title: 'Records',
                        subtitle: 'History & logs',
                      ),
                    ),
                  ]),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 118,
                  child: _CenteredHScroll(
                    paddingLR: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TapScale(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: const _FeatureCard(
                            title: 'Profile',
                            icon: Icons.person,
                            caption: 'View profile',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const _FeatureCard(
                          title: 'Sync Out',
                          icon: Icons.upload,
                          caption: 'Push updates',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: _CenteredHScroll(
                    paddingLR: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureCard(
                          title: 'Sync In',
                          icon: Icons.download,
                          caption: 'Pull latest',
                        ),
                        SizedBox(width: 12),
                        _FeatureCard(
                          title: 'Add Shops',
                          icon: Icons.add_business_rounded,
                          caption: 'Create outlet',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(
              color: HomeUpdated._shadow,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: HomeUpdated.field,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, color: HomeUpdated.orange),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: t.titleMedium?.copyWith(
                color: HomeUpdated.text,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: HomeUpdated.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.icon, this.caption});

  final String title;
  final IconData icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.43, // wider since horizontal
        height: 70,
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(
              color: HomeUpdated._shadow,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Icon
            Container(
              width: 30,
              height: 43,
              decoration: BoxDecoration(
                color: HomeUpdated.field,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: HomeUpdated.orange, size: 26),
            ),
            const SizedBox(width: 14),
            // Right: Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: HomeUpdated.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: HomeUpdated.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredHScroll extends StatelessWidget {
  const _CenteredHScroll({required this.child, this.paddingLR = 20});
  final Widget child;
  final double paddingLR;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cns) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingLR),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: cns.maxWidth - paddingLR * 2),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
*/