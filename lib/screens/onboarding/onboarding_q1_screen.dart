import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import 'onboarding_q2_screen.dart';

class OnboardingQ1Screen extends StatelessWidget {
  const OnboardingQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    final options = const [
      'Сменила сферу',
      'Дала себе отдохнуть',
      'Попробовала себя в чём-то новом',
      'Хочу пройти короткий тест, чтобы понять',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              // Верхняя панель
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text('1/4', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  'А что бы ты сделала,\nесли бы не боялась?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final o = options[i];
                    final selected = (vm.fearChoice == o);
                    return _Tile(
                      label: o,
                      selected: selected,
                      onTap: () => vm.setFear(o),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: vm.canGoNextFromQ1
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingQ2Screen(),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha:(selected ? 0.18 : 0.08)),
          border: Border.all(
            color: selected ? const Color(0xFF2CC796) : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF2CC796) : Colors.white70,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
