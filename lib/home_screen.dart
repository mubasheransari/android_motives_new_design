import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/journey_plan_screen.dart';
import 'package:motives_new_ui_conversion/mark_attendance.dart';
import 'package:motives_new_ui_conversion/peofile_screen.dart';
import 'package:motives_new_ui_conversion/take_order.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';
import 'dart:ui';

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
        statusBarColor: Color(0xFFFFCCB6), // Peach
        statusBarIconBrightness: Brightness.dark, // Icons contrast
      ),
      child: Scaffold(
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
                          colors: [Colors.grey, Color(0xFFFFB07A)],
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
                                // avatar-ish badge
                                Container(
                                  width: 54,
                                  height: 54,
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
                                    size: 28,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          height: 1.05,
                                        ),
                                      ),

                                      // const _StatusPill(
                                      //   icon: Icons.assignment_turned_in_rounded,
                                      //   label: 'Last Action Performed : LOGIN',
                                      // ),
                                      // const SizedBox(height: 12),
                                      // const _StatusPill(
                                      //   icon: Icons.assignment_turned_in_rounded,
                                      //   label: 'Last Action Performed : LOGIN',
                                      // ),
                                    ],
                                  ),
                                ),
                                _OrangePills(),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const _StatusPill(
                              icon: Icons.assignment_turned_in_rounded,
                              label: 'Last Action Performed : LOGIN',
                            ),
                          ],
                        ),
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
                    const _CategoryCard(
                      icon: Icons.alt_route,
                      title: 'Routes',
                      subtitle: 'Daily route plan',
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
                            caption: 'View & edit',
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
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangePills extends StatelessWidget {
  const _OrangePills();

  @override
  Widget build(BuildContext context) {
    const orange = HomeUpdated.orange;
    return Transform.rotate(
      angle: -12 * 3.1415926 / 180,
      child: Column(
        children: [
          _Pill(color: Colors.white.withOpacity(.28), width: 64),
          const SizedBox(height: 6),
          _Pill(color: orange.withOpacity(.34), width: 78),
          const SizedBox(height: 6),
          _Pill(color: orange, width: 86),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.24),
            blurRadius: 10,
            spreadRadius: 1,
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
              width: 33,
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
                    //    maxLines: 1,
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
