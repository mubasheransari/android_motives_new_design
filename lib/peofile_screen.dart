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

  @override
  void initState() {
    super.initState();
        context.read<GlobalBloc>().add(Activity(activity: 'PROFILE DETAILS'));

  }
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: '');
  final _email = TextEditingController(text: '');
  String? _distributor;

  

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kMuted),
    filled: true,
    fillColor: kCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.orange, width: 1.6),
    ),
    // enabledBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(16),
    //   borderSide: const BorderSide(color: Color(0xFFEDEFF2)),
    // ),
    // focusedBorder: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(16),
    //   borderSide: const BorderSide(color: kOrange, width: 1.6),
    // ),
  );

  @override
  Widget build(BuildContext context) {


    final t = Theme.of(context).textTheme;

    String formatTitleCase(String text) {
      if (text.isEmpty) return text;

      return text
          .toLowerCase()
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '',
          )
          .join(' ');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE',
                      style: t.labelLarge?.copyWith(
                        letterSpacing: 1.4,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Profile',
                          style: t.headlineSmall?.copyWith(
                            height: 1.1,
                            color: kText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        OrangePills(),
                      ],
                    ),
                    // const SizedBox(height: 6),
                    // Text('Personal Information',
                    //     style: t.bodyMedium?.copyWith(color: kMuted)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  140,
                ), // leave space for sticky button
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Name',
                          style: t.titleMedium?.copyWith(color: kText),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        initialValue: context
                            .read<GlobalBloc>()
                            .state
                            .loginModel!
                            .userinfo!
                            .userName
                            .toString(),
                        //  controller: _name,
                        decoration: _dec('Abc Test'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email',
                          style: t.titleMedium?.copyWith(color: kText),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        initialValue: context
                            .read<GlobalBloc>()
                            .state
                            .loginModel!
                            .userinfo!
                            .email
                            .toString(),

                        //   controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _dec('abctest@example.com'),
                        // validator: (v) {
                        //   if (v == null || v.trim().isEmpty)
                        //     return 'Please enter your email';
                        //   final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        //       .hasMatch(v.trim());
                        //   return ok ? null : 'Enter a valid email';
                        // },
                      ),
                      const SizedBox(height: 14),

                      // Distributor
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Distributor',
                          style: t.titleMedium?.copyWith(color: kText),
                        ),
                      ),

                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        initialValue: formatTitleCase(
                          context
                              .read<GlobalBloc>()
                              .state
                              .loginModel!
                              .userinfo!
                              .distributionName
                              .toString(),
                        ), // context.read<GlobalBloc>().state.loginModel!.userinfo!.email.toString(),
                        //  controller: _name,
                        decoration: _dec('Abc Test'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      // Distributor
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number',
                          style: t.titleMedium?.copyWith(color: kText),
                        ),
                      ),

                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        initialValue: context
                            .read<GlobalBloc>()
                            .state
                            .loginModel!
                            .userinfo!
                            .phone
                            .toString(),
                        //  controller: _name,
                        decoration: _dec('Abc Test'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                    ],
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