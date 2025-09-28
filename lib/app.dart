import 'package:flutter/material.dart';
import 'screens/auth/auth_test_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "RealHero",
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.teal),
      home: const AuthTestScreen(), // временно тест
    );
  }
}
