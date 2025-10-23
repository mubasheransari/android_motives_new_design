import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/Offline/sync_service.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';
import 'package:motives_new_ui_conversion/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:io';

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




/// Fast, reliable internet check.
/// - Races: TCP to 1.1.1.1:53 and 8.8.8.8:53, plus an HTTP 204 probe.
/// - Returns true the moment any path confirms connectivity.
/// - No extra packages needed.
class NetCheck {
  static const _dnsHosts = [
    ['1.1.1.1', 53],  // Cloudflare DNS
    ['8.8.8.8', 53],  // Google DNS
  ];
  static const _probeUrl = 'https://www.gstatic.com/generate_204';

  /// Typical result in < 300–800ms depending on network.
  static Future<bool> isOnline({
    Duration tcpTimeout = const Duration(milliseconds: 700),
    Duration httpTimeout = const Duration(seconds: 1, milliseconds: 200),
  }) async {
    // Build tasks
    final tasks = <Future<bool>>[
      for (final h in _dnsHosts) _tcpPing(h[0] as String, h[1] as int, tcpTimeout),
      _http204(httpTimeout),
    ];

    // Complete as soon as any returns true; otherwise false when all finish.
    final completer = Completer<bool>();
    var pending = tasks.length;

    void tryComplete(bool ok) {
      if (ok && !completer.isCompleted) {
        completer.complete(true);
      } else {
        pending -= 1;
        if (pending == 0 && !completer.isCompleted) completer.complete(false);
      }
    }

    for (final t in tasks) {
      t.then(tryComplete).catchError((_) => tryComplete(false));
    }

    return completer.future;
  }

  static Future<bool> _tcpPing(String host, int port, Duration timeout) async {
    try {
      final s = await Socket.connect(host, port, timeout: timeout);
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _http204(Duration timeout) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;
      final req = await client.openUrl('GET', Uri.parse(_probeUrl)).timeout(timeout);
      req.followRedirects = false;
      final res = await req.close().timeout(timeout);
      // Drain/close quickly; response body is empty for 204.
      await res.drain();
      return res.statusCode == 204;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }
}




class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  initialMethod()async{
        final online = await NetCheck.isOnline();

//context.read<GlobalBloc>().add(Activity(activity: 'App Open'));
    if (email != null && online ) {
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
  }

  
  @override
  void initState() {
    super.initState();
     initialMethod();
//     final online = await NetCheck.isOnline();

// //context.read<GlobalBloc>().add(Activity(activity: 'App Open'));
//     if (email != null && online ) {
//       print("if condition");
//       print("if condition");
//       print("if condition");
//       print("if condition");
//       print("EMAIL :$email");
//       print("PASSWRD $password");

//       Future.microtask(() {
//         context.read<GlobalBloc>().add(
//           LoginEvent(email: email!, password: password),
//         );
//       });
//     } 



    
    // else if (email_auth != null) {
    //   print("else condition");
    //   print("else condition");
    //   print("else condition");
    //   print("else condition");
    //   context.read<GlobalBloc>().add(
    //     LoginEvent(email: email_auth, password: password_auth),
    //   );
    // }
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
