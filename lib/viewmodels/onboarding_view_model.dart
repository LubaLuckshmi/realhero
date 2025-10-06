import 'package:flutter/foundation.dart';

/// Храним ответы пользователя на шагах онбординга
class OnboardingViewModel extends ChangeNotifier {
  // Q1
  String? _fearChoice; // что бы сделала, если бы не боялась

  // Q2
  final Set<String> _inspirations = {}; // что вдохновляет (мультивыбор)

  // Q2b (НОВЫЙ)
  final Set<String> _energy = {}; // что даёт энергию (мультивыбор)

  // Q3
  String? _mood; // как себя чувствуешь (одиночный выбор)

  // --- Getters
  String? get fearChoice => _fearChoice;
  Set<String> get inspirations => _inspirations;
  Set<String> get energy => _energy;
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

  void toggleEnergy(String value) {
    if (_energy.contains(value)) {
      _energy.remove(value);
    } else {
      _energy.add(value);
    }
    notifyListeners();
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

  // Валидация по шагам
  bool get canGoNextFromQ1 => (_fearChoice != null && _fearChoice!.isNotEmpty);
  bool get canGoNextFromQ2 => _inspirations.isNotEmpty;
  bool get canGoNextFromQ2b => _energy.isNotEmpty;
  bool get canGoNextFromQ3 => (_mood != null && _mood!.isNotEmpty);
}
