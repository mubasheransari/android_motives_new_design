import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/widgets/orange_pills_designs.dart';




const kOrange = Color(0xFFEA7A3B);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000); 


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Palette (same family as your app)
  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kText   = Color(0xFF1E1E1E);
  static const Color kMuted  = Color(0xFF707883);
  static const Color kField  = Color(0xFFF4F5F7); // <- like NewLoginScreen
  static const Color kCard   = Colors.white;

  // MOTIVES background controls
  static const double kBgOpacity = 0.08;
  static const double kTileScale = 2.8;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'PROFILE DETAILS'));
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  // === Field decoration exactly like NewLoginScreen ===
  InputDecoration _loginFieldDec({
    required String hint,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // same radius
      borderSide: const BorderSide(color: Colors.transparent),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: kField,
      hintText: hint,
      hintStyle: const TextStyle(color: kMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border,
      focusedBorder: border,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = context.read<GlobalBloc>().state;
    final login = state.loginModel!;

    final name   = login.userinfo!.userName?.toString() ?? '';
    final email  = login.userinfo!.email?.toString() ?? '';
    final dist   = _titleCase(login.userinfo!.distributionName?.toString() ?? '');
    final phone  = login.userinfo!.phone?.toString() ?? '';
    final logInT = '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}';

    return Scaffold(
      backgroundColor: Colors.white,
 
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ── MOTIVES tiled watermark background ──
            Positioned.fill(
              child: Opacity(
                opacity: kBgOpacity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade300,
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    'assets/logo-bg.png',
                    repeat: ImageRepeat.repeat,
                    scale: kTileScale,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),

            // ── Content ──
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Gradient header + glass card (like Routes)
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 100,
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Profile',
                                        style: t.titleLarge?.copyWith(
                                          color: Colors.white.withOpacity(.95),
                                          fontWeight: FontWeight.w700,
                                        )),
                                    // Text(
                                    //   name,
                                    //   overflow: TextOverflow.ellipsis,
                                    //   style: t.headlineSmall?.copyWith(
                                    //     color: Colors.white,
                                    //     fontWeight: FontWeight.w800,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                              //Image.asset('assets/logo-bg.png', height: 46, width: 100, fit: BoxFit.contain),
                            ],
                          ),
                        ),
                      ),
                      // Positioned(
                      //   top: 115,
                      //   left: 20,
                      //   child: _StatusPill(
                      //     icon: Icons.access_time,
                      //     label: logInT,
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // Fields styled like NewLoginScreen
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: name,
                            decoration: _loginFieldDec(
                              hint: 'Name',
                              suffixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 18),

                          const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _loginFieldDec(
                              hint: 'Email',
                              suffixIcon: const Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 18),

                          const Text('Distributor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: dist,
                            decoration: _loginFieldDec(
                              hint: 'Distributor',
                              suffixIcon: const Icon(Icons.apartment_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),

                          const Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: phone,
                            decoration: _loginFieldDec(
                              hint: 'Phone Number',
                              suffixIcon: const Icon(Icons.call_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Helpers reused from your theme =====

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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Text(label, style: t.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: .3)),
      ]),
    );
  }
}



/*class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kText   = Color(0xFF1E1E1E);
  static const Color kMuted  = Color(0xFF707883);
  static const Color kField  = Color(0xFFF5F5F7);
  static const Color kCard   = Colors.white;
  static const Color kShadow = Color(0x14000000);

  // Background tiling controls
  static const double kBgOpacity = 0.08;  // 0.05–0.12
  static const double kTileScale = 2.8;   // ↑ scale = smaller tiles

  final _formKey = GlobalKey<FormState>();

  // Nice, consistent decoration for read-only fields
  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted),
        filled: true,
        fillColor: kCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDEFF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kOrange, width: 1.6),
        ),
      );

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'PROFILE DETAILS'));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = context.read<GlobalBloc>().state;
    final login = state.loginModel!;

    final name   = login.userinfo!.userName?.toString() ?? '';
    final email  = login.userinfo!.email?.toString() ?? '';
    final dist   = _titleCase(login.userinfo!.distributionName?.toString() ?? '');
    final phone  = login.userinfo!.phone?.toString() ?? '';
    final logInT = '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}';

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   centerTitle: false,
      //   title: Text(
      //     'Profile',
      //     style: t.titleLarge?.copyWith(
      //       color: kText,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ====== MOTIVES repeating watermark background ======
            Positioned.fill(
              child: Opacity(
                opacity: kBgOpacity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade300,
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    'assets/logo-bg.png',
                    repeat: ImageRepeat.repeat,
                    scale: kTileScale,                 // make chunks small
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),

            // ====== Content ======
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Themed gradient hero + glass header (like Routes)
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 120,
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Profile',
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.95),
                                          fontWeight: FontWeight.w700,
                                        )),
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Optional: your logo preview
                              Image.asset(
                                'assets/logo-bg.png',
                                height: 46,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                 
                    ],
                  ),
                ),

                // Form fields area
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _FieldLabel('Name', t),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: name,
                            decoration: _dec('Abc Test'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel('Email', t),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('abctest@example.com'),
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel('Distributor', t),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: dist,
                            decoration: _dec('Distributor name'),
                          ),
                          const SizedBox(height: 14),

                          _FieldLabel('Phone Number', t),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            initialValue: phone,
                            decoration: _dec('0300 0000000'),
                          ),

                          const SizedBox(height: 28),

                          // Card with quick info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: kShadow,
                                  blurRadius: 16,
                                  offset: Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color:
                                    const Color(0xFFFFB07A).withOpacity(.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: kField,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.info_outline,
                                      color: kOrange),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'These details are synced from your account. Contact support to update.',
                                    style: t.bodyMedium
                                        ?.copyWith(color: kMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper for left labels
Widget _FieldLabel(String label, TextTheme t) => Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: t.titleMedium?.copyWith(color: _ProfileLabel.k)),
    );

// isolate label color to avoid capturing outer const
class _ProfileLabel {
  static const k = Color(0xFF1E1E1E);
}

// Glass header reused
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

// Status pill like your other screens
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
          Icon(icon, size: 16, color: Colors.white),
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
}*/


// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {

//   @override
//   void initState() {
//     super.initState();
//         context.read<GlobalBloc>().add(Activity(activity: 'PROFILE DETAILS'));

//   }
//   final _formKey = GlobalKey<FormState>();
//   final _name = TextEditingController(text: '');
//   final _email = TextEditingController(text: '');
//   String? _distributor;

  

//   @override
//   void dispose() {
//     _name.dispose();
//     _email.dispose();
//     super.dispose();
//   }

//   InputDecoration _dec(String hint) => InputDecoration(
//     hintText: hint,
//     hintStyle: const TextStyle(color: kMuted),
//     filled: true,
//     fillColor: kCard,
//     contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(16),
//       borderSide: const BorderSide(color: Colors.orange, width: 1.6),
//     ),
//     // enabledBorder: OutlineInputBorder(
//     //   borderRadius: BorderRadius.circular(16),
//     //   borderSide: const BorderSide(color: Color(0xFFEDEFF2)),
//     // ),
//     // focusedBorder: OutlineInputBorder(
//     //   borderRadius: BorderRadius.circular(16),
//     //   borderSide: const BorderSide(color: kOrange, width: 1.6),
//     // ),
//   );

//   @override
//   Widget build(BuildContext context) {


//     final t = Theme.of(context).textTheme;

//     String formatTitleCase(String text) {
//       if (text.isEmpty) return text;

//       return text
//           .toLowerCase()
//           .split(' ')
//           .map(
//             (word) => word.isNotEmpty
//                 ? '${word[0].toUpperCase()}${word.substring(1)}'
//                 : '',
//           )
//           .join(' ');
//     }

//     return Scaffold(
//           backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: false,
//         title: Text(
//           'Profile',
//           style: t.titleLarge?.copyWith(
//             color: Color(0xFF1E1E1E),
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [


//           /*  SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Text(
//                     //   'PROFILE',
//                     //   style: t.labelLarge?.copyWith(
//                     //     letterSpacing: 1.4,
//                     //     color: kText,
//                     //   ),
//                     // ),
//                     // const SizedBox(height: 6),
//                     // Container(
//                     //   width: 64,
//                     //   height: 4,
//                     //   decoration: BoxDecoration(
//                     //     color: kOrange.withOpacity(.9),
//                     //     borderRadius: BorderRadius.circular(8),
//                     //   ),
//                     // ),
//                     const SizedBox(height: 18),
//                     Row(
//                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back)),
//                         Text(
//                           'Your Profile',
//                           style: TextStyle(fontSize: 20,fontWeight: FontWeight.w500)
//                         ),
//                         SizedBox(width: MediaQuery.of(context).size.width *0.17),
//                         OrangePills(),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),*/

//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(
//                   20,
//                   4,
//                   20,
//                   140,
//                 ), // leave space for sticky button
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       // Name
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Name',
//                           style: t.titleMedium?.copyWith(color: kText),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         readOnly: true,
//                         initialValue: context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .userinfo!
//                             .userName
//                             .toString(),
//                         //  controller: _name,
//                         decoration: _dec('Abc Test'),
//                         validator: (v) => (v == null || v.trim().isEmpty)
//                             ? 'Please enter your name'
//                             : null,
//                       ),
//                       const SizedBox(height: 14),

//                       // Email
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Email',
//                           style: t.titleMedium?.copyWith(color: kText),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         readOnly: true,
//                         initialValue: context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .userinfo!
//                             .email
//                             .toString(),

//                         //   controller: _email,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: _dec('abctest@example.com'),
//                         // validator: (v) {
//                         //   if (v == null || v.trim().isEmpty)
//                         //     return 'Please enter your email';
//                         //   final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
//                         //       .hasMatch(v.trim());
//                         //   return ok ? null : 'Enter a valid email';
//                         // },
//                       ),
//                       const SizedBox(height: 14),

//                       // Distributor
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Distributor',
//                           style: t.titleMedium?.copyWith(color: kText),
//                         ),
//                       ),

//                       const SizedBox(height: 8),
//                       TextFormField(
//                         readOnly: true,
//                         initialValue: formatTitleCase(
//                           context
//                               .read<GlobalBloc>()
//                               .state
//                               .loginModel!
//                               .userinfo!
//                               .distributionName
//                               .toString(),
//                         ), // context.read<GlobalBloc>().state.loginModel!.userinfo!.email.toString(),
//                         //  controller: _name,
//                         decoration: _dec('Abc Test'),
//                         validator: (v) => (v == null || v.trim().isEmpty)
//                             ? 'Please enter your name'
//                             : null,
//                       ),

//                       const SizedBox(height: 14),

//                       // Distributor
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Phone Number',
//                           style: t.titleMedium?.copyWith(color: kText),
//                         ),
//                       ),

//                       const SizedBox(height: 8),
//                       TextFormField(
//                         readOnly: true,
//                         initialValue: context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .userinfo!
//                             .phone
//                             .toString(),
//                         //  controller: _name,
//                         decoration: _dec('Abc Test'),
//                         validator: (v) => (v == null || v.trim().isEmpty)
//                             ? 'Please enter your name'
//                             : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
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