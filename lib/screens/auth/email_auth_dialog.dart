
/// email_auth_dialog.dart — диалог авторизации по email
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EmailAuthDialog extends StatefulWidget {
  const EmailAuthDialog({super.key});

  @override
  State<EmailAuthDialog> createState() => _EmailAuthDialogState();
}

class _EmailAuthDialogState extends State<EmailAuthDialog> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _submit(bool register) async {
    setState(() { _loading = true; _error = null; });
    try {
      if (register) {
        await _auth.register(_email.text.trim(), _pass.text.trim());
      } else {
        await _auth.signIn(_email.text.trim(), _pass.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Войти или зарегистрироваться'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
          if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: TextStyle(color: Colors.red))],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        TextButton(onPressed: _loading ? null : () => _submit(false), child: const Text('Войти')),
        FilledButton(onPressed: _loading ? null : () => _submit(true), child: const Text('Регистрация')),
      ],
    );
  }
}
