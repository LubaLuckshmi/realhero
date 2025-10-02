import 'package:flutter/foundation.dart';

/// Храним ответы пользователя на шагах онбординга
class OnboardingViewModel extends ChangeNotifier {
  String? _fearChoice; // Q1: что бы сделала, если бы не боялась
  final Set<String> _inspirations = {}; // Q2: что вдохновляет
  String? _mood; // Q3: как себя чувствуешь (СТРОКА, не int!)

  // --- Getters
  String? get fearChoice => _fearChoice;
  Set<String> get inspirations => _inspirations;
  String? get mood => _mood;

  // --- Mutations
  void setFear(String value) {
    _fearChoice = value;
    notifyListeners();
  }

  void toggleInspiration(String value) {
    if (_inspirations.contains(value)) {
      _inspirations.remove(value);
    } else {
      _inspirations.add(value);
    }
    notifyListeners();
  }

  void setMood(String value) {
    _mood = value; // строка: '😔 Плохо' | '🙂 Нормально' | '😃 Отлично'
    notifyListeners();
  }

  void reset() {
    _fearChoice = null;
    _inspirations.clear();
    _mood = null;
    notifyListeners();
  }

  bool get canGoNextFromQ1 => (_fearChoice != null && _fearChoice!.isNotEmpty);
}
