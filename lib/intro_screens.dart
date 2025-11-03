import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motives_new_ui_conversion/login.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';

// TODO: import your NewLoginScreen file
// import 'package:your_app/new_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // HomeUpdated / Login theme palette
  static const cBg = Color(0xFFEEEEEE);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);

  final controller = PageController();
  int index = 0;

final pages = [
  _OnbData(
    title: 'Mark attendance & start your route',
    points: [
      'Mark attendance to clock in.',
      'Tap Start Route to begin your day.',
      'Enable location for accurate visit logs.',
      'Check-in works only after you start your route.',
      'Today’s journey plan unlocks once you start.',
      'Shops are grouped by area for faster coverage.',
      'Weak signal? Actions save offline and auto-sync later.',
      'Your start time is recorded for the shift.',
      'Finish your day with End Route.',
    ],
  ),
  _OnbData(
    title: 'Plan today’s journey by areas',
    points: [
      'Check your journey plan for today.',
      'Use area filters to cover faster.',
      'Prioritize nearest routes first.',
    ],
  ),
  _OnbData(
    title: 'Visit shops & auto-sync',
    points: [
      'Select a shop to visit and Check-in.',
      'Place order / collect payment / choose a reason.',
      'Checkout when done — data auto-syncs, no manual sync needed.',
      'Complete your journey plan and Sign out.',
    ],
  ),
];


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _next() {
    if (index < pages.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NewLoginScreen()),
        (route) => false,
      );
    }
  }

  void _skip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isLast = index == pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // OPTIONAL: watermark only on this screen (must be direct child of Stack)
            const WatermarkTiledSmall(tileScale: 3.0),

            SafeArea(
              child: Column(
                children: [
                  // top bar: skip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Spacer(),
                        TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: cPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  // pages
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => index = i),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (_, i) {
                        final data = pages[i];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glass hero with small badge + title (like HomeUpdated)
                     _HeroGlassHeader(
  titleBottom: data.title,
  points: data.points, // <-- now List<String>
),
                            const SizedBox(height: 16),
                        
                            // Artwork in a glass panel
                         /*   Expanded(
                              child: _GlassPanel(
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // soft orange radial aura
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              colors: [cPrimary.withOpacity(.10), Colors.transparent],
                                              radius: .85,
                                              center: const Alignment(0, -.2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Image.asset(
                                          data.asset,
                                          height: 300,
                                         // fit: BoxFit.contain,
                                          width: MediaQuery.of(context).size.width * .58,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),*/
                          ],
                        );
                      },
                    ),
                  ),

                  // bottom glass sheet: dots + CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: _BottomGlass(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          _PagerDots(count: pages.length, index: index),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _PrimaryButton(
                              label: isLast ? 'Get Started' : 'Next',
                              onPressed: _next,
                            ),
                          ),
                        ],
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

/* -------------------- Data -------------------- */

class _OnbData {
  final String title;
  final List<String> points;
  const _OnbData({required this.title, required this.points});
}
class _HeroGlassHeader extends StatelessWidget {
  const _HeroGlassHeader({
    required this.titleBottom,
    required this.points,
  });

