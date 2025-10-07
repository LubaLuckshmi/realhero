import 'package:flutter/material.dart';
import '../../widgets/background_stars.dart';
import '../../services/goal_suggestor.dart';

class SuggestGoalScreen extends StatefulWidget {
  const SuggestGoalScreen({
    super.key,
    required this.fearChoice,
    required this.inspirations,
    required this.energy,
    required this.mood,
  });

  final String? fearChoice;
  final Set<String> inspirations;
  final Set<String> energy;
  final String? mood;

  @override
  State<SuggestGoalScreen> createState() => _SuggestGoalScreenState();
}

class _SuggestGoalScreenState extends State<SuggestGoalScreen> {
  late List<GoalSuggestion> _pool;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pool = GoalSuggestor.suggest(
      fearChoice: widget.fearChoice,
      inspirations: widget.inspirations,
      energy: widget.energy,
      mood: widget.mood,
    );
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % _pool.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _pool[_index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
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
                const SizedBox(height: 12),

                Text(
                  'Твоя возможная цель',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // карточка предложения
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (s.firstStep != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Первый шаг:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.firstStep!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (s.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: s.tags
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    border: Border.all(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),

                // кнопки
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'title': s.title,
                            'firstStep': s.firstStep,
                            'tags': s.tags,
                          });
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
                      child: FilledButton.tonal(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Предложи другую'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // тут можно открыть экран ручного создания цели
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Придумаю свою',
                        style: TextStyle(color: Colors.white70),
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
