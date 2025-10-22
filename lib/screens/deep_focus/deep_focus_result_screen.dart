import 'package:flutter/material.dart';
import 'package:realhero/widgets/background_stars.dart';
import 'package:realhero/services/deep_focus_service.dart';
import 'package:realhero/models/deep_focus.dart';

class DeepFocusResultScreen extends StatelessWidget {
  const DeepFocusResultScreen({super.key, required this.advice});

  final DeepFocusAdvice advice;

  void _finish(BuildContext context) => Navigator.of(context).pop(true);

  void _createGoal(BuildContext context) {
    // Делаем простую цель: заголовок короткий, первый шаг = совет
    final intent = DeepFocusCreateGoal(
      title: 'Фокус недели',
      firstStep: advice.advice,
    );
    Navigator.of(context).pop(intent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // appbar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => _finish(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Твоя выжимка',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // карточка
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Коротко о тебе'),
                          Text(
                            advice.summary,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _sectionTitle('Персональный совет'),
                          Text(
                            advice.advice,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _createGoal(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Создать цель из совета'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _finish(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2CC796),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Понятно'),
                      ),
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

  Widget _sectionTitle(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      s,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
