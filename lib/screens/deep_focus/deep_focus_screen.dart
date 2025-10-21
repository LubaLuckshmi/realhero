// lib/screens/deep_focus/deep_focus_screen.dart
import 'package:flutter/material.dart';
import 'package:realhero/widgets/background_stars.dart';
import 'package:realhero/screens/deep_focus/deep_focus_result_screen.dart';
import 'package:realhero/services/deep_focus_service.dart';

class DeepFocusScreen extends StatefulWidget {
  const DeepFocusScreen({super.key});

  @override
  State<DeepFocusScreen> createState() => _DeepFocusScreenState();
}

class _DeepFocusScreenState extends State<DeepFocusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  final _dislike = TextEditingController();
  final _priority = TextEditingController();
  final _meaning = TextEditingController();
  final _noFear = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _scroll.dispose();
    _dislike.dispose();
    _priority.dispose();
    _meaning.dispose();
    _noFear.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await DeepFocusService.generate(
      dislike: _dislike.text.trim(),
      priority: _priority.text.trim(),
      meaning: _meaning.text.trim(),
      noFear: _noFear.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DeepFocusResultScreen(advice: res)),
    );
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
                      onPressed: () => Navigator.pop(context),
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
                  'Ответь коротко. Мы соберём выжимку и дадим персональный совет на неделю.',
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _qa(
                              label: 'Что тебе не нравится в текущей жизни?',
                              ctrl: _dislike,
                              minLines: 2,
                            ),
                            const SizedBox(height: 12),
                            _qa(
                              label: 'Что для тебя главное?',
                              ctrl: _priority,
                              minLines: 1,
                            ),
                            const SizedBox(height: 12),
                            _qa(
                              label: 'В чём смысл?',
                              ctrl: _meaning,
                              minLines: 1,
                            ),
                            const SizedBox(height: 12),
                            _qa(
                              label:
                                  'Что бы ты сделал(а), если бы не боялся(ась)?',
                              ctrl: _noFear,
                              minLines: 2,
                            ),
                          ],
                        ),
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

  Widget _qa({
    required String label,
    required TextEditingController ctrl,
    int minLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      minLines: minLines,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Пожалуйста, ответь кратко' : null,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
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
    );
  }
}
