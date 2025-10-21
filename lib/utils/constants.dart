// lib/utils/constants.dart

/// Заголовок приложения
const String appTitle = "RealHero";

/// Единый список категорий целей (используется в нескольких экранах)
const List<String> kGoalCategories = [
  'Здоровье',
  'Музыка',
  'Карьера',
  'Отношения',
  'Учёба',
  'Творчество',
  'Помощь другим',
  'Красота',
  'Деньги',
  'Спорт',
  'Дом',
  'Финансы',
  'Баланс',
  'Навыки',
  'Эмоции',
];

/// Сколько шагов составляет 100% прогресса по цели
const int kStepsPerGoal = 4;

/// Текстовые сообщения (на будущее удобно локализовать)
const String msgEnterGoalTitle = 'Введите название цели';
const String msgSyncedCloud = 'Синхронизировано с облаком';
const String msgGoalSaved = 'Цель сохранена 👌';
const String msgGoalDeleted = 'Цель удалена';
