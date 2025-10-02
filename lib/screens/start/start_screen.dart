// lib/screens/start/start_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../onboarding/onboarding_q2_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // фон — картинка со львом
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/start_bg.png', // положи файл в assets/images/
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  // заголовок в 2 строки, как в макете
                  const Text(
                    'Каждый день — шанс стать\nсобой!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),

                  const Spacer(),

                  // 1) зелёная кнопка
                  AppButton(
                    text: 'Я не знаю что хочу',
                    kind: AppButtonKind.green,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingQ2Screen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2) синяя кнопка
                  AppButton(
                    text: 'Посмотреть примеры',
                    kind: AppButtonKind.blue,
                    onTap: () {
                      // TODO: открыть экран с примерами (позже)
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3) «стеклянная» кнопка
                  AppButton(
                    text: 'Я уже знаю что хочу',
                    kind: AppButtonKind.ghost,
                    onTap: () {
                      // TODO: сразу к выбору целей (позже)
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
