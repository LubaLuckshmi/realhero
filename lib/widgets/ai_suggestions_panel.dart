import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_service.dart';
import '../viewmodels/home_viewmodel.dart';

/// Панель ИИ-подсказок для выбранной категории.
/// Показывает 2–4 короткие цели с первым шагом и кнопкой "Добавить",
/// а также "Предложи ещё" для обновления выборки.
class AISuggestionsPanel extends StatefulWidget {
  const AISuggestionsPanel({super.key, required this.category});

  final String category;

  @override
  State<AISuggestionsPanel> createState() => _AISuggestionsPanelState();
}

class _AISuggestionsPanelState extends State<AISuggestionsPanel> {
  bool _loading = true;
  List<GoalSuggestion> _items = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AIService.suggestQuickGoals(widget.category, n: 3);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось получить предложения';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _error ?? 'Пока нет идей',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Попробовать ещё раз'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // список карточек
          ..._items.map(
            (g) => _GoalCard(
              g: g,
              onAdd: () async {
                await vm.addManualGoal(
                  title: g.title,
                  category: widget.category,
                  firstStep: g.firstStep,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Цель добавлена')));
              },
            ),
          ),
          const SizedBox(height: 8),

          // кнопка "Предложи ещё"
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Предложи ещё'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white24),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.g, required this.onAdd});

  final GoalSuggestion g;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            g.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // first step
          if ((g.firstStep ?? '').isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.flag, size: 16, color: Colors.white70),
                SizedBox(width: 6),
              ],
            ),
          if ((g.firstStep ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                g.firstStep!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2CC796),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Добавить'),
            ),
          ),
        ],
      ),
    );
  }
}
