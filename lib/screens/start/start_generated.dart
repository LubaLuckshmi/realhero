import 'package:flutter/material.dart';

/// Сшитый по макету виджет: фон + заголовок + 3 кнопки.
/// Колбэки прокидываются снаружи, чтобы StartScreen управлял навигацией.
class StartGenerated extends StatelessWidget {
  const StartGenerated({
    super.key,
    this.onTapUnknown,
    this.onTapExamples,
    this.onTapKnown,
  });

  final VoidCallback? onTapUnknown;  // "Я не знаю что хочу"
  final VoidCallback? onTapExamples; // "Посмотреть примеры"
  final VoidCallback? onTapKnown;    // "Я уже знаю что хочу"

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Фон
        Positioned.fill(
          child: Image.asset(
            'assets/images/lion_bg.png', // <= положи картинку сюда
            fit: BoxFit.cover,
          ),
        ),

        // Заголовок
        Positioned(
          left: 94,
          top: 118,
          child: SizedBox(
            width: 250,
            child: Text(
              'Каждый день - шанс стать собой!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),

        // Кнопка 1: "Я не знаю что хочу"
        Positioned(
          left: 63,
          right: 64,
          top: 723,
          child: GestureDetector(
            onTap: onTapUnknown,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  begin: Alignment(0.50, 1.44),
                  end: Alignment(1.39, 0.44),
                  colors: [Color(0xFF7EF091), Color(0xFF2CC796)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF76ED92),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Я не знаю что хочу',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.11,
                ),
              ),
            ),
          ),
        ),

        // Кнопка 2: "Посмотреть примеры"
        Positioned(
          left: 64,
          right: 65,
          top: 796,
          child: GestureDetector(
            onTap: onTapExamples,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4565D4),
                borderRadius: BorderRadius.circular(27),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Посмотреть примеры',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.11,
                ),
              ),
            ),
          ),
        ),

        // Кнопка 3: "Я уже знаю что хочу"
        Positioned(
          left: 64,
          right: 65,
          top: 863,
          child: GestureDetector(
            onTap: onTapKnown,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white.withOpacity(0.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33EEF4FF),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Я уже знаю что хочу',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
