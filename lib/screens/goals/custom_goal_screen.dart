import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/background_stars.dart';
import '../home/home_screen.dart';

/// Экран: пользователь сам формулирует цель и первый шаг.
class CustomGoalScreen extends StatefulWidget {
  const CustomGoalScreen({super.key, this.prefilledCategory});

  /// Можно передать из экрана подсказок (тег/категория).
  final String? prefilledCategory;

  @override
  State<CustomGoalScreen> createState() => _CustomGoalScreenState();
}

class _CustomGoalScreenState extends State<CustomGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _stepCtrl = TextEditingController();
  late String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.prefilledCategory;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<HomeViewModel>();

    await vm.addManualGoal(
      title: _titleCtrl.text.trim(),
      category: (_category ?? '').trim().isEmpty ? null : _category!.trim(),
      firstStep: _stepCtrl.text.trim().isEmpty ? null : _stepCtrl.text.trim(),
    );

    if (!mounted) return;

    // Возвращаемся на Home c очисткой стека и показываем тост
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Цель сохранена 👌')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundStars(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аппбар
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Своя цель',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Сформулируй цель и первый шаг, с которого начнёшь.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // Форма
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Категория (необязательно)
                          TextFormField(
                            initialValue: _category,
                            onChanged: (v) => _category = v,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              context,
                              'Категория (необязательно)',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Название цели
                          TextFormField(
                            controller: _titleCtrl,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              context,
                              'Название цели *',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Введите название цели'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Первый шаг
                          TextFormField(
                            controller: _stepCtrl,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              context,
                              'Первый шаг (необязательно)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2CC796),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Colors.white60),
      labelText: null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}
