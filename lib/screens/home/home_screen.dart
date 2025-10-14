// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';

// экраны добавления целей
import '../goals/goal_suggest_screen.dart';
import '../goals/custom_goal_screen.dart';
import '../goals/categories_screen.dart' show CategoriesScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final need = _scroll.offset > 280.0;
    if (need != _showScrollTop) {
      setState(() => _showScrollTop = need);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openSuggest(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GoalSuggestScreen()));
  }

  Future<void> _openCustom(BuildContext context) async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CustomGoalScreen()));
    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Цель добавлена')));
    }
  }

  Future<void> _openCategories(BuildContext context) async {
    // Если нет CategoriesScreen — откроем «Своя цель»
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
    } catch (_) {
      await _openCustom(context);
    }
  }

  void _scrollToTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final items = vm.items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Stack(
            children: [
              // Основной контент
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок + кнопка "плюс" в шапке
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Мои цели',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2CC796),
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Добавить цель',
                          onPressed: () => _openCategories(context),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),

                  // Общий прогресс
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: vm.totalProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF2CC796),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Контент: список либо пустое состояние
                  Expanded(
                    child: items.isEmpty
                        ? _EmptyState(
                            onSuggest: () => _openSuggest(context),
                            onCustom: () => _openCustom(context),
                          )
                        : Scrollbar(
                            controller: _scroll,
                            thumbVisibility: true,
                            child: ListView.separated(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                24 + 56,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final g = items[index];
                                return _GoalTile(
                                  title: g.title,
                                  firstStep: g.firstStep,
                                  progress: g.progress,
                                  onProgress: (v) => vm.setProgress(g, v),
                                  onRemove: () =>
                                      _confirmRemove(context, vm, g),
                                  stepsText:
                                      '${(g.progress * 4).round()}/4 шага',
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),

              // Кнопка "вверх"
              Positioned(
                right: 16,
                bottom: 16,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  scale: _showScrollTop ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _showScrollTop ? 1 : 0,
                    child: FloatingActionButton.small(
                      heroTag: 'scrollTop',
                      onPressed: _scrollToTop,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      foregroundColor: Colors.white,
                      tooltip: 'Наверх',
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    HomeViewModel vm,
    goal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить цель?'),
        content: const Text('Действие нельзя будет отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final removed = goal;
      await vm.remove(removed);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Цель удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () async {
              await vm.addManualGoal(
                title: removed.title,
                category: removed.category.isEmpty ? null : removed.category,
                firstStep:
                    (removed.firstStep == null || removed.firstStep!.isEmpty)
                    ? null
                    : removed.firstStep,
              );
            },
          ),
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggest, required this.onCustom});

  final VoidCallback onSuggest;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'У тебя пока нет целей',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Давай начнём с одной маленькой.\nЯ могу предложить варианты или ты придумаешь свою.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSuggest,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2CC796),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Предложить цели'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onCustom,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Придумать свою'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.title,
    this.firstStep,
    required this.progress,
    required this.onProgress,
    required this.onRemove,
    this.stepsText,
  });

  final String title;
  final String? firstStep;
  final double progress;
  final ValueChanged<double> onProgress;
  final VoidCallback onRemove;
  final String? stepsText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок + удалить
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.white54),
                onPressed: onRemove,
                tooltip: 'Удалить цель',
              ),
            ],
          ),

          if (firstStep != null && firstStep!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    firstStep!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2CC796)),
            ),
          ),

          if (stepsText != null) ...[
            const SizedBox(height: 6),
            Text(
              stepsText!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2CC796),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    final next = (progress + 0.25).clamp(0.0, 1.0);
                    onProgress(next);
                  },
                  child: const Text('+ шаг выполнен'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => onProgress(0.0),
                child: const Text('Сброс'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
