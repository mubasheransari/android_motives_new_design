import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  bool rememberMe = true;
  bool obscure = true;
  final box = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE97C42);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login'.toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hello there, sign in to continue!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const _DecorShapes(),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Email',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  suffixIcon: const Icon(Icons.mail_outline),
                  enabledBorder: border,
                  focusedBorder: border,
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 18),
              // Password
              const Text(
                'Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,

                //   initialValue: '********',
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  enabledBorder: border,
                  focusedBorder: border,
                ),
              ),

              const SizedBox(height: 22),

              BlocConsumer<GlobalBloc, GlobalState>(
                listener: (context, state) {
                  if (state.status == LoginStatus.success) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeUpdated()),
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
                  return Center(
                    child: state.status == LoginStatus.loading
                        ? SpinKitWave(
                            color: Color(0xFFEA7A3B),
                            size: 30.0,
                            duration: Duration(milliseconds: 1500),
                          )
                        : SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: 40,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                //  padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              onPressed: state.status == LoginStatus.loading
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();
                                      final email = emailController.text.trim();
                                      final password = passwordController.text
                                          .trim();
                                      final emailRegex = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      );

                                      print("EMAIL ::: $email");
                                      print("PASSWORD ::: $password");

                                      if (email.isEmpty || password.isEmpty) {
                                        toastWidget(
                                          "Please Enter Complete Form Data!",
                                          Colors.red,
                                        );
                                        return;
                                      } else if (!emailRegex.hasMatch(email)) {
                                        toastWidget(
                                          "Please Enter Valid Email Address",
                                          Colors.red,
                                        );
                                      } else {
                                        context.read<GlobalBloc>().add(
                                          LoginEvent(
                                            email: email,
                                            password: password,
                                          ),
                                        );
                                      }
                                    },

                              child: Center(
                                child: Text(
                                  'Login',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
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
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _CircleIcon({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 1),
              color: Color(0x11000000),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Top-right decorative peach angled rectangles to match the mock.
/// Pure Flutter, no assets.
class _DecorShapes extends StatelessWidget {
  const _DecorShapes();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFFFE1D2);
    const mid = Color(0xFFF6B79C);
    const dark = Color(0xFFE97C42);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle, // ~34°
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -6, top: 0, child: block(light)),
          Positioned(right: 6, top: 22, child: block(mid, w: 78)),
          Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
        ],
      ),
    );
  }
}
