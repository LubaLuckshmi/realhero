import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../onboarding/onboarding_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фон — открываем морду льва
          Positioned.fill(
            child: Image.asset(
              'assets/images/start_bg.png', // проверь имя файла
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Контент
          Column(
            children: [
              const SizedBox(height: 140),

              // Заголовок
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Каждый день — шанс стать собой!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const Spacer(),

              // Кнопка 1 — зелёный градиент (через наш AppButton primary)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: AppButton(
                  text: 'Я не знаю что хочу',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                  primary: true,
                ),
              ),

              // Кнопка 2 — синяя
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: AppButton(
                  text: 'Посмотреть примеры',
                  onTap: () {},
                  primary: false, // у нас вторичный стиль — синий
                ),
              ),

              // Кнопка 3 — прозрачная (кастом)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Я уже знаю что хочу',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
