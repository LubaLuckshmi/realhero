import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/goal.dart';
import '../../widgets/app_button.dart';
import '../../widgets/background_stars.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({
    super.key,
    this.prefillCategory,
    this.prefillTitle,
    this.prefillFirstStep,
  });

  final String? prefillCategory;
  final String? prefillTitle;
  final String? prefillFirstStep;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  static const _categories = <String>[
    'Здоровье',
    'Музыка',
    'Карьера',
    'Отношения',
    'Учёба',
    'Творчество',
    'Помощь другим',
    'Красота',
    'Деньги',
    'Спорт',
  ];

  final _titleC = TextEditingController();
  final _stepC = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.prefillCategory ?? _categories.first;
    _titleC.text = widget.prefillTitle ?? '';
    _stepC.text = widget.prefillFirstStep ?? '';
  }

  @override
  void dispose() {
    _titleC.dispose();
    _stepC.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleC.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название цели')));
      return;
    }
    final goal = Goal(
      id: const Uuid().v4(),
      category: _selectedCategory ?? _categories.first,
      title: title,
      firstStep: _stepC.text.trim().isEmpty ? null : _stepC.text.trim(),
      progress: 0.0,
      isCompleted: false,
    );
    Navigator.pop(context, goal);
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
                // top bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Создать цель',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),

                // Категория
                const Text(
                  'Категория',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((c) {
                    final isSel = c == _selectedCategory;
                    return ChoiceChip(
                      label: Text(c),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                      ),
                      selectedColor: const Color(0xFF7EF091),
                      backgroundColor: Colors.white24,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSel ? Colors.transparent : Colors.white38,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Название цели
                const Text(
                  'Название цели',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                _GlassField(
                  controller: _titleC,
                  hint: 'Например: Вернуть музыку в день',
                ),

                const SizedBox(height: 14),

                // Первый шаг
                const Text(
                  'Первый шаг',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                _GlassField(
                  controller: _stepC,
                  hint: 'Например: 10 минут сыграть на гитаре',
                ),

                const Spacer(),

                AppButton(
                  text: 'Сохранить',
                  kind: AppButtonKind.green,
                  onTap: _save,
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Отмена',
                  kind: AppButtonKind.ghost,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white70),
        ),
      ),
    );
  }
}
