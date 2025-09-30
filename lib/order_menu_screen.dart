import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';

class OrderMenuScreen extends StatefulWidget {
  String shopname, miscid,address;
  OrderMenuScreen({super.key, required this.shopname, required this.miscid,required this.address});

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  String checkInText = "Check In";
  String iconAsset = "assets/checkin_order.png";
  final loc.Location location = loc.Location();

  void _toggleCheckIn() {
    setState(() {
      if (checkInText == "Check In") {
        checkInText = "Check Out";
        iconAsset = "assets/checkout_order.png";
      } else {
        checkInText = "Check In";
        iconAsset = "assets/checkin_order.png";
      }
    });
  }

  String? selectedOption; 

  Future<void> showHoldDialog(BuildContext context) async {
    int selectedValue = 0;

    List<String> holdText = [
      "Purchaser Not Available",
      "Tea Time",
      "Lunch Time",
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white, 
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ), 
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text("Select Hold Reason!")),
            
                    const SizedBox(height: 8),
                    ...List.generate(holdText.length, (index) {
                      return RadioListTile<int>(
                        dense: true, 
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact, 
                        title: Text(
                          holdText[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        value: index,
                        groupValue: selectedValue,
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value!;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    }),
                  
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> noOrderReason(BuildContext context) async {
    int selectedValue = 0;

    List<String> noOrder = [
      "No Order",
      "Credit Not Alowed",
      "Shop Closed",
      "Stock Available",
      "No Order With Collection",
      "Visit For Collection",
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white, // White only
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ), // Reduced padding
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text("Select No Order Reason!")),
                    // const Text(
                    //   "Choose an Option",
                    //   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    // ),
                    const SizedBox(height: 8),
                    ...List.generate(noOrder.length, (index) {
                      return RadioListTile<int>(
                        dense: true, // Compact style
                        contentPadding: EdgeInsets.zero, // No extra padding
                        visualDensity: VisualDensity.compact, // Reduce spacing
                        title: Text(
                          noOrder[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        value: index,
                        groupValue: selectedValue,
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value!;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    }),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () => Navigator.pop(context, selectedValue),
                    //     child: const Text("OK"),
                    //   ),
                    // ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  


  @override
  Widget build(BuildContext context) {
    const kText = Color(0xFF1E1E1E);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'Order Menu',
          style: t.titleLarge?.copyWith(
            color: kText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: CustomScrollView(
    physics: const BouncingScrollPhysics(),
        slivers:[ 
          SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 90,
                     // width: MediaQuery.of(context).size.width*0.99,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                        // colors: [Colors.grey,Colors.grey],
                          colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
                          //  colors: [orange, Color(0xFFFFB07A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _GlassHeader(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  child: const Icon(
                                    Icons.shop_sharp,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.shopname,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.95),
                                          fontWeight: FontWeight.w600,
                                          height: 1.1,
                                        ),
                                      ),
                                            Text(
                                        widget.address,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.95),
                                          fontWeight: FontWeight.w600,
                                          height: 1.1,
                                        ),
                                      ),
                            
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          
                          ],
                        ),
                      ),
                    ),
              
                  ],
                ),
              ),

          SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.10,
                  ),
                  delegate: SliverChildListDelegate.fixed([

                      
                    _TapScale(
                                  onTap: () async {
                                final currentLocation = await location
                                    .getLocation();
                                _toggleCheckIn();
                                context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '5',
                                    userId: context
                                        .read<GlobalBloc>()
                                        .state
                                        .loginModel!
                                        .userinfo!
                                        .userId
                                        .toString(),
                                    lat: currentLocation.latitude.toString(),
                                    lng: currentLocation.longitude.toString(),
                                    act_type: "SHOP_CHECK",
                                    action: "IN",
                                    misc: widget.miscid,
                                    dist_id: context
                                        .read<GlobalBloc>()
                                        .state
                                        .loginModel!
                                        .userinfo!
                                        .disid
                                        .toString(),
                                  ),
                                );
                              },
                      child: const _CategoryCard(
                        icon: Icons.access_time,
                        title: 'Checkin',
                        subtitle: 'Shop Checkin',
                      ),
                    ),
                    _TapScale(
                      onTap: () {
               
                      },
                      child: const _CategoryCard(
                        icon: Icons.alt_route,
                        title: 'Take Order',
                        subtitle: 'Orders',
                      ),
                    ),
                    _TapScale(
                      onTap: () {
                        showHoldDialog(context);
                  
                      },
                      child: const _CategoryCard(
                        icon: Icons.shopping_cart,
                        title: 'Hold',
                        subtitle: 'Hold Reason',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                   noOrderReason(context);
                      },
                      child: const _CategoryCard(
                        icon: Icons.insert_drive_file,
                        title: 'No Order Reason',
                        subtitle: 'Select Reason',
                      ),
                    ),

                      _TapScale(
                      onTap: () {
                   
                      },
                      child: const _CategoryCard(
                        icon: Icons.shopping_cart,
                        title: 'Collect Payment',
                        subtitle: 'Place new order',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                  
                      },
                      child: const _CategoryCard(
                        icon: Icons.insert_drive_file,
                        title: 'Sale History',
                        subtitle: 'History',
                      ),
                    ),
                  ]),
                ),
              ),


         ])
    );
  }

  

  Widget _buildStatCard({
    required String title,
    required String iconName,
    required Color color1,
    required Color color2,
    required double height,
    required double width,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width * 0.40,
      //   padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconName, height: height, width: width),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
        ],
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



class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

   const Color orange = Color(0xFFEA7A3B);
   const Color text = Color(0xFF1E1E1E);
   const Color muted = Color(0xFF707883);
   const Color field = Color(0xFFF5F5F7);
   const Color card = Colors.white;
   const Color accent = Color(0xFFE97C42);
   const Color _shadow = Color(0x14000000);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [orange, Color(0xFFFFB07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(
              color: _shadow,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: field,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, color: orange),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: t.titleSmall?.copyWith(
                color: text,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
            ),
            // if (subtitle != null) ...[
            //   const SizedBox(height: 2),
            //   Text(
            //     subtitle!,
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //     style: t.bodySmall?.copyWith(color:muted),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}


class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
