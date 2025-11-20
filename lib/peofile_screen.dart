import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/widgets/orange_pills_designs.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';
import 'package:provider/provider.dart';


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// === Brand Palette (same family as your app) ===
const kOrange = Color(0xFFEA7A3B);
const kOrangeSoft = Color(0xFFFFB07A);
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
  // watermark controls
  static const double _bgOpacity = 0.08;
  static const double _tileScale = 2.8;

  @override
  void initState() {
    super.initState();
    context.read<GlobalBloc>().add(Activity(activity: 'Profile Details'));
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final login = context.read<GlobalBloc>().state.loginModel!;

    final name  = login.userinfo?.userName?.toString() ?? '';
    final email = login.userinfo?.email?.toString() ?? '';
    final dist  = _titleCase(login.userinfo?.distributionName?.toString() ?? '');
    final phone = login.userinfo?.phone?.toString() ?? '';
    final logInT = '${login.log?.tim ?? ''} , ${login.log?.time ?? ''}';

    return Scaffold(
   //   backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // === Watermark tiled background ===
            Positioned.fill(
              child: Opacity(
                opacity: _bgOpacity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade300,
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    'assets/logo-bg.png',
                    repeat: ImageRepeat.repeat,
                    scale: _tileScale,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),

            // === Content ===
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero header (gradient + glass)
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                       WatermarkTiledSmall(tileScale: 3.0),
                      Container(
                        height: 100,
                        color: Colors.white.withOpacity(0.50),
                      //   decoration: const BoxDecoration(
                      //     gradient: LinearGradient(
                      //       colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
                      //       begin: Alignment.topLeft,
                      //       end: Alignment.bottomRight,
                      //     ),
                      //  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _GlassBlock(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [kOrange, kOrangeSoft],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Profile',
                                        style: t.titleLarge?.copyWith(
                                          color: kText,
                                          fontWeight: FontWeight.w800,
                                        )),
                                    const SizedBox(height: 2),
                                    Text(
                                      name.isEmpty ? '—' : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.titleMedium?.copyWith(
                                        color: kMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: _GlassBlock(
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.person_outline, label: 'Name', value: name),
                          const _RowDivider(),
                          _InfoRow(icon: Icons.mail_outline, label: 'Email', value: email),
                          const _RowDivider(),
                          _InfoRow(icon: Icons.apartment_outlined, label: 'Distributor', value: dist),
                          const _RowDivider(),
                          _InfoRow(icon: Icons.call_outlined, label: 'Phone Number', value: phone),
                        ],
                      ),
                    ),
                  ),
                ),

                // Last login (full-width glass)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    child: _GlassBlock(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kField,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.access_time, color: kOrange),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Last Login',
                                    style: t.titleMedium?.copyWith(
                                      color: kText,
                                      fontWeight: FontWeight.w800,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  logInT.isEmpty ? 'No login record' : logInT,
                                  style: t.bodyMedium?.copyWith(
                                    color: kMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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

// === Reusable full-width glass container ===
class _GlassBlock extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassBlock({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// === One vertical info row ===
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kField,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: t.bodySmall?.copyWith(
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .1,
                  )),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '—' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(
                  color: kText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// thin divider between rows (inside glass)
class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x22000000), Color(0x00000000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

