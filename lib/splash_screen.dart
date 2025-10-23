import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/intro_screens.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';
import 'home_screen.dart';


// splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';



const _orange = Color(0xFFEA7A3B);
const _card = Colors.white;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl; // logo pop-in
  late final AnimationController _pillCtrl; // rotating/sweeping pills
  late final AnimationController _fadeCtrl; // tagline + content fade/slide
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

        

    // Sequence: start logo, then pills, then tagline, then start auth flow.
    _logoCtrl.forward().whenComplete(() {
      _pillCtrl.repeat();
      _fadeCtrl.forward();
      _startAuthFlow(); // <-- changed (no timed jump to Home)
    });
  }

  void _startAuthFlow() {
    final box = GetStorage();
    final email = box.read<String>('email');
    final password = box.read<String>('password');

    // If saved creds exist, let Bloc try login; otherwise go to Onboarding.
    if (email != null && password != null) {
      context.read<GlobalBloc>().add(LoginEvent(email: email, password: password));
    } else {
      // tiny delay so the splash animation breathes before navigating
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(_fadeRoute(const OnboardingScreen()));
      });
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pillCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GlobalBloc, GlobalState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {

            final box = GetStorage();
    var email = box.read("email");
        // ⛔️ Do NOT navigate to Home when success
        if (state.status == LoginStatus.success && email != null ) {
          // Option A: go to selfie/attendance gate first
          Navigator.of(context).pushReplacement(
            _fadeRoute(const HomeUpdated()),
          );

          // Option B (do nothing): comment the line above to remain on splash
          // return;
        } else if (email == null) {
          Navigator.of(context).pushReplacement(
            _fadeRoute(const OnboardingScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Soft rotating radial sweep in the background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pillCtrl,
                builder: (_, __) {
                  final a = _pillCtrl.value * 2 * math.pi;
                  return CustomPaint(painter: _SoftSweepPainter(angle: a));
                },
              ),
            ),
            SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.90,
                      child: _LogoCard(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(18),
                            child: Transform.rotate(
                              angle: -6 * 3.1415926 / 150,
                              child: Image.asset(
                                'assets/logo-bg.png',
                                height: 100,
                                width: 200,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SoftSweepPainter extends CustomPainter {
  _SoftSweepPainter({required this.angle});
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide * .7;

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + math.pi * 2,
        colors: [
          _orange.withOpacity(.08),
          Colors.transparent,
          _orange.withOpacity(.06),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweep);

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(.03)],
      ).createShader(Rect.fromCircle(center: center, radius: size.longestSide));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _SoftSweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}

PageRouteBuilder _fadeRoute(Widget child) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}


// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// const _orange = Color(0xFFEA7A3B);
// const _text = Color(0xFF1E1E1E);
// const _muted = Color(0xFF707883);
// const _card = Colors.white;

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _logoCtrl; // logo pop-in
//   late final AnimationController _pillCtrl; // rotating/sweeping pills
//   late final AnimationController _fadeCtrl; // tagline + content fade/slide
//   late final Animation<double> _logoScale;
//   late final Animation<double> _logoOpacity;
//   late final Animation<double> _taglineOpacity;
//   late final Animation<Offset> _taglineOffset;

//   @override
//   void initState() {
//     super.initState();

//     _logoCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//     _pillCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2400),
//     );
//     _fadeCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     _logoScale = Tween(
//       begin: 0.85,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
//     _logoOpacity = Tween(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

//     _taglineOpacity = Tween(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
//     _taglineOffset = Tween(
//       begin: const Offset(0, .15),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

//     // Sequence: start logo, then pills, then tagline, then navigate.
//     _logoCtrl.forward().whenComplete(() {
//       _pillCtrl.repeat(); // continuous sweep while splash shows
//       _fadeCtrl.forward();
//       Future.delayed(const Duration(seconds: 5), _goHome);
//     });
//   }

//   void _goHome() {
//     if (!mounted) return;
//     _pillCtrl.stop();
    // final box = GetStorage();
    // var email = box.read("email");
//     if (email != null) {
//       Navigator.of(context).pushReplacement(_fadeRoute(const HomeUpdated()));
//     } else {
//       Navigator.of(
//         context,
//       ).pushReplacement(_fadeRoute(const OnboardingScreen()));
//     }
//     // email != null ?HomeUpdated() :  SplashScreen(),
//     // Navigator.of(context).pushReplacement(_fadeRoute(const OnboardingScreen()));
//   }

//   @override
//   void dispose() {
//     _logoCtrl.dispose();
//     _pillCtrl.dispose();
//     _fadeCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//         //    WatermarkTiledSmall(tileScale: 3.0),
//           // Background gradient sweep (very subtle)
//           Positioned.fill(
//             child: AnimatedBuilder(
//               animation: _pillCtrl,
//               builder: (_, __) {
//                 final a = _pillCtrl.value * 2 * math.pi;
//                 return CustomPaint(painter: _SoftSweepPainter(angle: a));
//               },
//             ),
//           ),

//           // Center content
//           SafeArea(
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Decorative angled pills (your login motif)
//                   // const SizedBox(height: 10),
//                   // Transform.rotate(
//                   //   angle: -12 * math.pi / 180,
//                   //   child: _OrangePills(anim: _pillCtrl),
//                   // ),
//                   // const SizedBox(height: 24),

//                   // Logo pop-in
//                   ScaleTransition(
//                     scale: _logoScale,
//                     child: FadeTransition(
//                       opacity: _logoOpacity,
//                       child: SizedBox(
//                         width: MediaQuery.of(context).size.width * 0.90,
//                         child: _LogoCard(
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(18),
//                             child: Container(
//                               color: Colors.white,
//                               padding: const EdgeInsets.all(18),
//                               child: Transform.rotate(
//                                 angle:
//                                     -6 *
//                                     3.1415926 /
//                                     150, // same tilt as your pills
//                                 child: Image.asset(
//                                   'assets/logo-bg.png',
//                                   height: 100,
//                                   width: 200,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   // const SizedBox(height: 18),

//                   // FadeTransition(
//                   //   opacity: _logoOpacity,
//                   //   child: Text(
//                   //     "Motives",
//                   //     style: t.headlineSmall?.copyWith(
//                   //       color: _text,
//                   //       fontWeight: FontWeight.w800,
//                   //       letterSpacing: .6,
//                   //     ),
//                   //   ),
//                   // ),
//                   const SizedBox(height: 6),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LogoCard extends StatelessWidget {
//   const _LogoCard({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [_orange, Color(0xFFFFB07A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.all(Radius.circular(20)),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           color: _card,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 14,
//               offset: Offset(0, 8),
//             ),
//           ],
//         ),
//         child: child,
//       ),
//     );
//   }
// }

// class _OrangePills extends StatelessWidget {
//   const _OrangePills({required this.anim});
//   final AnimationController anim;

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: anim,
//       builder: (_, __) {
//         final shift = (anim.value - .5) * 10; // small breathing
//         return Column(
//           children: [
//             _Pill(color: _orange.withOpacity(.18), width: 52 + shift),
//             const SizedBox(height: 6),
//             _Pill(color: _orange.withOpacity(.34), width: 64 - shift),
//             const SizedBox(height: 6),
//             const _Pill(color: _orange, width: 86),
//           ],
//         );
//       },
//     );
//   }
// }

// class _Pill extends StatelessWidget {
//   const _Pill({required this.color, required this.width});
//   final Color color;
//   final double width;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width,
//       height: 14,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(8),
//       ),
//     );
//   }
// }

// // Soft rotating radial sweep in the background (very light)
// class _SoftSweepPainter extends CustomPainter {
//   _SoftSweepPainter({required this.angle});
//   final double angle;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = size.longestSide * .7;

//     final sweep = Paint()
//       ..shader = SweepGradient(
//         startAngle: angle,
//         endAngle: angle + math.pi * 2,
//         colors: [
//           _orange.withOpacity(.08),
//           Colors.transparent,
//           _orange.withOpacity(.06),
//         ],
//         stops: const [0.0, 0.55, 1.0],
//       ).createShader(Rect.fromCircle(center: center, radius: radius));

//     canvas.drawCircle(center, radius, sweep);

//     // faint vignette
//     final vignette = Paint()
//       ..shader = RadialGradient(
//         colors: [Colors.transparent, Colors.black.withOpacity(.03)],
//       ).createShader(Rect.fromCircle(center: center, radius: size.longestSide));
//     canvas.drawRect(Offset.zero & size, vignette);
//   }

//   @override
//   bool shouldRepaint(covariant _SoftSweepPainter oldDelegate) =>
//       oldDelegate.angle != angle;
// }

// // --------------------- Page transition ---------------------
// PageRouteBuilder _fadeRoute(Widget child) {
//   return PageRouteBuilder(
//     transitionDuration: const Duration(milliseconds: 450),
//     pageBuilder: (_, __, ___) => child,
//     transitionsBuilder: (_, anim, __, child) {
//       return FadeTransition(
//         opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
//         child: child,
//       );
//     },
//   );
// }
