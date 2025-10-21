import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';
import '../home/home_screen.dart';

/// Экран подсказок целей.
/// 1) сначала пытается получить идеи от AIService;
/// 2) если пусто — показывает локальный пул «шаблонных» подсказок.
class GoalSuggestScreen extends StatefulWidget {
  const GoalSuggestScreen({super.key, this.signals});

  /// Сигналы с онбординга (можно не передавать — тогда подсказки будут более общими).
  final OnboardingSignal? signals;

  @override
  State<GoalSuggestScreen> createState() => _GoalSuggestScreenState();
}

class _GoalSuggestScreenState extends State<GoalSuggestScreen> {
  // Фолбэк-пул (как у вас раньше)
  late final List<_GoalSuggestion> _fallbackPool;

  // Результат ИИ (если придёт — будем использовать его)
  List<_GoalSuggestion> _aiIdeas = const [];

  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _fallbackPool = <_GoalSuggestion>[
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

    _loadAI();
  }

  Future<void> _loadAI() async {
    setState(() => _loading = true);

    final s =
        widget.signals ??
        const OnboardingSignal(
          fearChoice: null,
          inspirations: <String>{},
          energy: <String>{},
          mood: null,
        );

    try {
      final ideas = await AIService.suggestGoals(s);
      // маппим к локальной модели экрана
      _aiIdeas = ideas
          .map(
            (g) => _GoalSuggestion(
              title: g.title,
              firstStep: g.firstStep?.trim().isEmpty == true
                  ? 'Сделать первый маленький шаг к цели'
                  : (g.firstStep ?? 'Сделать первый маленький шаг к цели'),
              category: (g.tags.isNotEmpty ? g.tags.first : 'цель'),
            ),
          )
          .toList();
    } catch (_) {
      _aiIdeas = const [];
    }

    if (!mounted) return;
    setState(() {
      _index = 0;
      _loading = false;
    });
  }

  List<_GoalSuggestion> get _currentList =>
      _aiIdeas.isNotEmpty ? _aiIdeas : _fallbackPool;

  void _next() {
    final list = _currentList;
    if (list.isEmpty) return;
    setState(() => _index = (_index + 1) % list.length);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final list = _currentList;

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
                    if (!_loading && list.isNotEmpty)
                      Text(
                        '${_index + 1}/${list.length}',
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

                // Скелетон/лоадер
                if (_loading)
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  )
                else if (list.isEmpty)
                  Text(
                    'Подсказок сейчас нет.\nПопробуйте позже или придумайте свою.',
                    style: const TextStyle(color: Colors.white70),
                  )
                else
                  _SuggestionCard(s: list[_index]),

                const Spacer(),

                // buttons
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading || list.isEmpty
                        ? null
                        : () async {
                            final s = list[_index];
                            final nav = Navigator.of(context);
                            await vm.addManualGoal(
                              title: s.title,
                              category: s.category,
                              firstStep: s.firstStep,
                            );
                            nav.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
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
                    onPressed: _loading || list.isEmpty ? null : _next,
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
                    onPressed: () => Navigator.of(context).pop(),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.s});
  final _GoalSuggestion s;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            s.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          // first step
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

          // tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.24)),
            ),
            child: Text(
              s.category,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
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
