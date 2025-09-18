import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/peofile_screen.dart';
import 'listviewui.dart';


class HomeUpdated extends StatelessWidget {
  const HomeUpdated({super.key});


  static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF2F3F5);
  static const Color card = Colors.white;
  static const accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000); 

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back!',
                              style: t.headlineSmall?.copyWith(
                                height: 1.1,
                                color: text,
                                fontWeight: FontWeight.w600,
                              )),
                          Text('Testuser',
                              style: t.headlineSmall?.copyWith(
                                height: 1.1,
                                color: orange,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 16),
                          // Status pill -> styled like catalog tag
                          const _StatusPill(
                            icon: Icons.assignment_turned_in_rounded,
                            label: 'Last Action Performed : LOGIN',
                          ),
                        ],
                      ),
                    ),
                    // Right: decorative pills
                    const _OrangePills(),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate.fixed([
                  const _CategoryCard(
                      icon: Icons.access_time, title: 'Attendance'),
                  const _CategoryCard(icon: Icons.alt_route, title: 'Routes'),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MeezanTeaCatalog()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const _CategoryCard(
                        icon: Icons.shopping_cart, title: 'Punch Order'),
                  ),
                  const _CategoryCard(
                      icon: Icons.insert_drive_file, title: 'Records'),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),

            // ---------- Features title ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(
                  children: [
                    Text('Features',
                        style: t.titleMedium?.copyWith(
                          color: orange,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: orange.withOpacity(.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: _CenteredHScroll(
                  paddingLR: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: const _FeatureCard(
                            title: 'Profile', icon: Icons.person),
                      ),
                      const SizedBox(width: 12),
                      const _FeatureCard(title: 'Sync Out', icon: Icons.upload),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: _CenteredHScroll(
                  paddingLR: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _FeatureCard(title: 'Sync In', icon: Icons.download),
                      SizedBox(width: 12),
                      _FeatureCard(
                          title: 'Add Shops', icon: Icons.add_business_rounded),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: 600,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUpdated.orange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomeUpdated.orange.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: HomeUpdated.orange),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: HomeUpdated.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangePills extends StatelessWidget {
  const _OrangePills();

  @override
  Widget build(BuildContext context) {
    const orange = HomeUpdated.orange;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Transform.rotate(
        angle: -12 * 3.1415926 / 180,
        child: Column(
          children: [
            _Pill(color: orange.withOpacity(.18), width: 50),
            const SizedBox(height: 6),
            _Pill(color: orange.withOpacity(.34), width: 62),
            const SizedBox(height: 6),
            _Pill(color: orange, width: 82),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Category card with the same "gradient outline -> white card" pattern as TeaCard
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.4),
          boxShadow: const [
            BoxShadow(
                color: HomeUpdated._shadow,
                blurRadius: 14,
                offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: HomeUpdated.field,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: HomeUpdated.orange),
              ),
            ),
            const Spacer(),
            Text(title,
                style: t.titleMedium?.copyWith(
                  color: HomeUpdated.text,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 2),
            Text('Explore',
                style: t.bodySmall?.copyWith(color: HomeUpdated.muted)),
          ],
        ),
      ),
    );
  }
}

/// Feature card mirrors the compact look used in catalog lanes
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      width: 150,
      height: 100, // fits inside 110px lane height
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeUpdated.orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          color: HomeUpdated.card,
          borderRadius: BorderRadius.circular(14.4),
          boxShadow: const [
            BoxShadow(
                color: HomeUpdated._shadow,
                blurRadius: 14,
                offset: Offset(0, 8))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: HomeUpdated.field,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: HomeUpdated.orange),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall?.copyWith(
                  color: HomeUpdated.text, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centers a horizontal row if the total width is shorter than the viewport
class _CenteredHScroll extends StatelessWidget {
  const _CenteredHScroll({required this.child, this.paddingLR = 20});
  final Widget child;
  final double paddingLR;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cns) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingLR),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: cns.maxWidth - paddingLR * 2),
            child: child,
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:motives_new_ui_conversion/peofile_screen.dart';

// import 'listviewui.dart';

// class HomeUpdated extends StatelessWidget {
//   const HomeUpdated({super.key});

//   // —— Theme tokens (match your login) ——
//   static const Color orange = Color(0xFFEA7A3B); // pick your exact hex
//   static const Color text = Color(0xFF1E1E1E);
//   static const Color muted = Color(0xFF707883);
//   static const Color field =
//       Color(0xFFF2F3F5); // same vibe as your Email/Password fields
//   static const Color card = Colors.white;
//   static const accent = Color(0xFFE97C42);

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 18),
//                           Text('Welcome back!',
//                               style: t.headlineSmall?.copyWith(
//                                 height: 1.1,
//                                 color: text,
//                                 fontWeight: FontWeight.w500,
//                               )),
//                           //const SizedBox(height: 3),
//                           Text('Testuser',
//                               style: t.headlineSmall?.copyWith(
//                                 height: 1.1,
//                                 color: orange,
//                                 fontWeight: FontWeight.w500,
//                               )),
//                         ],
//                       ),
//                     ),

