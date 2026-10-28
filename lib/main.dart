import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
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
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/mechanic': (context) => const MechanicHomeScreen(),
        '/owner': (context) => const OwnerHomeScreen(),
      },
    );
  }
}