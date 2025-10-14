// lib/screens/start/start_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../onboarding/onboarding_q1_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фон
          Positioned.fill(
            child: Image.asset('assets/images/start_bg.png', fit: BoxFit.cover),
          ),

          // Контент
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Заголовок — жёстко 2 строки
                  const Text(
                    'Каждый день — шанс\nстать собой!',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
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
                          builder: (_) => const OnboardingQ1Screen(),
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
