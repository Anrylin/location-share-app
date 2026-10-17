import 'package:flutter/material.dart';

import 'app_state.dart';
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
      title: '位置共享',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)),
      ),
      home: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          return AppState.instance.joined ? const MapPage() : const SetupPage();
        },
      ),
    );
  }
}
