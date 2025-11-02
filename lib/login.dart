import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';
import 'dart:ui';
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
      child: Scaffold(resizeToAvoidBottomInset: true,
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
                    BlocConsumer<GlobalBloc, GlobalState>(
  listener: (context, state) {
    if (state.status == LoginStatus.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeUpdated()),
        (route) => false,
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
    final t = Theme.of(context).textTheme;

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.42,
        height: 45,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _NewLoginScreenState.cPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isLoading
              ? null
              : () {
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
                  }

                  context.read<GlobalBloc>().add(
                        LoginEvent(email: email, password: password),
                      );
                },
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Login'.toUpperCase(),
                  style: TextStyle(fontSize: 18,color: Colors.white,fontWeight: FontWeight.bold)
                ),
        ),
      ),
    );
  },
),


                    // Same Bloc + onPressed logic — only UI changed
                   /* BlocConsumer<GlobalBloc, GlobalState>(
                      listener: (context, state) {
                        if (state.status == LoginStatus.success) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeUpdated()),(route) => false,
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
                    ),*/
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
