import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import 'onboarding_summary_screen.dart';

class OnboardingQ3Screen extends StatelessWidget {
  const OnboardingQ3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    // Больше вариантов, как в макете
    final moods = const <(String, String)>[
      ('🫥', 'Опустошен'),
      ('😪', 'Уставший'),
      ('😔', 'Печален'),
      ('😕', 'Смущен'),
      ('😵‍💫', 'В смятении'),
      ('😐', 'Нейтрально'),
      ('😌', 'Спокойно'),
      ('⚡', 'Заряжен'),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text('4/4', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 6),
                child: Text(
                  'Как ты сейчас\nсебя чувствуешь?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: moods.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.9,
                        ),
                    itemBuilder: (_, i) {
                      final (emoji, label) = moods[i];
                      final selected = vm.mood == label;
                      return _MoodTile(
                        emoji: emoji,
                        label: label,
                        selected: selected,
                        onTap: () => vm.setMood(label),
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: vm.canGoNextFromQ3
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingSummaryScreen(),
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2CC796),
                      disabledBackgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
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

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(selected ? 0.20 : 0.08),
          border: Border.all(
            color: selected ? const Color(0xFF2CC796) : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? const Color(0xFF2CC796) : Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
