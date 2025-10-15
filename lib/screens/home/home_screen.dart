// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';
import '../auth/email_auth_dialog.dart';
import '../../services/sync_service.dart';

// добавили
import '../goals/categories_screen.dart';
import '../goals/custom_goal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  bool _showUp = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final need = _scroll.offset > 200;
      if (need != _showUp) {
        setState(() => _showUp = need);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddTile(
                  icon: Icons.category_outlined,
                  title: 'Выбрать из категорий',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _AddTile(
                  icon: Icons.edit_outlined,
                  title: 'Создать свою цель',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomGoalScreen(),
                      ),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Цель сохранена 👌')),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Мои цели'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Сохранить прогресс в облаке',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () async {
              // 1) Мягкий логин
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => const EmailAuthDialog(),
              );

              // 2) Если вошли — пушим локальные цели в Firestore
              if (ok == true) {
                await SyncService().pushLocalToCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Синхронизировано с облаком')),
                  );
                }
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Отступ под AppBar
              const SizedBox(height: 8),

              // Общий прогресс
              if (vm.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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

              // Пустое состояние
              if (vm.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'У тебя пока нет целей',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Нажми «+», чтобы выбрать из предложений или придумать свою.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Список целей + видимый скроллбар
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: vm.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final g = vm.items[index];
                        return _GoalTile(
                          title: g.title,
                          firstStep: g.firstStep,
                          progress: g.progress,
                          onProgress: (v) => vm.setProgress(g, v),
                          onRemove: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Удалить цель?'),
                                content: const Text(
                                  'Это действие нельзя отменить.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Отмена'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await vm.remove(g);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Цель удалена')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // FAB + кнопка "вверх"
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // up
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _showUp ? Offset.zero : const Offset(0.2, 0.6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showUp ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70.0),
                child: FloatingActionButton.small(
                  heroTag: 'toTop',
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
            ),
          ),
          // main +
          FloatingActionButton.extended(
            heroTag: 'addGoal',
            onPressed: () => _openAddSheet(context),
            backgroundColor: const Color(0xFF2CC796),
            foregroundColor: Colors.black,
            label: const Text('Добавить'),
            icon: const Icon(Icons.add),
          ),
        ],
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
  });

  final String title;
  final String? firstStep;
  final double progress;
  final ValueChanged<double> onProgress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Цель: $title',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.all(16), // единый паддинг
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
                  tooltip: 'Удалить цель',
                  icon: const Icon(Icons.delete_forever, color: Colors.white54),
                  onPressed: onRemove,
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

            // Прогресс
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2CC796)),
              ),
            ),

            const SizedBox(height: 10),

            // Счётчик шагов (условно 4 шага = 100%)
            Text(
              '${(progress * 4).round()}/4 шага',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),

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
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
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
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
