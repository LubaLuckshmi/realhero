import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/start/start_screen.dart';
import 'viewmodels/onboarding_view_model.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OnboardingViewModel>(
          create: (_) => OnboardingViewModel(),
        ),
        // сюда позже легко добавим:
        // ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        // ChangeNotifierProvider<GoalsViewModel>(create: (_) => GoalsViewModel()),
      ],
      child: MaterialApp(
        title: 'RealHero',
        theme: base.copyWith(
          textTheme: GoogleFonts.karlaTextTheme(base.textTheme),
        ),
        home: const StartScreen(),
      ),
    );
  }
}
