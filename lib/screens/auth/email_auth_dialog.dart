import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EmailAuthDialog extends StatefulWidget {
  const EmailAuthDialog({super.key});

  @override
  State<EmailAuthDialog> createState() => _EmailAuthDialogState();
}

class _EmailAuthDialogState extends State<EmailAuthDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService().signInOrSignUp(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, user != null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сохранить прогресс?'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Введите email';
                if (!s.contains('@') || !s.contains('.')) {
                  return 'Нужен корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Войти / Создать'),
        ),
      ],
    );
  }
}
