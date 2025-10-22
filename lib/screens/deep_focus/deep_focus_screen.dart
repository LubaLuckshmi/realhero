import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:realhero/widgets/background_stars.dart';
import 'package:realhero/screens/deep_focus/deep_focus_result_screen.dart';
import 'package:realhero/services/deep_focus_service.dart';
import 'package:realhero/models/deep_focus.dart';
import 'package:realhero/viewmodels/home_viewmodel.dart';

class DeepFocusScreen extends StatefulWidget {
  const DeepFocusScreen({super.key});

  @override
  State<DeepFocusScreen> createState() => _DeepFocusScreenState();
}

class _DeepFocusScreenState extends State<DeepFocusScreen> {
  final _scroll = ScrollController();

  // пресеты
  final _dislikeOpts = const [
    'Хаос и спешка',
    'Мало энергии',
    'Ощущение пустоты',
    'Мало результатов',
    'Много прокрастинации',
    'Залипаю в телефон',
  ];
  final _priorityOpts = const [
    'Здоровье',
    'Семья/отношения',
    'Карьера/финансы',
    'Творчество',
    'Спокойствие',
    'Свобода',
  ];
  final _meaningOpts = const [
    'Помогать людям',
    'Создавать ценность',
    'Исследовать и учиться',
    'Строить своё',
    'Любить и быть рядом',
    'Оставить след',
  ];
  final _noFearOpts = const [
    'Запустить проект',
    'Поменять работу',
    'Переехать',
    'Начать творить',
    'Поставить границы',
    'Попросить о помощи',
  ];

  // выборы
  final _dislikeSel = <String>{};
  final _prioritySel = <String>{};
  final _meaningSel = <String>{};
  final _noFearSel = <String>{};

  // «свой вариант»
  final _dislikeCustom = TextEditingController();
  final _priorityCustom = TextEditingController();
  final _meaningCustom = TextEditingController();
  final _noFearCustom = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _scroll.dispose();
    _dislikeCustom.dispose();
    _priorityCustom.dispose();
    _meaningCustom.dispose();
    _noFearCustom.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    // в каждой секции нужен хотя бы один пункт (или свой)
    if (_dislikeSel.isEmpty && _dislikeCustom.text.trim().isEmpty) {
      _snack(
        'Коротко отметь, что не нравится — выбери вариант или напиши свой.',
      );
      return;
    }
    if (_prioritySel.isEmpty && _priorityCustom.text.trim().isEmpty) {
      _snack('Отметь, что для тебя главное — выбери вариант или напиши свой.');
      return;
    }
    if (_meaningSel.isEmpty && _meaningCustom.text.trim().isEmpty) {
      _snack('Коротко — в чём смысл?');
      return;
    }
    if (_noFearSel.isEmpty && _noFearCustom.text.trim().isEmpty) {
      _snack('Что сделал(а) бы без страха — выбери или напиши.');
      return;
    }

    setState(() => _loading = true);

    final raw = DeepFocusInputRaw(
      dislikeChoices: _dislikeSel.toList(),
      priorityChoices: _prioritySel.toList(),
      meaningChoices: _meaningSel.toList(),
      noFearChoices: _noFearSel.toList(),
      dislikeCustom: _dislikeCustom.text.trim().isEmpty
          ? null
          : _dislikeCustom.text.trim(),
      priorityCustom: _priorityCustom.text.trim().isEmpty
          ? null
          : _priorityCustom.text.trim(),
      meaningCustom: _meaningCustom.text.trim().isEmpty
          ? null
          : _meaningCustom.text.trim(),
      noFearCustom: _noFearCustom.text.trim().isEmpty
          ? null
          : _noFearCustom.text.trim(),
    );

    final advice = await DeepFocusService.generate(raw: raw);

    if (!mounted) return;
    setState(() => _loading = false);

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => DeepFocusResultScreen(advice: advice)),
    );

    if (!mounted) return;

    if (result is DeepFocusCreateGoal) {
      // создаём цель прямо отсюда
      final vm = context.read<HomeViewModel>();
      await vm.addManualGoal(
        title: result.title,
        firstStep: result.firstStep,
        category: 'фокус недели',
      );
      // закрываемся с успехом -> Home подтянет профиль
      Navigator.of(context).pop(true);
      return;
    }

    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // appbar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Глубокий фокус (ИИ)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Отметь 1–3 пункта и при желании добавь свой вариант. Мы сделаем выжимку и совет на неделю.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _block(
                            title: 'Что не нравится?',
                            options: _dislikeOpts,
                            selected: _dislikeSel,
                            controller: _dislikeCustom,
                          ),
                          const SizedBox(height: 14),
                          _block(
                            title: 'Что для тебя главное?',
                            options: _priorityOpts,
                            selected: _prioritySel,
                            controller: _priorityCustom,
                          ),
                          const SizedBox(height: 14),
                          _block(
                            title: 'В чём смысл?',
                            options: _meaningOpts,
                            selected: _meaningSel,
                            controller: _meaningCustom,
                          ),
                          const SizedBox(height: 14),
                          _block(
                            title: 'Если бы не боялся(ась)…',
                            options: _noFearOpts,
                            selected: _noFearSel,
                            controller: _noFearCustom,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _run,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2CC796),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Получить выжимку и совет'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _block({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              FilterChip(
                label: Text(opt),
                selected: selected.contains(opt),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      if (selected.length < 3) selected.add(opt);
                    } else {
                      selected.remove(opt);
                    }
                  });
                },
                selectedColor: const Color(0xFF2CC796).withValues(alpha: 0.25),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selected.contains(opt) ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Свой вариант (необязательно)',
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}
