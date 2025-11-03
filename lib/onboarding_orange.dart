import 'package:flutter/material.dart';

/// Orange + White text-only onboarding inspired by your reference image.
/// - Page 1: Mark attendance & start your route
/// - Page 2: Check journey plan with area filters
/// - Page 3: Shop visit flow + auto-sync + sign out
///
/// No images, only text. Colors restricted to orange/white.
class OrangeOnboarding extends StatefulWidget {
  const OrangeOnboarding({super.key});

  @override
  State<OrangeOnboarding> createState() => _OrangeOnboardingState();
}

class _OrangeOnboardingState extends State<OrangeOnboarding> {
  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kWhite  = Colors.white;

  final _pc = PageController();
  int _idx = 0;

  void _goNext() {
    if (_idx < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      // TODO: Navigate to your sign up/home
      Navigator.of(context).maybePop();
    }
  }

  void _skip() {
    // TODO: Handle skip (maybe go to login/home)
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: kWhite,
        colorScheme: ColorScheme.fromSeed(seedColor: kOrange, primary: kOrange, background: kWhite),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kOrange, height: 1.2),
          bodyMedium: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: kOrange, height: 1.35),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kOrange),
        ),
        useMaterial3: true,
      ),
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              // Top bar (Skip/Later)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    // little dash placeholder (kept in white/orange theme)
                    Container(width: 28, height: 4, decoration: BoxDecoration(color: kOrange.withOpacity(.16), borderRadius: BorderRadius.circular(999))),
                    const Spacer(),
                    TextButton(
                      onPressed: _skip,
                      child: Text(_idx < 2 ? 'Skip' : 'Later', style: const TextStyle(color: kOrange, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _idx = i),
                  children: const [
                    _OnboardPanel(
                      title: 'Mark attendance\n& start your route',
                      body:
                          'Begin your day by marking attendance, then start your route to kick off today’s work.',
                      midLabel: 'ATTENDANCE • ROUTE',
                    ),
                    _OnboardPanel(
                      title: 'Check your journey plan',
                      body:
                          'Use area filters to finish faster.\nPlan your journey area-wise and follow today’s route efficiently.',
                      midLabel: 'AREA FILTERS • ROUTE PLAN',
                    ),
                    _OnboardPanel(
                      title: 'Visit shops & auto-sync',
                      body:
                          'Select a shop to visit → Check in → pick a reason / place orders / collect payment → Check out.\nAll data syncs automatically—no manual sync in/out. Complete your journey plan and sign out.',
                      midLabel: 'CHECK-IN • ORDER • PAYMENT • CHECK-OUT',
                    ),
                  ],
                ),
              ),

              // Dots + CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final selected = i == _idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 6,
                          width: selected ? 24 : 8,
                          decoration: BoxDecoration(
                            color: selected ? kOrange : kOrange.withOpacity(.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Primary pill (white pill like the reference, orange text/border)
                    SizedBox(
                      width: double.infinity,
                      child: _WhitePillButton(
                        label: _idx < 2 ? 'Continue' : 'Sign up',
                        onPressed: _goNext,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Secondary link on last page (Login)
                    if (_idx == 2)
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to Login
                          Navigator.of(context).maybePop();
                        },
                        child: const Text('Login', style: TextStyle(color: kOrange, fontWeight: FontWeight.w700)),
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

/// A centered panel with headline, body and a text-only "hero" block
class _OnboardPanel extends StatelessWidget {
  const _OnboardPanel({
    required this.title,
    required this.body,
    required this.midLabel,
  });

  final String title;
  final String body;
  final String midLabel;

  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kWhite  = Colors.white;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (_, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 12),
                Column(
                  children: [
                    Text(title, textAlign: TextAlign.center, style: t.headlineMedium),
                    const SizedBox(height: 10),
                    Text(body, textAlign: TextAlign.center, style: t.bodyMedium),
                  ],
                ),
                // Text-only "illustration" card (kept minimal, white background, orange border)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kOrange, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: kOrange.withOpacity(.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    midLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// White pill button with orange outline + text (matches reference feel)
class _WhitePillButton extends StatelessWidget {
  const _WhitePillButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kWhite  = Colors.white;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kOrange, width: 2),
        backgroundColor: kWhite,
        foregroundColor: kOrange,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
