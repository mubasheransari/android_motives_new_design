import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/Constants/constants.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  // HomeUpdated palette
  static const cBg = Color(0xFFEEEEEE);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);

  bool rememberMe = true;
  bool obscure = true;
  final box = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  OutlineInputBorder _border([Color c = Colors.transparent]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  InputDecoration _inputDec({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintText: hint,
      hintStyle: const TextStyle(color: cMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      enabledBorder: _border(Colors.transparent),
      focusedBorder: _border(cStroke),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
    backgroundColor: Colors.white, 
        body: Stack(
           fit: StackFit.expand,   
          children: [
  const WatermarkTiledSmall(tileScale: 3.0),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
               padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Glassy hero header (no orange pills)
                    _HeroGlassHeader(
                      titleBottom: 'Welcome back',
                      right: const _LogoOrBadge(),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Hello there, sign in to continue!',
                      style: t.bodyMedium?.copyWith(color: cMuted),
                    ),
                    const SizedBox(height: 16),

                    // Glass form card
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email',
                              style: t.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cText,
                              )),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDec(
                              hint: 'Email',
                              prefix: const Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Password',
                              style: t.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cText,
                              )),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscure,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDec(
                              hint: 'Password',
                              prefix: const Icon(Icons.lock_outline),
                              suffix: IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Same Bloc + onPressed logic — only UI changed
                    BlocConsumer<GlobalBloc, GlobalState>(
                      listener: (context, state) {
                        if (state.status == LoginStatus.success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeUpdated()),
                          );
                          toastWidget("✅ Authenticated Successfully!", Colors.green);

                          box.write("email", emailController.text.trim());
                          box.write("password", passwordController.text.trim());
                          box.write('isLoggedIn', true);
                        } else if (state.status == LoginStatus.failure) {
                          toastWidget("Incorrect Email or Password", Colors.red);
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state.status == LoginStatus.loading;
                        return Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.40,
                            height: 48,
                            child: isLoading
                                ? const Center(
                                    child: SpinKitWave(
                                      color: cPrimary,
                                      size: 30.0,
                                      duration: Duration(milliseconds: 1500),
                                    ),
                                  )
                                : Center(
                                    child: _PrimaryButton(
                                      label: 'Login',
                                      onPressed: () async {
                                        FocusScope.of(context).unfocus();
                                        final email = emailController.text.trim();
                                        final password = passwordController.text.trim();
                                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                                        if (email.isEmpty || password.isEmpty) {
                                          toastWidget("Please Enter Complete Form Data!", Colors.red);
                                          return;
                                        } else if (!emailRegex.hasMatch(email)) {
                                          toastWidget("Please Enter Valid Email Address", Colors.red);
                                          return;
                                        } else {
                                          context.read<GlobalBloc>().add(
                                                LoginEvent(email: email, password: password),
                                              );
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _HeroGlassHeader extends StatelessWidget {
  const _HeroGlassHeader({
    required this.titleBottom,
    required this.right,
  });

  final String titleBottom;
  final Widget right;

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
            border: Border.all(color: _NewLoginScreenState.cStroke),
            boxShadow: const [
              BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 22, offset: Offset(0, 12)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // mini badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _NewLoginScreenState.cStroke),
                  boxShadow: const [
                    BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.person, color: _NewLoginScreenState.cPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    titleBottom,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall?.copyWith(
                      color: _NewLoginScreenState.cText,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
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

class _LogoOrBadge extends StatelessWidget {
  const _LogoOrBadge();

  @override
  Widget build(BuildContext context) {
    // Replace with Image.asset('assets/logo-bg.png', ...) if you want
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _NewLoginScreenState.cStroke),
        boxShadow: const [
          BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: const Icon(Icons.lock_person_rounded, color: _NewLoginScreenState.cPrimary, size: 30),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _NewLoginScreenState.cStroke),
            boxShadow: const [
              BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 16, offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}




class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: _NewLoginScreenState.cPrimary, // fallback
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          color: _NewLoginScreenState.cPrimary
          // gradient: LinearGradient(
          //   colors: [_NewLoginScreenState.cPrimary, _NewLoginScreenState.cPrimarySoft],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
        ),
        child: Container(
          height: 42,
          width: 110,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}


// keep your own imports for GlobalBloc, LoginEvent, HomeUpdated, toastWidget, etc.

// class NewLoginScreen extends StatefulWidget {
//   const NewLoginScreen({super.key});

//   @override
//   State<NewLoginScreen> createState() => _NewLoginScreenState();
// }

// class _NewLoginScreenState extends State<NewLoginScreen> {
//   // HomeUpdated palette
//   static const cBg = Color(0xFFEEEEEE);
//   static const cSurface = Colors.white;
//   static const cText = Color(0xFF1F2937);
//   static const cMuted = Color(0xFF6B7280);
//   static const cStroke = Color(0xFFE9E9EF);
//   static const cPrimary = Color(0xFFEA7A3B);
//   static const cPrimarySoft = Color(0xFFFFB07A);
//   static const cShadow = Color(0x14000000);

//   bool rememberMe = true;
//   bool obscure = true;
//   final box = GetStorage();

//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

//   OutlineInputBorder _border([Color c = Colors.transparent]) => OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: c),
//       );

//   InputDecoration _inputDec({
//     required String hint,
//     Widget? prefix,
//     Widget? suffix,
//   }) {
//     return InputDecoration(
//       isDense: true,
//       filled: true,
//       fillColor: const Color(0xFFF5F6F8),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//       hintText: hint,
//       hintStyle: const TextStyle(color: cMuted),
//       prefixIcon: prefix,
//       suffixIcon: suffix,
//       enabledBorder: _border(Colors.transparent),
//       focusedBorder: _border(cStroke),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: cBg,
//         body: SafeArea(
//           child: SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title + underline
//                 // Text(
//                 //   'LOGIN',
//                 //   style: t.titleMedium?.copyWith(
//                 //     fontSize: 18,
//                 //     fontWeight: FontWeight.w800,
//                 //     color: cText,
//                 //     letterSpacing: .2,
//                 //   ),
//                 // ),
//                 // const SizedBox(height: 6),
//                 // Container(
//                 //   height: 3,
//                 //   width: 60,
//                 //   decoration: BoxDecoration(
//                 //     color: cPrimary,
//                 //     borderRadius: BorderRadius.circular(2),
//                 //   ),
//                 // ),

//                 const SizedBox(height: 10),

//                 // Glassy hero header (no orange pills)
//                 _HeroGlassHeader(
//                   titleBottom: 'Welcome back',
//                   right: const _LogoOrBadge(),
//                 ),

//                 const SizedBox(height: 18),
//                 Text(
//                   'Hello there, sign in to continue!',
//                   style: t.bodyMedium?.copyWith(color: cMuted),
//                 ),
//                 const SizedBox(height: 16),

//                 // Glass form card
//                 _GlassCard(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Email',
//                           style: t.labelLarge?.copyWith(
//                             fontWeight: FontWeight.w700,
//                             color: cText,
//                           )),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         textInputAction: TextInputAction.next,
//                         decoration: _inputDec(
//                           hint: 'Email',
//                           prefix: const Icon(Icons.mail_outline),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text('Password',
//                           style: t.labelLarge?.copyWith(
//                             fontWeight: FontWeight.w700,
//                             color: cText,
//                           )),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: passwordController,
//                         obscureText: obscure,
//                         textInputAction: TextInputAction.done,
//                         decoration: _inputDec(
//                           hint: 'Password',
//                           prefix: const Icon(Icons.lock_outline),
//                           suffix: IconButton(
//                             onPressed: () => setState(() => obscure = !obscure),
//                             icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
                    
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 // Same Bloc + onPressed logic — only UI changed
//                 BlocConsumer<GlobalBloc, GlobalState>(
//                   listener: (context, state) {
//                     if (state.status == LoginStatus.success) {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => const HomeUpdated()),
//                       );
//                       toastWidget("✅ Authenticated Successfully!", Colors.green);

//                       box.write("email", emailController.text.trim());
//                       box.write("password", passwordController.text.trim());
//                       box.write('isLoggedIn', true);
//                     } else if (state.status == LoginStatus.failure) {
//                       toastWidget("Incorrect Email or Password", Colors.red);
//                     }
//                   },
//                   builder: (context, state) {
//                     final isLoading = state.status == LoginStatus.loading;
//                     return Center(
//                       child: SizedBox(
//                         width: MediaQuery.of(context).size.width *0.40,
//                         height: 48,
//                         child: isLoading
//                             ? const Center(
//                                 child: SpinKitWave(
//                                   color: cPrimary,
//                                   size: 30.0,
//                                   duration: Duration(milliseconds: 1500),
//                                 ),
//                               )
//                             : Center(
//                               child: _PrimaryButton(
//                                   label: 'Login',
//                                   onPressed: () async {
//                                     FocusScope.of(context).unfocus();
//                                     final email = emailController.text.trim();
//                                     final password = passwordController.text.trim();
//                                     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              
//                                     if (email.isEmpty || password.isEmpty) {
//                                       toastWidget("Please Enter Complete Form Data!", Colors.red);
//                                       return;
//                                     } else if (!emailRegex.hasMatch(email)) {
//                                       toastWidget("Please Enter Valid Email Address", Colors.red);
//                                       return;
//                                     } else {
//                                       // unchanged: dispatch your event
//                                       context.read<GlobalBloc>().add(
//                                             LoginEvent(email: email, password: password),
//                                           );
//                                     }
//                                   },
//                                 ),
//                             ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ---------- UI helpers (purely visual) ---------- */

// class _HeroGlassHeader extends StatelessWidget {
//   const _HeroGlassHeader({
//     required this.titleBottom,
//     required this.right,
//   });

//   final String titleBottom;
//   final Widget right;

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
//             border: Border.all(color: _NewLoginScreenState.cStroke),
//             boxShadow: const [
//               BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 22, offset: Offset(0, 12)),
//             ],
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // mini badge
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: _NewLoginScreenState.cStroke),
//                   boxShadow: const [
//                     BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 12, offset: Offset(0, 6)),
//                   ],
//                 ),
//                 child: const Icon(Icons.person, color: _NewLoginScreenState.cPrimary),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   child: Text(
//                     titleBottom,
//                     overflow: TextOverflow.ellipsis,
//                     style: t.headlineSmall?.copyWith(
//                       color: _NewLoginScreenState.cText,
//                       fontWeight: FontWeight.w900,
//                       height: 1.06,
//                     ),
//                   ),
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

// class _LogoOrBadge extends StatelessWidget {
//   const _LogoOrBadge();

//   @override
//   Widget build(BuildContext context) {
//     // Replace with Image.asset('assets/logo-bg.png', ...) if you want
//     return Container(
//       width: 64,
//       height: 64,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//         border: Border.all(color: _NewLoginScreenState.cStroke),
//         boxShadow: const [
//           BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 12, offset: Offset(0, 6)),
//         ],
//       ),
//       child: const Icon(Icons.lock_person_rounded, color: _NewLoginScreenState.cPrimary, size: 30),
//     );
//   }
// }

// class _GlassCard extends StatelessWidget {
//   const _GlassCard({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.88),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: _NewLoginScreenState.cStroke),
//             boxShadow: const [
//               BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 16, offset: Offset(0, 10)),
//             ],
//           ),
//           child: child,
//         ),
//       ),
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
//         boxShadow: [BoxShadow(color: _NewLoginScreenState.cShadow, blurRadius: 16, offset: Offset(0, 10))],
//       ),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           padding: EdgeInsets.zero,
//           backgroundColor: _NewLoginScreenState.cPrimary, // fallback
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: 0,
//         ),
//         onPressed: onPressed,
//         child: Ink(
         
//           decoration:  BoxDecoration(
//             borderRadius: BorderRadius.all(Radius.circular(12)),
//              color: _NewLoginScreenState.cPrimary,
//             // gradient: LinearGradient(
//             //   colors: [_NewLoginScreenState.cPrimary, _NewLoginScreenState.cPrimarySoft],
//             //   begin: Alignment.topLeft,
//             //   end: Alignment.bottomRight,
//             // ),
//           ),
//           child: Container(
//             height: 48,
//             alignment: Alignment.center,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 17.5,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//                 letterSpacing: .5,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// class NewLoginScreen extends StatefulWidget {
//   const NewLoginScreen({super.key});

//   @override
//   State<NewLoginScreen> createState() => _NewLoginScreenState();
// }

// class _NewLoginScreenState extends State<NewLoginScreen> {
//   bool rememberMe = true;
//   bool obscure = true;
//   final box = GetStorage();

//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     const accent = Color(0xFFE97C42);
//     final border = OutlineInputBorder(
//       borderRadius: BorderRadius.circular(10),
//       borderSide: const BorderSide(color: Colors.transparent),
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Login'.toUpperCase(),
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                   ),
//                   SizedBox(height: 4),
//                   SizedBox(
//                     width: 60,
//                     height: 3,
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                         color: accent,
//                         borderRadius: BorderRadius.all(Radius.circular(2)),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 22),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Welcome Back,',
//                           style: Theme.of(context).textTheme.headlineMedium,
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           'Hello there, sign in to continue!',
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const _DecorShapes(),
//                 ],
//               ),
//               const SizedBox(height: 28),
//               const Text(
//                 'Email',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: InputDecoration(
//                   isDense: true,
//                   filled: true,
//                   fillColor: const Color(0xFFF4F5F7),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 16,
//                   ),
//                   suffixIcon: const Icon(Icons.mail_outline),
//                   enabledBorder: border,
//                   focusedBorder: border,
//                   hintText: 'Email',
//                 ),
//               ),
//               const SizedBox(height: 18),
//               // Password
//               const Text(
//                 'Password',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: passwordController,

//                 //   initialValue: '********',
//                 obscureText: obscure,
//                 decoration: InputDecoration(
//                   hintText: 'Password',
//                   isDense: true,
//                   filled: true,
//                   fillColor: const Color(0xFFF4F5F7),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 16,
//                   ),
//                   suffixIcon: IconButton(
//                     onPressed: () => setState(() => obscure = !obscure),
//                     icon: Icon(
//                       obscure ? Icons.visibility_off : Icons.visibility,
//                     ),
//                   ),
//                   enabledBorder: border,
//                   focusedBorder: border,
//                 ),
//               ),

//               const SizedBox(height: 22),

//               BlocConsumer<GlobalBloc, GlobalState>(
//                 listener: (context, state) {
//                   if (state.status == LoginStatus.success) {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (context) => HomeUpdated()),
//                     );
//                     toastWidget("✅ Authenticated Successfully!", Colors.green);

//                     box.write("email", emailController.text.trim());
//                     box.write("password", passwordController.text.trim());

//                     box.write('isLoggedIn', true);
//                   } else if (state.status == LoginStatus.failure) {
//                     toastWidget("Incorrect Email or Password", Colors.red);
//                   }
//                 },
//                 builder: (context, state) {
//                   return Center(
//                     child: state.status == LoginStatus.loading
//                         ? SpinKitWave(
//                             color: Color(0xFFEA7A3B),
//                             size: 30.0,
//                             duration: Duration(milliseconds: 1500),
//                           )
//                         : SizedBox(
//                             width: MediaQuery.of(context).size.width * 0.35,
//                             height: 40,
//                             child: FilledButton(
//                               style: FilledButton.styleFrom(
//                                 backgroundColor: accent,
//                                 //  padding: const EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(9),
//                                 ),
//                               ),
//                               onPressed: state.status == LoginStatus.loading
//                                   ? null
//                                   : () async {
//                                       FocusScope.of(context).unfocus();
//                                       final email = emailController.text.trim();
//                                       final password = passwordController.text
//                                           .trim();
//                                       final emailRegex = RegExp(
//                                         r'^[^@]+@[^@]+\.[^@]+',
//                                       );

//                                       print("EMAIL ::: $email");
//                                       print("PASSWORD ::: $password");

//                                       if (email.isEmpty || password.isEmpty) {
//                                         toastWidget(
//                                           "Please Enter Complete Form Data!",
//                                           Colors.red,
//                                         );
//                                         return;
//                                       } else if (!emailRegex.hasMatch(email)) {
//                                         toastWidget(
//                                           "Please Enter Valid Email Address",
//                                           Colors.red,
//                                         );
//                                       } else {
//                                         context.read<GlobalBloc>().add(
//                                           LoginEvent(
//                                             email: email,
//                                             password: password,
//                                           ),
//                                         );
//                                       }
//                                     },

//                               child: Center(
//                                 child: Text(
//                                   'Login',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w700,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CircleIcon extends StatelessWidget {
//   final Widget child;
//   final VoidCallback onTap;
//   const _CircleIcon({required this.child, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return InkResponse(
//       onTap: onTap,
//       radius: 28,
//       child: Container(
//         width: 58,
//         height: 58,
//         decoration: BoxDecoration(
//           color: const Color(0xFFEFEFEF),
//           shape: BoxShape.circle,
//           boxShadow: const [
//             BoxShadow(
//               blurRadius: 4,
//               offset: Offset(0, 1),
//               color: Color(0x11000000),
//             ),
//           ],
//         ),
//         alignment: Alignment.center,
//         child: child,
//       ),
//     );
//   }
// }

// /// Top-right decorative peach angled rectangles to match the mock.
// /// Pure Flutter, no assets.
// class _DecorShapes extends StatelessWidget {
//   const _DecorShapes();

//   @override
//   Widget build(BuildContext context) {
//     const light = Color(0xFFFFE1D2);
//     const mid = Color(0xFFF6B79C);
//     const dark = Color(0xFFE97C42);

//     Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
//       return Transform.rotate(
//         angle: angle, // ~34°
//         child: Container(
//           width: w,
//           height: h,
//           decoration: BoxDecoration(
//             color: c,
//             borderRadius: BorderRadius.circular(6),
//           ),
//         ),
//       );
//     }

//     return SizedBox(
//       width: 110,
//       height: 90,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(right: -6, top: 0, child: block(light)),
//           Positioned(right: 6, top: 22, child: block(mid, w: 78)),
//           Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
//         ],
//       ),
//     );
//   }
// }
