/// numerology_service.dart — простая заглушка рекомендаций по дате рождения
class NumerologyService {
  List<String> suggestGoals(DateTime birthDate) {
    final s = (birthDate.year + birthDate.month + birthDate.day) % 9;
    if (s <= 3) return ['Утренние страницы 10 мин', 'Дыхательная практика 5 мин'];
    if (s <= 6) return ['Тренировка 15 мин', 'Учить 10 новых слов'];
    return ['Медитация 7 мин', '30 минут творчества'];
  }
}
