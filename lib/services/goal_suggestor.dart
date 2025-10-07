import 'dart:math';

/// Простые локальные правила: на основы ответов формируем варианты.
/// Возвращаем список предложений (title + optional firstStep + tags).
class GoalSuggestion {
  final String title;
  final String? firstStep;
  final List<String> tags;

  GoalSuggestion(this.title, {this.firstStep, this.tags = const []});
}

class GoalSuggestor {
  static List<GoalSuggestion> suggest({
    required String? fearChoice, // Q1
    required Set<String> inspirations, // Q2
    Set<String>? energy, // (добавим позже, может быть пусто)
    required String? mood, // Q3
  }) {
    final rnd = Random();
    final List<GoalSuggestion> out = [];

    // 1) По страху/намерению (Q1)
    if ((fearChoice ?? '').contains('тест')) {
      out.add(
        GoalSuggestion(
          'Пройти короткий профориентационный тест',
          firstStep: 'Выбрать тест (15–20 мин) и запланировать время сегодня',
          tags: ['самопознание', 'выбор пути'],
        ),
      );
    }
    if ((fearChoice ?? '').contains('сменила сферу')) {
      out.add(
        GoalSuggestion(
          'Исследовать новую сферу деятельности',
          firstStep: 'Найти 3 вакансии/курса и выписать требования',
          tags: ['карьера', 'исследование'],
        ),
      );
    }
    if ((fearChoice ?? '').contains('отдохнуть')) {
      out.add(
        GoalSuggestion(
          'Сделать план восстановления',
          firstStep: 'Выбрать 1 активность для отдыха на этой неделе',
          tags: ['баланс', 'здоровье'],
        ),
      );
    }

    // 2) По вдохновляющим источникам (Q2)
    if (inspirations.contains('Природа')) {
      out.add(
        GoalSuggestion(
          'Больше времени на природе',
          firstStep: 'Запланировать прогулку в парке на выходных',
          tags: ['природа', 'энергия'],
        ),
      );
    }
    if (inspirations.contains('Искусство')) {
      out.add(
        GoalSuggestion(
          'Прокачать творческую рутину',
          firstStep: '15 минут скетч/музыки/фото каждый день',
          tags: ['творчество'],
        ),
      );
    }
    if (inspirations.contains('Люди')) {
      out.add(
        GoalSuggestion(
          'Расширять тёплый круг общения',
          firstStep: 'Назначить встречу/звонок одному близкому',
          tags: ['отношения'],
        ),
      );
    }
    if (inspirations.contains('Музыка')) {
      out.add(
        GoalSuggestion(
          'Вернуть музыку в день',
          firstStep: 'Собрать плейлист «энергия» на неделю',
          tags: ['радость'],
        ),
      );
    }
    if (inspirations.contains('Деньги')) {
      out.add(
        GoalSuggestion(
          'Финансовая привычка 1%',
          firstStep: 'Откладывать 1% дохода на отдельный счёт',
          tags: ['деньги', 'привычки'],
        ),
      );
    }
    if (inspirations.contains('Эмоции')) {
      out.add(
        GoalSuggestion(
          'Дневник эмоций 5 минут',
          firstStep: 'Вечером записать 3 эмоции и их причины',
          tags: ['осознанность'],
        ),
      );
    }
    if (inspirations.contains('Помощь другим')) {
      out.add(
        GoalSuggestion(
          'Доброе дело каждую неделю',
          firstStep: 'Выбрать мини-волонтёрство / помощь близким',
          tags: ['смысл', 'сообщество'],
        ),
      );
    }
    if (inspirations.contains('Красота')) {
      out.add(
        GoalSuggestion(
          'Микро-эстетика дня',
          firstStep: 'Найти и сфотографировать «красоту дня»',
          tags: ['вкус к жизни'],
        ),
      );
    }

    // 3) По настроению (Q3)
    switch (mood) {
      case '😔 Плохо':
        out.add(
          GoalSuggestion(
            'Ритуал заботы о себе',
            firstStep: 'Составить список 5 простых штук «мне лучше»',
            tags: ['поддержка'],
          ),
        );
        break;
      case '🙂 Нормально':
        out.add(
          GoalSuggestion(
            '1 маленький шаг к цели ежедневно',
            firstStep: 'Выбрать мини-задачу на 10 минут',
            tags: ['привычка', 'движение'],
          ),
        );
        break;
      case '😃 Отлично':
        out.add(
          GoalSuggestion(
            'Шагаем смелее',
            firstStep: 'Выбрать «самый полезный дискомфорт» на неделе',
            tags: ['рост'],
          ),
        );
        break;
    }

    // Если вдруг пусто — базовые универсальные идеи
    if (out.isEmpty) {
      out.addAll([
        GoalSuggestion(
          'Определить 1 ближайшую цель на 2 недели',
          firstStep: 'Записать результат и 3 шага',
          tags: ['фокус'],
        ),
        GoalSuggestion(
          'Ежедневный «шаг 10 минут»',
          firstStep: 'Выбрать время и поставить напоминание',
          tags: ['привычка'],
        ),
      ]);
    }

    // Перемешаем слегка
    out.shuffle(rnd);
    // Вернём до 6 штук
    return out.take(6).toList();
  }
}
