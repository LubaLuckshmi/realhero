import 'package:flutter/material.dart';
import 'package:realhero/widgets/background_stars.dart';
import 'package:realhero/widgets/ai_suggestions_panel.dart';

/// Экран выбора категории + ИИ быстрые цели внутри каждой категории.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _cats = const [
    'Здоровье',
    'Эмоции',
    'Карьера',
    'Навыки',
    'Отношения',
    'Баланс',
  ];

  String? _selected;

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
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Выбери категорию',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // сетка категорий
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _cats.map((c) {
                    final sel = _selected == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: sel,
                      onSelected: (_) => setState(() => _selected = c),
                      labelStyle: TextStyle(
                        color: sel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: const Color(0xFF2CC796),
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      side: BorderSide(
                        color: sel ? const Color(0xFF2CC796) : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // панель ИИ-предложений по выбранной категории
                if (_selected != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Быстрые цели • ${_selected!}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AISuggestionsPanel(category: _selected!),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Выбери категорию,\nчтобы получить быстрые цели от ИИ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
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
