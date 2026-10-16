import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/mechanic_home_screen.dart';
import 'screens/owner_home_screen.dart';

void main() {
  runApp(const TelemetriJuken5App());
}

class TelemetriJuken5App extends StatelessWidget {
  const TelemetriJuken5App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemetri Juken 5',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1565C0),
              width: 2,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/mechanic': (context) => const MechanicHomeScreen(),
        '/owner': (context) => const OwnerHomeScreen(),
      },
    );
  }
}