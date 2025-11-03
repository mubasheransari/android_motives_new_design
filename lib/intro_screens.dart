import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motives_new_ui_conversion/login.dart';

import 'dart:ui';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';



import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/login.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';

/* -------------------------------------------------------------------------- */
/*                                   THEME                                    */
/* -------------------------------------------------------------------------- */
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // palette
  static const cBg = Color(0xFFEEEEEE);
  static const cText = Color(0xFF1F2937);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);

  final controller = PageController();
  int index = 0;

  // --- LANG state/prefs ---
  final _prefs = _OnbPrefs();
  late AppLang _lang;
  late _L10nOnb _t;
  late List<_OnbData> _pages;

  @override
  void initState() {
    super.initState();
    _lang = _prefs.getLang();
    _t = _L10nOnb(_lang);
    _pages = _pagesFor(_lang);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // build localized pages
  List<_OnbData> _pagesFor(AppLang l) => [
        _OnbData(
          title: l == AppLang.en
              ? 'Mark attendance & start your route'
              : 'حاضری لگائیں اور روٹ شروع کریں',
          points: l == AppLang.en
              ? const [
                  'Mark attendance to clock in.',
                  'Tap Start Route to begin your day.',
                  'Enable location for accurate visit logs.',
                  'Check-in works only after you start your route.',
                  'Today’s journey plan unlocks once you start.',
                  'Shops are grouped by area for faster coverage.',
                  'Weak signal? Actions save offline and auto-sync later.',
                  'Your start time is recorded for the shift.',
                  'Finish your day with End Route.',
                ]
              : const [
                  'حاضری لگا کر ڈیوٹی شروع کریں۔',
                  'دن شروع کرنے کیلئے “روٹ شروع کریں” دبائیں۔',
                  'درست ریکارڈ کیلئے لوکیشن آن رکھیں۔',
                  'چیک اِن صرف روٹ شروع کرنے کے بعد ممکن ہے۔',
                  'آج کا جرنی پلان روٹ شروع ہونے پر کھلتا ہے۔',
                  'تیزی کیلئے دکانیں ایریا کے مطابق گروپ ہیں۔',
                  'کم سگنل؟ ایکشن آف لائن محفوظ ہوں گے، انٹرنیٹ پر خود سنک۔',
                  'آپ کے شفٹ کا آغاز وقت ریکارڈ ہوتا ہے۔',
                  'آخر میں “روٹ ختم کریں” ضرور دبائیں۔',
                ],
        ),
        _OnbData(
          title: l == AppLang.en
              ? 'Plan today’s journey by areas'
              : 'آج کا جرنی پلان علاقوں کے حساب سے',
          points: l == AppLang.en
              ? const [
                  'Check your journey plan for today.',
                  'Use area filters to cover faster.',
                  'Prioritize nearest routes first.',
                ]
              : const [
                  'آج کا جرنی پلان دیکھیں۔',
                  'جلدی کیلئے ایریا فلٹر استعمال کریں۔',
                  'قریب ترین راستوں کو ترجیح دیں۔',
                ],
        ),
        _OnbData(
          title: l == AppLang.en
              ? 'Visit shops & auto-sync'
              : 'دکانوں پر وزٹ کریں اور آٹو سنک',
          points: l == AppLang.en
              ? const [
                  'Select a shop, Check-in first.',
                  'Place order / collect payment / choose a reason.',
                  'Checkout when done — auto-sync, no manual sync needed.',
                  'Complete journey plan and Sign out.',
                ]
              : const [
                  'دکان منتخب کریں اور پہلے چیک اِن کریں۔',
                  'آرڈر لیں / پیمنٹ لیں / وجہ منتخب کریں۔',
                  'کام مکمل ہو تو چیک آؤٹ — آٹو سنک، دستی سنک کی ضرورت نہیں۔',
                  'جرنی پلان مکمل کریں اور سائن آؤٹ کریں۔',
                ],
        ),
      ];

  void _next() {
    if (index < _pages.length - 1) {
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

  Future<void> _switchLang(AppLang l) async {
    if (_lang == l) return;
    await _prefs.setLang(l);
    setState(() {
      _lang = l;
      _t = _L10nOnb(_lang);
      _pages = _pagesFor(_lang);
      index = 0;
      controller.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isLast = index == _pages.length - 1;

    return Directionality(
      textDirection: _lang.dir,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: cBg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const WatermarkTiledSmall(tileScale: 3.0),

              SafeArea(
                child: Column(
                  children: [
                    // top bar: lang toggle + skip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          _LangToggle(
                            lang: _lang,
                            onChanged: _switchLang,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              foregroundColor: cPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(_t.skip, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),

                    // pages (title + bullets)
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => index = i),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (_, i) {
                          final data = _pages[i];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _HeroGlassHeader(titleBottom: data.title, points: data.points),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),

                    // bottom: dots + CTA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: _BottomGlass(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            _PagerDots(count: _pages.length, index: index),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: _PrimaryButton(
                                label: isLast ? _t.getStarted : _t.next,
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
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                 LOCALIZATION                                */
/* -------------------------------------------------------------------------- */

enum AppLang { en, ur }
extension _AppLangX on AppLang {
  String get code => this == AppLang.en ? 'en' : 'ur';
  TextDirection get dir => this == AppLang.ur ? TextDirection.rtl : TextDirection.ltr;
}

class _OnbPrefs {
  final _box = GetStorage();
  AppLang getLang() {
    final s = (_box.read('onb_lang') as String?) ?? 'en';
    return s == 'ur' ? AppLang.ur : AppLang.en;
  }

  Future<void> setLang(AppLang l) => _box.write('onb_lang', l.code);
}

class _L10nOnb {
  final AppLang lang;
  const _L10nOnb(this.lang);

  String get skip => lang == AppLang.en ? 'Skip' : 'اسکپ';
  String get next => lang == AppLang.en ? 'Next' : 'اگلا';
  String get getStarted => lang == AppLang.en ? 'Get Started' : 'شروع کریں';
}

/* -------------------------------------------------------------------------- */
/*                               VIEW BUILDING BLKS                            */
/* -------------------------------------------------------------------------- */

class _OnbData {
  final String title;
  final List<String> points;
  const _OnbData({required this.title, required this.points});
}

class _HeroGlassHeader extends StatelessWidget {
  const _HeroGlassHeader({required this.titleBottom, required this.points});
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
            boxShadow: const [BoxShadow(color: _OnboardingScreenState.cShadow, blurRadius: 22, offset: Offset(0, 12))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleBottom,
                        style: t.titleMedium?.copyWith(
                          color: _OnboardingScreenState.cText,
                          fontWeight: FontWeight.w900,
                          height: 1.06,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...points.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _OnboardingScreenState.cText)),
                              Expanded(
                                child: Text(
                                  p,
                                  softWrap: true,
                                  style: t.titleSmall?.copyWith(
                                    color: _OnboardingScreenState.cText,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
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
            ],
          ),
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
          backgroundColor: _OnboardingScreenState.cPrimary,
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
            child: Text(label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .2)),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               LANG TOGGLE CHIP                              */
/* -------------------------------------------------------------------------- */

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.lang, required this.onChanged});
  final AppLang lang;
  final ValueChanged<AppLang> onChanged;

  @override
  Widget build(BuildContext context) {
    final selEn = lang == AppLang.en;
    final selUr = lang == AppLang.ur;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _OnboardingScreenState.cStroke),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _segBtn(label: 'EN', selected: selEn, onTap: () => onChanged(AppLang.en)),
        _segBtn(label: 'اردو', selected: selUr, onTap: () => onChanged(AppLang.ur)),
      ]),
    );
  }

  Widget _segBtn({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _OnboardingScreenState.cPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _OnboardingScreenState.cText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   // HomeUpdated / Login theme palette
//   static const cBg = Color(0xFFEEEEEE);
//   static const cSurface = Colors.white;
//   static const cText = Color(0xFF1F2937);
//   static const cMuted = Color(0xFF6B7280);
//   static const cStroke = Color(0xFFE9E9EF);
//   static const cPrimary = Color(0xFFEA7A3B);
//   static const cPrimarySoft = Color(0xFFFFB07A);
//   static const cShadow = Color(0x14000000);

//   final controller = PageController();
//   int index = 0;

//   final pages = [
//     _OnbData(
//       title: 'Mark attendance & start your route',
//       points: [
//         'Mark attendance to clock in.',
//         'Tap Start Route to begin your day.',
//         'Enable location for accurate visit logs.',
//         'Check-in works only after you start your route.',
//         'Today’s journey plan unlocks once you start.',
//         'Shops are grouped by area for faster coverage.',
//         'Weak signal? Actions save offline and auto-sync later.',
//         'Your start time is recorded for the shift.',
//         'Finish your day with End Route.',
//       ],
//     ),
//     _OnbData(
//       title: 'Plan today’s journey by areas',
//       points: [
//         'Check your journey plan for today.',
//         'Use area filters to cover faster.',
//         'Prioritize nearest routes first.',
//       ],
//     ),
//     _OnbData(
//       title: 'Visit shops & auto-sync',
//       points: [
//         'Select a shop to visit and Check-in.',
//         'Place order / collect payment / choose a reason.',
//         'Checkout when done — data auto-syncs, no manual sync needed.',
//         'Complete your journey plan and Sign out.',
//       ],
//     ),
//   ];

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   void _next() {
//     if (index < pages.length - 1) {
//       controller.nextPage(
//         duration: const Duration(milliseconds: 280),
//         curve: Curves.easeOut,
//       );
//     } else {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const NewLoginScreen()),
//         (route) => false,
//       );
//     }
//   }

//   void _skip() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const NewLoginScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final isLast = index == pages.length - 1;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: cBg,
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             // OPTIONAL: watermark only on this screen (must be direct child of Stack)
//             const WatermarkTiledSmall(tileScale: 3.0),

//             SafeArea(
//               child: Column(
//                 children: [
//                   // top bar: skip
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 8),
//                         const Spacer(),
//                         TextButton(
//                           onPressed: _skip,
//                           style: TextButton.styleFrom(
//                             foregroundColor: cPrimary,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                           ),
//                           child: const Text(
//                             'Skip',
//                             style: TextStyle(fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // pages
//                   Expanded(
//                     child: PageView.builder(
//                       controller: controller,
//                       itemCount: pages.length,
//                       onPageChanged: (i) => setState(() => index = i),
//                       physics: const BouncingScrollPhysics(),
//                       itemBuilder: (_, i) {
//                         final data = pages[i];
//                         return Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             _HeroGlassHeader(
//                               titleBottom: data.title,
//                               points: data.points,
//                             ),
//                             const SizedBox(height: 16),
//                           ],
//                         );
//                       },
//                     ),
//                   ),

//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
//                     child: _BottomGlass(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const SizedBox(height: 8),
//                           _PagerDots(count: pages.length, index: index),
//                           const SizedBox(height: 14),
//                           SizedBox(
//                             width: double.infinity,
//                             height: 48,
//                             child: _PrimaryButton(
//                               label: isLast ? 'Get Started' : 'Next',
//                               onPressed: _next,
//                             ),
//                           ),
//                         ],
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
// }

// class _OnbData {
//   final String title;
//   final List<String> points;
//   const _OnbData({required this.title, required this.points});
// }

// class _HeroGlassHeader extends StatelessWidget {
//   const _HeroGlassHeader({required this.titleBottom, required this.points});

//   final String titleBottom;
//   final List<String> points;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(22),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.75),
//             borderRadius: BorderRadius.circular(22),
//             border: Border.all(color: _OnboardingScreenState.cStroke),
//             boxShadow: const [
//               BoxShadow(
//                 color: _OnboardingScreenState.cShadow,
//                 blurRadius: 22,
//                 offset: Offset(0, 12),
//               ),
//             ],
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start, // align with title
//             children: [
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   child: Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start, // <-- left align
//                     children: [
//                       Text(
//                         titleBottom,
//                         style: t.titleMedium?.copyWith(
//                           color: _OnboardingScreenState.cText,
//                           fontWeight: FontWeight.w900,
//                           height: 1.06,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       ...points.map(
//                         (p) => Padding(
//                           padding: const EdgeInsets.only(bottom: 4),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 '• ',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w800,
//                                   color: _OnboardingScreenState.cText,
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   p,
//                                   softWrap: true,
//                                   style: t.titleSmall?.copyWith(
//                                     color: _OnboardingScreenState.cText,
//                                     fontWeight: FontWeight.w400,
//                                     height: 1.15,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
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

// class _BottomGlass extends StatelessWidget {
//   const _BottomGlass({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.90),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: _OnboardingScreenState.cStroke),
//             boxShadow: const [
//               BoxShadow(
//                 color: _OnboardingScreenState.cShadow,
//                 blurRadius: 16,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _PagerDots extends StatelessWidget {
//   const _PagerDots({required this.count, required this.index});
//   final int count;
//   final int index;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(count, (i) {
//         final active = i == index;
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 220),
//           margin: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
//           height: 8,
//           width: active ? 34 : 10,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(999),
//             border: Border.all(color: _OnboardingScreenState.cStroke),
//             color: active
//                 ? _OnboardingScreenState.cPrimary.withOpacity(.85)
//                 : Colors.white.withOpacity(.70),
//             boxShadow: const [
//               BoxShadow(
//                 color: _OnboardingScreenState.cShadow,
//                 blurRadius: 8,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }

// class _PrimaryButton extends StatelessWidget {
//   const _PrimaryButton({required this.label, required this.onPressed});
//   final String label;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.all(Radius.circular(12)),
//         boxShadow: [
//           BoxShadow(
//             color: _OnboardingScreenState.cShadow,
//             blurRadius: 16,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           padding: EdgeInsets.zero,
//           backgroundColor: _OnboardingScreenState.cPrimary, // fallback
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 0,
//         ),
//         onPressed: onPressed,
//         child: Ink(
//           decoration: const BoxDecoration(
//             borderRadius: BorderRadius.all(Radius.circular(12)),
//             gradient: LinearGradient(
//               colors: [
//                 _OnboardingScreenState.cPrimary,
//                 _OnboardingScreenState.cPrimarySoft,
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Container(
//             height: 48,
//             alignment: Alignment.center,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white,
//                 letterSpacing: .2,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
