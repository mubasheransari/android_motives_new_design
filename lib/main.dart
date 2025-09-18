import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:location/location.dart' as loc;

final box = GetStorage();
var email = box.read("email");
var password = box.read("password");
var email_auth = box.read("email_auth");
var password_auth = box.read("password-auth");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<GlobalBloc>(create: (_) => GlobalBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (email != null) {
      Future.microtask(() {
        context.read<GlobalBloc>().add(
          LoginEvent(email: email!, password: password),
        );
      });
    } else if (email_auth != null) {
      context.read<GlobalBloc>().add(
        LoginEvent(email: email_auth, password: password_auth),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motives-T',
      debugShowCheckedModeBanner: false,
      home:  SplashScreen(),
    );
  }
}


// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: 'Motives-T',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         ),
//         home: SplashScreen());
//   }
// }