//                     // Right: decorative “pills” to match the login corner motif
//                     const _OrangePills(),
//                   ],
//                 ),
//               ),
//             ),

//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     _ChipAction(
//                       label: 'Last Action Performed : LOGIN',
//                       icon: Icons.assignment_rounded,
//                       color: orange,
//                       fg: text,
//                       onTap: () {},
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Categories grid
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
//               sliver: SliverGrid(
//                 delegate: SliverChildListDelegate.fixed([
//                   _CategoryCard(icon: Icons.access_time, title: 'Attendance'),
//                   _CategoryCard(icon: Icons.alt_route, title: 'Routes'),
//                   InkWell(
//                     onTap: () {
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => MeezanTeaCatalog()));
//                     },
//                     child: _CategoryCard(
//                         icon: Icons.shopping_cart, title: 'Punch Order'),
//                   ),
//                   _CategoryCard(
//                       icon: Icons.insert_drive_file, title: 'Records'),
//                   // _CategoryCard(icon: Icons.home_rounded, title: 'Home'),
//                   // _CategoryCard(icon: Icons.more_horiz_rounded, title: 'More'),
//                 ]),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 12,
//                   mainAxisSpacing: 12,
//                   childAspectRatio: 1.15,
//                 ),
//               ),
//             ),

//             // “Recommended” horizontal list
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
//                 child: Row(
//                   children: [
//                     Text('Features',
//                         style: TextStyle(
//                             color: orange,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 19)),
//                   ],
//                 ),
//               ),
//             ),

//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: EdgeInsets.only(
//                     left: MediaQuery.of(context).size.width * 0.10),
//                 child: SizedBox(
//                   height: 103,
//                   child: Center(
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.only(left: 10, right: 10),
//                       children: [
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => ProfileScreen()));
//                           },
//                           child: _RecoCard(
//                               title: 'Profile',
//                               price: '\$20',
//                               icon: Icons.person),
//                         ),
//                         _RecoCard(
//                             title: 'Sync Out',
//                             price: '\$39',
//                             icon: Icons.upload),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: EdgeInsets.only(
//                     left: MediaQuery.of(context).size.width * 0.10, top: 10),
//                 child: SizedBox(
//                   height: 103,
//                   child: Center(
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.only(left: 10, right: 10),
//                       children: const [
//                         SizedBox(
//                           child: _RecoCard(
//                               title: 'Sync In',
//                               price: '\$45/hr',
//                               icon: Icons.download),
//                         ),
//                         _RecoCard(
//                             title: 'Add Shops', price: '\$39', icon: Icons.add),
//                       ],
//                     ),
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

// class _OrangePills extends StatelessWidget {
//   const _OrangePills();

//   @override
//   Widget build(BuildContext context) {
//     const orange = HomeUpdated.orange;
//     return Padding(
//       padding: const EdgeInsets.only(top: 8),
//       child: Transform.rotate(
//         angle: -12 * 3.1415926 / 180,
//         child: Column(
//           children: [
//             _Pill(color: orange.withOpacity(.20), width: 54),
//             const SizedBox(height: 6),
//             _Pill(color: orange.withOpacity(.35), width: 64),
//             const SizedBox(height: 6),
//             _Pill(color: orange, width: 84),
//           ],
//         ),
//       ),
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
//       height: 16,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(8),
//       ),
//     );
//   }
// }

