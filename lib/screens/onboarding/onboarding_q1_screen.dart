import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import 'onboarding_q2_screen.dart';

class OnboardingQ1Screen extends StatelessWidget {
  const OnboardingQ1Screen({super.key});

  static const items = <String>[
    'Попробовала себя в чём-то новом',
    'Дала себе отдохнуть',
    'Сменила сферу',
    'Хочу пройти короткий тест, чтобы понять',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    // Небольшая «резина» заголовка
    final w = MediaQuery.of(context).size.width;
    final base = Theme.of(context).textTheme;
    final double titleSize = math.max(20, math.min(28, w * 0.065));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              // AppBar заменим на лёгкую верхнюю панель
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'А что бы ты сделала, если бы не боялась?',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  softWrap: true,
                  style: base.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: titleSize, // адаптивный
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Список
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final value = items[i];
                    final selected = vm.fearChoice == value;
                    return Material(
                      color: selected
                          ? Colors.white.withOpacity(0.12)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: selected ? FontWeight.w600 : null,
                          ),
                        ),
                        leading: Radio<String>(
                          value: value,
                          groupValue: vm.fearChoice,
                          onChanged: (v) => vm.setFear(v!),
                          fillColor: WidgetStateProperty.all(Colors.white),
                        ),
                        onTap: () => vm.setFear(value),
                      ),
                    );
                  },
                ),
              ),

              // Кнопка "Далее"
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
                      disabledBackgroundColor: Colors.white.withOpacity(0.15),
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