  final String titleBottom;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _OnboardingScreenState.cStroke),
            boxShadow: const [
              BoxShadow(
                color: _OnboardingScreenState.cShadow,
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // align with title
            children: [
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     border: Border.all(color: _OnboardingScreenState.cStroke),
              //     boxShadow: const [
              //       BoxShadow(
              //         color: _OnboardingScreenState.cShadow,
              //         blurRadius: 12,
              //         offset: Offset(0, 6),
              //       )
              //     ],
              //   ),
              //   child: Image.asset('assets/slide.png', height: 40, width: 40),
              // ),
              // const SizedBox(width: 14),
              // Title + bullets
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // <-- left align
                    children: [
                      Text(
                        titleBottom,
                        style: t.titleMedium?.copyWith(
                          color: _OnboardingScreenState.cText,
                          fontWeight: FontWeight.w900,
                          height: 1.06,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // dynamic bullet list
                      ...points.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _OnboardingScreenState.cText,
                                    )),
                                Expanded(
                                  child: Text(
                                    p,
                                    softWrap: true,
                                    style: t.titleSmall?.copyWith(
                                      color: _OnboardingScreenState.cText,
                                      fontWeight: FontWeight.w400,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
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


class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.84),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _OnboardingScreenState.cStroke),
            boxShadow: const [BoxShadow(color: _OnboardingScreenState.cShadow, blurRadius: 18, offset: Offset(0, 10))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BottomGlass extends StatelessWidget {
  const _BottomGlass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _OnboardingScreenState.cStroke),
            boxShadow: const [BoxShadow(color: _OnboardingScreenState.cShadow, blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
          height: 8,
          width: active ? 34 : 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _OnboardingScreenState.cStroke),
            color: active
                ? _OnboardingScreenState.cPrimary.withOpacity(.85)
                : Colors.white.withOpacity(.70),
            boxShadow: const [BoxShadow(color: _OnboardingScreenState.cShadow, blurRadius: 8, offset: Offset(0, 4))],
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [BoxShadow(color: _OnboardingScreenState.cShadow, blurRadius: 16, offset: Offset(0, 10))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: _OnboardingScreenState.cPrimary, // fallback
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            gradient: LinearGradient(
              colors: [_OnboardingScreenState.cPrimary, _OnboardingScreenState.cPrimarySoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: .2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// /* -------------------- Optional: stub -------------------- */

// // Watermark widget stub (use your existing implementation)
// class WatermarkTiledSmall extends StatelessWidget {
//   const WatermarkTiledSmall({super.key, this.tileScale = 3.0});
//   final double tileScale;

//   @override
//   Widget build(BuildContext context) {
//     // Replace with your real tiled watermark; keep Stack direct parent if using Positioned inside.
//     return Container(); // <-- remove this when using your real implementation
//   }
// }

// // Replace with your actual login screen import
// class NewLoginScreen extends StatelessWidget {
//   const NewLoginScreen({super.key});
//   @override
//   Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login'))); 
// }
/*

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const accent = Color(0xFFE97C42);
  static const bgPeach = Color(0xFFFFE8E3);

  final controller = PageController();
  int index = 0;

  final pages = const [
    _OnbData(
      title: 'Mark Your Attendance!',
      asset: 'assets/time_card_icon.png',
    ),
    _OnbData(
      title: 'Start Your Route & Follow Your Daily Journey Plan!',
      asset: 'assets/routes.png',
    ),
    _OnbData(
      title: 'End Your Route & Wrap Up Your Day!',
      asset: 'assets/end_route_icon.png',
      // underline: true,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _next() {
    if (index < pages.length - 1) {
      controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NewLoginScreen()),
        (route) => false,
      );
    }
  }

  void _skip() {
    //controller.jumpToPage(pages.length - 1);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => NewLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = index == pages.length - 1;

    return Scaffold(
      backgroundColor: bgPeach,
      body: SafeArea(
        child: Stack(
          children: [
            // Pages
            PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(top:40.0),
                child: _OnboardPage(data: pages[i]),
              ),
            ),

            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: const Text('Skip',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            // Bottom sheet: title, pager, CTA
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        pages[index].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: pages[index].underline
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: const Color(
                              0xFF1E3A8A), // subtle blue underline like screenshot
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),

                    // Pager dots (two gray dots + long orange dash active)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (i) {
                        final active = i == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: EdgeInsets.only(
                              right: i == pages.length - 1 ? 0 : 8),
                          height: 6,
                          width: active ? 36 : 8,
                          decoration: BoxDecoration(
                            color: active ? accent : Colors.black26,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnbData {
  final String title;
  final String asset;
  final bool underline;
  const _OnbData(
      {required this.title, required this.asset, this.underline = false});
}

class _OnboardPage extends StatelessWidget {
  static const accent = Color(0xFFE97C42);
  static const light = Color(0xFFFFE1D2);
  static const mid = Color(0xFFF6B79C);

  final _OnbData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    // Stack with tilted rectangles + model image centered
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative tilted blocks (behind model)
                  Positioned(
                    top: h * 0.16,
                    left: 36,
                    right: 36,
                    child: _TiltedBar(
                        width: c.maxWidth * .72,
                        height: 80,
                        color: mid,
                        angle: -0.18),
                  ),
                  Positioned(
                    top: h * 0.24,
                    left: 56,
                    right: 56,
                    child: _TiltedBar(
                        width: c.maxWidth * .68,
                        height: 82,
                        color: accent.withOpacity(.92),
                        angle: -0.18),
                  ),
                  Positioned(
                    top: h * 0.34,
                    left: 44,
                    right: 44,
                    child: _TiltedBar(
                        width: c.maxWidth * .70,
                        height: 84,
                        color: light,
                        angle: -0.18),
                  ),

                  // Model image (transparent PNG) 0309 6282575
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom:249),
                      child: Image.asset(
                        data.asset,
                        width: c.maxWidth * .35,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The bottom section is handled in parent (title, dots, button)
            const SizedBox(
                height: 160), // space reserved for bottom content overlay
          ],
        );
      },
    );
  }
}

class _TiltedBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double angle; // radians

  const _TiltedBar({
    required this.width,
    required this.height,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
*/