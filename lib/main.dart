import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motives_new_ui_conversion/Offline/sync_progress_portal.dart';
import 'package:motives_new_ui_conversion/Offline/sync_service.dart';
import 'package:motives_new_ui_conversion/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'dart:async';
import 'dart:io';
import 'dart:io' show Platform;
import 'package:workmanager/workmanager.dart';


class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }
}

@pragma('vm:entry-point')
void taskoonSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await GetStorage.init(); 
      await SyncService.instance.trySync(); 
      return Future.value(true);
    } catch (e, st) {
      debugPrint('BG sync error: $e\n$st');
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  if (Platform.isAndroid) {
    await Workmanager().initialize(taskoonSyncDispatcher, isInDebugMode: false);
  }

  // Foreground sync hooks + periodic background
  await SyncService.instance.init();
  if (Platform.isAndroid) {
    await SyncService.instance.registerBackgroundJobs();
  }

  Bloc.observer = AppBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<GlobalBloc>(
          create: (_) => GlobalBloc()
            ..add(Activity(activity: 'App Opens'))
            ..add(const HydrateLoginFromCache()),
        ),
      ],
      child: SyncProgressPortal(child: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motives-T',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA7A3B)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
