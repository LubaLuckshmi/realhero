import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import 'onboarding_q3_screen.dart';

class OnboardingQ2Screen extends StatelessWidget {
  const OnboardingQ2Screen({super.key});

  /// Эмодзи + подпись (порядок как в макете)
  static const _items = <({String emoji, String label})>[
    (emoji: '🌿', label: 'Природа'),
    (emoji: '🎨', label: 'Искусство'),
    (emoji: '👥', label: 'Люди'),
    (emoji: '🎵', label: 'Музыка'),
    (emoji: '💰', label: 'Деньги'),
    (emoji: '😊', label: 'Эмоции'),
    (emoji: '🤝', label: 'Помощь другим'),
    (emoji: '💖', label: 'Красота'),
  ];

  static const _maxSelect = 3;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final chosen = vm.inspirations;

    void toggle(({String emoji, String label}) it) {
      final value = '${it.emoji} ${it.label}';
      if (chosen.contains(value)) {
        vm.toggleInspiration(value);
      } else if (chosen.length < _maxSelect) {
        vm.toggleInspiration(value);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Можно выбрать до 3 вариантов'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    final canNext = chosen.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                child: Text(
                  'Что тебя вдохновляет больше\nвсего?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              // Счётчик по центру под заголовком — как на скрине
              Text(
                'Выбрано ${chosen.length}/$_maxSelect',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              // Плитка
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _items.map((it) {
                    final value = '${it.emoji} ${it.label}';
                    final selected = chosen.contains(value);
                    return _ChoicePill(
                      text: value,
                      selected: selected,
                      onTap: () => toggle(it),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Кнопка "Дальше"
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canNext
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingQ3Screen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: canNext
                          ? const Color(0xFF2CC796)
                          : Colors.white24,
                      disabledBackgroundColor: Colors.white24,
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
}

/// Пилюля "как на скрине":
/// - НЕвыбранная: прозрачная, белая обводка
/// - Выбранная: синяя заливка
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  static const _blue = Color(0xFF3B82F6); // приятный синий для выбранного

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 44, minWidth: 110),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected ? _blue : Colors.transparent,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white70,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _blue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
