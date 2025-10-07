import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/widgets/toast_widget.dart';


class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  String buttonText = "Break"; // unchanged (not used in the main button)
  String? selectedBreak;
  final loc.Location location = loc.Location();

  bool isRouteStarted = false; // NEW: only for UI toggle

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const Color orange = Color(0xFFEA7A3B);

    final global = context.read<GlobalBloc>().state;
    final login = global.loginModel!;
    final userId = login.userinfo!.userId.toString();

    final jpCount = login.journeyPlan.length;                  // compare as ints
    final reasonsCount = login.reasons.length;                 // compare as ints

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'Routes',
          style: t.titleLarge?.copyWith(
            color: const Color(0xFF1E1E1E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              children: [
                const Icon(Icons.person, size: 35, color: orange),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'ATTENDANCE-IN TIME',
                    style: t.titleSmall?.copyWith(
                      color: const Color(0xFF1E1E1E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 35, color: orange),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "${login.log!.tim} , ${login.log!.time}",
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: const Color(0xFF1E1E1E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.20,
            ),
            child: Center(
              // CHANGED: default message
              child: Text(
                isRouteStarted ? 'Route In Progress' : 'Start Your Route',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.80,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final currentLocation = await location.getLocation();

                    if (!isRouteStarted) {
                      // START: action IN, type '1'
                      context.read<GlobalBloc>().add(
                        StartRouteEvent(
                          action: 'IN',
                          type: '1',
                          userId: userId,
                          lat: currentLocation.latitude.toString(),
                          lng: currentLocation.longitude.toString(),
                        ),
                      );
                      setState(() => isRouteStarted = true);
                    } else {
                      // END: only if all routes done
                      if (jpCount == reasonsCount) {
                        context.read<GlobalBloc>().add(
                          StartRouteEvent(
                            action: 'OUT',
                            type: '0',
                            userId: userId,
                            lat: currentLocation.latitude.toString(),
                            lng: currentLocation.longitude.toString(),
                          ),
                        );
                        setState(() => isRouteStarted = false);
                      } else {
                        toastWidget(
                          "Please complete your routes first!",
                          Colors.red,
                        );
                      }
                    }
                  },
                  child: Text(
                    isRouteStarted ? 'End Route' : 'Start your route',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}


// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});
//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   final loc.Location location = loc.Location();
//   bool isRouteStarted = false; // default: not started → "Start your route"

//   Future<void> _startRoute() async {
//     final currentLocation = await location.getLocation();
//     final userId = context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString();

//     context.read<GlobalBloc>().add(
//       StartRouteEvent(
//         action: 'IN',
//         type: '1',
//         userId: userId,
//         lat: currentLocation.latitude.toString(),
//         lng: currentLocation.longitude.toString(),
//       ),
//     );

//     setState(() => isRouteStarted = true); // optional: flip UI to "Route in progress"
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     const orange = Color(0xFFEA7A3B);

//     return Scaffold(
//       body: Column(
//         children: [
//           // ...
//           Padding(
//             padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.20),
//             child: Center(
//               child: Text(
//                 isRouteStarted ? 'Route in progress' : 'Start your route',
//                 style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(26.0),
//         child: SizedBox(
//           width: MediaQuery.of(context).size.width * 0.80,
//           height: 50,
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: orange,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             ),
//             onPressed: () async {
//               if (!isRouteStarted) {
//                 await _startRoute(); // fires IN / type '1'
//               } else {
//                 // (optional) handle "End Route" here if you add that later
//               }
//             },
//             child: Text(
//               isRouteStarted ? 'End Route' : 'Start your route',
//               style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// class RouteScreen extends StatefulWidget {
//   const RouteScreen({super.key});

//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   String buttonText = "Break";
//   String? selectedBreak;
//   final loc.Location location = loc.Location();

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     const Color orange = Color(0xFFEA7A3B);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: false,
//         title: Text(
//           'Routes',
//           style: t.titleLarge?.copyWith(
//             color: Color(0xFF1E1E1E),
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),

//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//             child: Row(
//               children: [
//                 Icon(Icons.person, size: 35, color: orange),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     'ATTENDANCE-IN TIME',
//                     style: t.titleSmall?.copyWith(
//                       color: Color(0xFF1E1E1E),
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
//             child: Row(
//               children: [
//                 Icon(Icons.access_time, size: 35, color: orange),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     "${context.read<GlobalBloc>().state.loginModel!.log!.tim.toString()} , ${context.read<GlobalBloc>().state.loginModel!.log!.time.toString()}",
//                     overflow: TextOverflow.ellipsis,
//                     style: t.titleSmall?.copyWith(
//                       color: Color(0xFF1E1E1E),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).size.height * 0.20,
//             ),
//             child: Center(child: Text('Route Started!')),
//           ),
//         ],
//       ),

//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(26.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 10),

//             Center(
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.80,
//                 height: 50,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: orange,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onPressed: () async {
//                     final currentLocation = await location.getLocation();

//                     if (context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .journeyPlan
//                             .length
//                             .toString() ==
//                         context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .reasons
//                             .length
//                             .toString()) {
//                       context.read<GlobalBloc>().add(
//                         StartRouteEvent(
//                           action: 'IN',
//                           type: '0',
//                           userId: context
//                               .read<GlobalBloc>()
//                               .state
//                               .loginModel!
//                               .userinfo!
//                               .userId
//                               .toString(),
//                           lat: currentLocation.latitude.toString(),
//                           lng: currentLocation.longitude.toString(),
//                         ),
//                       );
//                     } else {
//                       toastWidget(
//                         "Please complete your routes first!",
//                         Colors.red,
//                       );
//                     }
//                   },
//                   child: Text(
//                     'End Route',
//                     style: t.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             /*    SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   final currentLocation = await location.getLocation();

//                   if(context.read<GlobalBloc>().state.loginModel!.journeyPlan.length.toString() == context.read<GlobalBloc>().state.loginModel!.reasons!.length.toString()){

//                    context.read<GlobalBloc>().add(
//                       StartRouteEvent(
//                         type: '0',
//                         userId: context
//                             .read<GlobalBloc>()
//                             .state
//                             .loginModel!
//                             .userinfo!
//                             .userId
//                             .toString(),
//                         lat: currentLocation.latitude.toString(),
//                         lng: currentLocation.longitude.toString(),
//                       ),
//                     );
//                   }
//                   else{
//                     toastWidget("Please visit all the shops of your PJP", Colors.red);
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//             'End Route',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),*/
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }
// }
