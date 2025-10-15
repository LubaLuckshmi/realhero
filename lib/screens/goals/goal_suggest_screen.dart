// lib/screens/goals/goal_suggest_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/background_stars.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/goal_suggestor.dart';
import '../../services/ai_service.dart' show GoalSuggestion;

class GoalSuggestScreen extends StatefulWidget {
  const GoalSuggestScreen({super.key});

  @override
  State<GoalSuggestScreen> createState() => _GoalSuggestScreenState();
}

class _GoalSuggestScreenState extends State<GoalSuggestScreen> {
  bool _loading = true;
  List<GoalSuggestion> _ideas = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _generateFromOnboarding();
  }

  Future<void> _generateFromOnboarding() async {
    final ob = context.read<OnboardingViewModel>();

    try {
      final ideas = await GoalSuggestor.suggestWithAiFallback(
        fearChoice: ob.fearChoice,
        inspirations: ob.inspirations,
        energy: ob.energy,
        mood: ob.mood,
      );
      if (!mounted) return;
      setState(() {
        _ideas = ideas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка генерации целей: $e')));
    }
  }

  void _nextIdea() {
    if (_ideas.isEmpty) return;
    setState(() => _index = (_index + 1) % _ideas.length);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final hasIdea = _ideas.isNotEmpty;
    final current = hasIdea ? _ideas[_index] : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // верхняя панель
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (hasIdea)
                      Text(
                        '${_index + 1}/${_ideas.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  'Твоя возможная цель',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),

                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2CC796),
                      ),
                    ),
                  )
                else if (!hasIdea)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Не удалось сгенерировать цели 😔\nПопробуй пройти тест заново.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Container(
                        key: ValueKey(current!.title),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (current.firstStep != null &&
                                  current.firstStep!.isNotEmpty) ...[
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.flag,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Первый шаг',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  current.firstStep!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (current.tags.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: current.tags
                                      .map(
                                        (t) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: Text(
                                            t,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                if (hasIdea)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final g = current!;
                            await vm.addManualGoal(
                              title: g.title,
                              category: g.tags.isNotEmpty ? g.tags.first : null,
                              firstStep: g.firstStep,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Цель добавлена 🎯'),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2CC796),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Добавить в мои цели'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _nextIdea,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.16),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Ещё вариант'),
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
}
