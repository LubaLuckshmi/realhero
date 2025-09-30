import 'package:flutter/material.dart'; // <= важный импорт
import 'package:google_fonts/google_fonts.dart';
import 'screens/start/start_screen.dart'; // <= наш стартовый экран

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal);

    return MaterialApp(
      title: 'RealHero',
      theme: base.copyWith(
        textTheme: GoogleFonts.karlaTextTheme(base.textTheme),
      ),
      home: const StartScreen(),
    );
  }
}
