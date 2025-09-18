import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/login.dart';

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
      title: 'Mark your attendance!',
      asset: 'assets/time_card_icon.png',
    ),
    _OnbData(
      title: 'Start your route and follow your daily journey plan!',
      asset: 'assets/routes.png',
    ),
    _OnbData(
      title: 'End your route and wrap up your day!',
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
              itemBuilder: (_, i) => _OnboardPage(data: pages[i]),
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
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
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

                  // Model image (transparent PNG)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom:186),
                      child: Image.asset(
                        data.asset,
                        width: c.maxWidth * .46,
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
