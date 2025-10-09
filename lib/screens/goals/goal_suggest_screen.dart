// lib/screens/goals/goal_suggest_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';
import '../home/home_screen.dart';
import 'custom_goal_screen.dart';

class GoalSuggestScreen extends StatefulWidget {
  const GoalSuggestScreen({super.key});

  @override
  State<GoalSuggestScreen> createState() => _GoalSuggestScreenState();
}

class _GoalSuggestScreenState extends State<GoalSuggestScreen> {
  late final List<_GoalSuggestion> _pool;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // тот же набор, что был раньше
    _pool = <_GoalSuggestion>[
      _GoalSuggestion(
        title: 'Микро-эстетика дня',
        firstStep: 'Найти и сфотографировать «красоту дня»',
        category: 'вкус к жизни',
      ),
      _GoalSuggestion(
        title: 'Вернуть музыку в день',
        firstStep: 'Собрать плейлист на неделю и слушать по 10 минут',
        category: 'эмоции',
      ),
      _GoalSuggestion(
        title: 'Двигаться каждый день',
        firstStep: '15 минут прогулки после ужина',
        category: 'здоровье',
      ),
      _GoalSuggestion(
        title: 'Забота о себе',
        firstStep: 'Назначить 1 «тихий час» без телефона',
        category: 'баланс',
      ),
    ];
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % _pool.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final s = _pool[_index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/${_pool.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 16),

                // ОДНА карточка — без списка => без задвоений
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // заголовок
                      Text(
                        s.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // первый шаг
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.flag, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          s.firstStep,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // тег
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          s.category,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Кнопки (как было)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await vm.addManualGoal(
                        title: s.title,
                        category: s.category,
                        firstStep: s.firstStep,
                      );
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2CC796),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Это мне подходит'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.16),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Предложи другую'),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      final res = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const CustomGoalScreen(),
                        ),
                      );
                      if (res == true && mounted) {
                        // если пользователь сохранил свою цель — на Home
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Придумаю свою',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSuggestion {
  final String title;
  final String firstStep;
  final String category;
  _GoalSuggestion({
    required this.title,
    required this.firstStep,
    required this.category,
  });
}
