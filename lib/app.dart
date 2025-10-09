// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/onboarding_view_model.dart';
import 'viewmodels/home_viewmodel.dart';

import 'screens/start/start_screen.dart';
// если пока стартового нет — можешь временно поставить HomeScreen:
// import 'screens/home/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2CC796),
      brightness: Brightness.dark,
      fontFamily: null, // если используешь свои шрифты — пропиши
      scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
    );

    return MultiProvider(
      providers: [
        // Онбординг (Q1–Q3)
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        // Цели (Home): сразу загружаем локальные цели
        ChangeNotifierProvider(create: (_) => HomeViewModel()..load()),
      ],
      child: MaterialApp(
        title: 'RealHero',
        debugShowCheckedModeBanner: false,
        theme: base,
        // Если хочешь сразу попадать на Home:
        // home: const HomeScreen(),
        home: const StartScreen(),
      ),
    );
  }
}
