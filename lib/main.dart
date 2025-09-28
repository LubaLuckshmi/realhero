/// main.dart — точка входа приложения
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Если Firebase уже инициализирован — не вызывать повторно
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Игнорируем ошибку дубликата
    } else {
      rethrow;
    }
  }

  runApp(const App());
}
