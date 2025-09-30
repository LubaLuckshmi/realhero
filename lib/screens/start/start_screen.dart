// lib/screens/start/start_screen.dart
import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../auth/auth_test_screen.dart';
import 'start_generated.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // убери SafeArea, если хочешь фон под статус-баром
        child: StartGenerated(
          onTapUnknown: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          onTapExamples: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthTestScreen()),
            );
          },
          onTapKnown: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
      ),
    );
  }
}
