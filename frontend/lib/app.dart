import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

class NitcBusApp extends StatelessWidget {
  const NitcBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12304A);
    return MaterialApp(
      title: 'NITC Bus Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
          primary: const Color(0xFF176B87),
          surface: const Color(0xFFF6F8FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7EDF1)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
