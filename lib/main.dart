import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/login_page.dart';
import 'pages/map_page.dart';
import 'pages/setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.boot();
  runApp(const LocationApp());
}

class LocationApp extends StatelessWidget {
  const LocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '心动定位',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6ADAFC)),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6ADAFC),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          if (!s.loggedIn) return const LoginPage();
          if (!s.joined) return const SetupPage();
          return const MapPage();
        },
      ),
    );
  }
}
