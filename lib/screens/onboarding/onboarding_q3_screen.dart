import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import 'onboarding_summary_screen.dart';

class OnboardingQ3Screen extends StatelessWidget {
  const OnboardingQ3Screen({super.key});

  // Константы состояний
  static const _moods = <int, ({String emoji, String label})>{
    0: (emoji: '😔', label: 'Плохо'),
    1: (emoji: '🙂', label: 'Нормально'),
    2: (emoji: '😃', label: 'Отлично'),
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    // текущий слайдер по vm.mood
    final double sliderValue = _moodToValue(vm.mood);

    void onSlider(double v) => vm.setMood(_valueToMood(v));

    final curr = _moods[_moodIndex(sliderValue)]!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              // back
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Как ты сейчас себя\nчувствуешь?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),

              // Текущее значение — БОЛЬШОЙ смайл + надпись
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(curr.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 8),
                    Text(
                      curr.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Слайдер
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                    inactiveTrackColor: Colors.white24,
                    activeTrackColor: const Color(0xFF2CC796),
                    thumbColor: const Color(0xFF2CC796),
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 0,
                    max: 2,
                    divisions: 2,
                    onChanged: onSlider,
                  ),
                ),
              ),

              // Подписи ПОД слайдером: смайл + текст для каждого деления
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MoodTick(emoji: _moods[0]!.emoji, label: _moods[0]!.label),
                    _MoodTick(emoji: _moods[1]!.emoji, label: _moods[1]!.label),
                    _MoodTick(emoji: _moods[2]!.emoji, label: _moods[2]!.label),
                  ],
                ),
              ),

              const Spacer(),

              // Кнопка "Дальше"
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // если по какой-то причине mood ещё null — проставим текущее
                      if (vm.mood == null)
                        vm.setMood(_valueToMood(sliderValue));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingSummaryScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2CC796),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Дальше'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== helpers ====

  static int _moodIndex(double value) => value.round().clamp(0, 2);

  static double _moodToValue(String? mood) {
    switch (mood) {
      case '😔 Плохо':
        return 0;
      case '😃 Отлично':
        return 2;
      case '🙂 Нормально':
      default:
        return 1;
    }
  }

  static String _valueToMood(double value) {
    switch (value.round()) {
      case 0:
        return '😔 Плохо';
      case 2:
        return '😃 Отлично';
      case 1:
      default:
        return '🙂 Нормально';
    }
  }
}

class _MoodTick extends StatelessWidget {
  const _MoodTick({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
