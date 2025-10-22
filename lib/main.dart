import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/Offline/sync_service.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
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
  // WidgetsFlutterBinding.ensureInitialized();
  // await GetStorage.init();
    WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SyncService.instance.init();
  runApp(const MyApp());

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<GlobalBloc>(create: (_) => GlobalBloc()..add(Activity(activity: 'App Opens'))..add(const HydrateLoginFromCache()),
        ),
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
//context.read<GlobalBloc>().add(Activity(activity: 'App Open'));
    if (email != null) {
      print("if condition");
      print("if condition");
      print("if condition");
      print("if condition");
      print("EMAIL :$email");
      print("PASSWRD $password");
      Future.microtask(() {
        context.read<GlobalBloc>().add(
          LoginEvent(email: email!, password: password),
        );
      });
    } 
    
    else if (email_auth != null) {
      print("else condition");
      print("else condition");
      print("else condition");
      print("else condition");
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
