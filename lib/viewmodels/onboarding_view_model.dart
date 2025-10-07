import 'package:flutter/foundation.dart';

/// Храним ответы пользователя на шагах онбординга
class OnboardingViewModel extends ChangeNotifier {
  // Q1: «А что бы ты сделала, если бы не боялась?»
  String? _fearChoice;

  // Q2: «Что тебя вдохновляет больше всего?» (до 3-х)
  final Set<String> _inspirations = {};

  // Q2b: «Что даёт тебе энергию?» (тоже до 3-х; если экрана ещё нет — просто не используется)
  final Set<String> _energy = {};

  // Q3: «Как ты сейчас себя чувствуешь?»
  String? _mood;

  // ---- getters для UI ----
  String? get fearChoice => _fearChoice;
  Set<String> get inspirations => _inspirations;
  Set<String> get energy => _energy;
  String? get mood => _mood;

  // лимиты выбора для Q2/Q2b
  static const int maxSelect = 3;

  int get selectedInspirations => _inspirations.length;
  int get selectedEnergy => _energy.length;

  // ---- валидация для кнопки «Далее» на шагах ----
  bool get canGoNextFromQ1 =>
      (_fearChoice != null && _fearChoice!.trim().isNotEmpty);
  bool get canGoNextFromQ2 =>
      _inspirations.isNotEmpty && _inspirations.length <= maxSelect;
  bool get canGoNextFromQ2b =>
      _energy.isNotEmpty && _energy.length <= maxSelect;
  bool get canGoNextFromQ3 => (_mood != null && _mood!.trim().isNotEmpty);

  // ---- мутации ----
  void setFear(String value) {
    _fearChoice = value.trim();
    notifyListeners();
  }

  void toggleInspiration(String value) {
    _toggleLimited(_inspirations, value);
  }

  void toggleEnergy(String value) {
    _toggleLimited(_energy, value);
  }

  void setMood(String value) {
    _mood = value;
    notifyListeners();
  }

  void reset() {
    _fearChoice = null;
    _inspirations.clear();
    _energy.clear();
    _mood = null;
    notifyListeners();
  }

  // ---- helpers ----
  void _toggleLimited(Set<String> set, String value) {
    if (set.contains(value)) {
      set.remove(value);
    } else {
      // ограничиваем до maxSelect
      if (set.length >= maxSelect) return;
      set.add(value);
    }
    notifyListeners();
  }
}
