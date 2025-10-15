// lib/screens/goals/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';
import 'custom_goal_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _categories = <_Category>[
    _Category('Здоровье', Icons.favorite_outline),
    _Category('Эмоции', Icons.emoji_emotions_outlined),
    _Category('Навыки', Icons.school_outlined),
    _Category('Отношения', Icons.favorite_border),
    _Category('Карьера', Icons.work_outline),
    _Category('Дом', Icons.home_outlined),
    _Category('Финансы', Icons.account_balance_wallet_outlined),
    _Category('Баланс', Icons.self_improvement_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Закрыть',
                    ),
                    const Spacer(),
                    Text(
                      'Выбери категорию',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final c = _categories[index];
                    return _CategoryCard(
                      title: c.title,
                      icon: c.icon,
                      onTap: () => _showPresets(context, c.title),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPresets(BuildContext context, String category) async {
    final vm = context.read<HomeViewModel>();
    final presets = _presets[category] ?? const <_Preset>[];

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white24),
            color: Colors.black.withValues(alpha: 0.25),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Быстрые цели • $category',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Пресеты
              ...presets.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PresetTile(
                    title: p.title,
                    step: p.firstStep,
                    onAdd: () async {
                      await vm.addManualGoal(
                        title: p.title,
                        category: category,
                        firstStep: p.firstStep,
                      );
                      if (ctx.mounted) Navigator.pop(ctx); // закрыть шит
                      if (context.mounted)
                        Navigator.pop(context); // назад на Home
                    },
                  ),
                ),
              ),

              // Своя цель в категории
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomGoalScreen(prefilledCategory: category),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Придумать свою в этой категории'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
  }
}

class _Category {
  final String title;
  final IconData icon;
  const _Category(this.title, this.icon);
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Категория $title',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preset {
  final String title;
  final String firstStep;
  const _Preset(this.title, this.firstStep);
}

/// Мини-набор готовых идей
const Map<String, List<_Preset>> _presets = {
  'Здоровье': [
    _Preset('Двигаться каждый день', '15 минут прогулки после ужина'),
    _Preset('Зарядка по утрам', '2–3 упражнения на 5 минут'),
    _Preset('Вода и сон', 'Выпить 1 стакан воды после пробуждения'),
  ],
  'Эмоции': [
    _Preset('Микро-эстетика дня', 'Найти и сфотографировать «красоту дня»'),
    _Preset('Вернуть музыку в день', 'Собрать плейлист и слушать 10 минут'),
    _Preset('Дневник эмоций', 'Записать 1 мысль о самочувствии вечером'),
  ],
  'Навыки': [
    _Preset('Капля языка', 'Пройти 1 короткий урок/карточки'),
    _Preset('Чтение по 10 минут', 'Открыть книгу и дочитать 3 страницы'),
  ],
  'Отношения': [
    _Preset('Знак внимания', 'Написать короткое тёплое сообщение близкому'),
    _Preset('Созвониться', 'Назначить 1 звонок в удобное окно'),
  ],
  'Карьера': [
    _Preset('Фокус-блок', '25 минут на одну задачу без отвлечений'),
    _Preset('Портфолио', 'Выбрать 1 работу и описать результат в 3 строках'),
  ],
  'Дом': [
    _Preset('Микро-уборка', 'Привести в порядок 1 маленькую зону'),
    _Preset('Список покупок', 'Добавить 3 нужные позиции'),
  ],
  'Финансы': [
    _Preset('Учёт расходов', 'Отметить сегодняшние траты'),
    _Preset('Резерв', 'Отложить символические 100 ₽'),
  ],
  'Баланс': [
    _Preset('Тихий слот', '10 минут без экрана перед сном'),
    _Preset('Дыхание 4-7-8', '3 цикла на расслабление'),
  ],
};

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.title,
    required this.step,
    required this.onAdd,
  });

  final String title;
  final String step;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.flag, color: Colors.white70, size: 18),
              SizedBox(width: 6),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(step, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2CC796),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