// class _RoundIcon extends StatelessWidget {
//   const _RoundIcon({required this.icon, this.onTap});
//   final IconData icon;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: HomeUpdated.field,
//       shape: const CircleBorder(),
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: const SizedBox(
//           width: 44,
//           height: 44,
//           child:
//               Center(child: Icon(Icons.tune_rounded, color: HomeUpdated.muted)),
//         ),
//       ),
//     );
//   }
// }

// class _ChipAction extends StatelessWidget {
//   const _ChipAction(
//       {required this.label,
//       required this.icon,
//       required this.color,
//       this.fg,
//       this.onTap});
//   final String label;
//   final IconData icon;
//   final Color color;
//   final Color? fg;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Material(
//       color: color,
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           height: 44,
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               Icon(icon, size: 18, color: Colors.white),
//               const SizedBox(width: 8),
//               Text(label,
//                   style: t.bodyMedium?.copyWith(
//                       color: Colors.white, fontWeight: FontWeight.w600)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title});
//   final IconData icon;
//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       decoration: BoxDecoration(
//         color: HomeUpdated.card,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(
//               color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6))
//         ],
//       ),
//       padding: const EdgeInsets.all(14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Material(
//             color: HomeUpdated.field,
//             shape: const CircleBorder(),
//             child: SizedBox(
//               width: 44,
//               height: 44,
//               child: Icon(icon, color: HomeUpdated.orange),
//             ),
//           ),
//           const Spacer(),
//           Text(title, style: t.titleMedium?.copyWith(color: HomeUpdated.text)),
//           const SizedBox(height: 2),
//           Text('Explore',
//               style: t.bodySmall?.copyWith(color: HomeUpdated.muted)),
//         ],
//       ),
//     );
//   }
// }

// class _RecoCard extends StatelessWidget {
//   const _RecoCard(
//       {required this.title, required this.price, required this.icon});
//   final String title;
//   final String price;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       width: 150,
//       height: 50,
//       margin: const EdgeInsets.only(right: 12),
//       decoration: BoxDecoration(
//         color: HomeUpdated.card,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: const [
//           BoxShadow(
//               color: Color(0x16000000), blurRadius: 14, offset: Offset(0, 8))
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Container(
//           //   width: 52,
//           //   height: 52,
//           //   decoration: BoxDecoration(
//           //     color: HomeUpdated.field,
//           //     borderRadius: BorderRadius.circular(14),
//           //   ),
//           //   child: Icon(icon, color: HomeUpdated.orange),
//           // ),
//           // const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Column(
//                   children: [
//                     Container(
//                       width: 38,
//                       height: 38,
//                       decoration: BoxDecoration(
//                         color: HomeUpdated.field,
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: Icon(icon, color: HomeUpdated.orange),
//                     ),
//                     SizedBox(height: 8),
//                     Text(title,
//                         style:
//                             t.titleMedium?.copyWith(color: HomeUpdated.text)),
//                   ],
//                 ),
//                 // const SizedBox(height: 2),
//                 // Text(price,
//                 //     style: t.bodyMedium?.copyWith(
//                 //         color: HomeUpdated.orange,
//                 //         fontWeight: FontWeight.w700)),
//               ],
//             ),
//           ),
//           // Container(
//           //   width: 52,
//           //   height: 52,
//           //   decoration: BoxDecoration(
//           //     color: HomeUpdated.field,
//           //     borderRadius: BorderRadius.circular(14),
//           //   ),
//           //   child: Icon(icon, color: HomeUpdated.orange),
//           // ),
//         ],
//       ),
//     );
//   }
// }

// class _BottomNav extends StatelessWidget {
//   const _BottomNav({required this.currentIndex, required this.onTap});
//   final int currentIndex;
//   final void Function(int) onTap;

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: onTap,
//       selectedItemColor: HomeUpdated.orange,
//       unselectedItemColor: HomeUpdated.muted,
//       showUnselectedLabels: true,
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
//         // BottomNavigationBarItem(
//         //     icon: Icon(Icons.calendar_month_rounded), label: 'Orders'),
//         BottomNavigationBarItem(
//             icon: Icon(Icons.person_rounded), label: 'Profile'),
//       ],
//     );
//   }
// }
