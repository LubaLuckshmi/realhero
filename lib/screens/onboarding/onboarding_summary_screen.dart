// lib/screens/onboarding/onboarding_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../goals/goal_suggest_screen.dart';
import '../auth/email_auth_dialog.dart';
import '../../services/sync_service.dart';

class OnboardingSummaryScreen extends StatelessWidget {
  const OnboardingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  'Итоги',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Q1
                Text(
                  'Твоя цель сейчас:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.fearChoice ?? '— не выбрано —',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 24),

                // Q2 — вдохновляет
                if (vm.inspirations.isNotEmpty) ...[
                  Text(
                    'Что вдохновляет:',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.inspirations.map((e) => _chip(e)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Energy
                if (vm.energy.isNotEmpty) ...[
                  Text(
                    'Что даёт энергию:',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.energy.map((e) => _chip(e)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Q3
                Text(
                  'Как ты себя чувствуешь:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.mood ?? '🙂 Нормально',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),

                const Spacer(),

                // CTA
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Предложить цели
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalSuggestScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2CC796),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Предложить цели'),
                    ),
                    const SizedBox(height: 10),

                    // 2) Сохранить прогресс
                    FilledButton.tonal(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => const EmailAuthDialog(),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          await SyncService().pushLocalToCloud();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Синхронизировано с облаком'),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Сохранить прогресс'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
