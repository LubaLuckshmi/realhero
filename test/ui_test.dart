import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/main.dart';
import 'package:realhero/store.dart';
import 'package:realhero/discovery.dart';
import 'package:realhero/process_view.dart';

class UiMemoryStorage implements JsonStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

final captureKey = GlobalKey();

Future<RealHeroStore> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  UiMemoryStorage? disk,
  bool demo = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final store = RealHeroStore(storage: disk ?? UiMemoryStorage());
  await store.load();
  if (demo) store.loadDemo();
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: RealHeroApp(store: store),
    ),
  );
  await tester.pumpAndSettle();
  // Asset codec work runs outside the fake clock. Pump the decoded bitmaps.
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return store;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> screenshot(WidgetTester tester, String name) async {
  final directory = Platform.environment['REALHERO_CAPTURE_DIR'];
  if (directory == null || directory.isEmpty) return;
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
  final boundary =
      captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final rendered = await boundary.toImage(pixelRatio: 2);
    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
    rendered.dispose();
  });
}

void main() {
  setUpAll(() async {
    // Load Flutter's bundled native Android font instead of Ahem, so both CI
    // layout assertions and optional captures use the app's real text metrics.
    var directory = Platform.environment['REALHERO_FONT_DIR'];
    if (directory == null || directory.isEmpty) {
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config = jsonDecode(await configFile.readAsString()) as Map;
      final packages = config['packages'] as List;
      final flutterPackage = packages.cast<Map>().firstWhere(
        (p) => p['name'] == 'flutter',
      );
      final packageUri = configFile.uri.resolve(
        flutterPackage['rootUri'] as String,
      );
      final sdkRoot = Directory.fromUri(packageUri).parent.parent;
      directory = '${sdkRoot.path}/bin/cache/artifacts/material_fonts';
    }
    for (final font in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(font.$1);
      final bytes = await File('$directory/${font.$2}').readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('context stays folded and uncertainty continues the existing idea', (tester) async {
    final store = await pumpApp(tester);
    store.setGoal('Хочу свою коллекцию ёлочных игрушек');
    final goalId = store.goal!.id;
    store.acceptPlan({
      'reply': 'Хочется сначала посмотреть три варианта?',
      'understanding': 'Идея коллекции уже есть; детали пока открыты.',
      'assumptions': ['Возможно, сначала удобнее посмотреть готовые варианты.'],
      'needsClarification': true,
      'quickReplies': ['Да', 'Нет', 'Не знаю'],
    });
    await tester.pumpAndSettle();
    await tapText(tester, 'Лея');
    expect(find.text('Твой Game Master'), findsNothing);
    expect(find.text('Идея коллекции уже есть; детали пока открыты.'), findsNothing);
    expect(find.text('Контекст Леи'), findsOneWidget);
    await tapText(tester, 'Контекст Леи');
    expect(find.text('Идея коллекции уже есть; детали пока открыты.'), findsOneWidget);
    await tapText(tester, 'Контекст Леи');
    await tapText(tester, 'Не знаю');
    expect(find.text('Сейчас есть силы на маленький шаг?'), findsOneWidget);
    expect(store.state.discovery.existingGoalId, goalId);
    expect(store.goal!.id, goalId);
    expect(store.state.chat.last.text, 'Не знаю');
    expect(store.profile.xp, 0);
  });

  for (final size in [const Size(320, 700), const Size(900, 1200)]) {
    testWidgets('short discovery uses taps and restores at $size', (tester) async {
      final disk = UiMemoryStorage();
      final store = await pumpApp(tester, disk: disk, size: size);
      await tapText(tester, 'Пока не знаю, чего хочу');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Сейчас есть силы на маленький шаг?'), findsOneWidget);
      await tapText(tester, 'Нет');
      expect(find.text('Найдётся пять минут без спешки?'), findsOneWidget);
      await store.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final reopened = await pumpApp(tester, disk: disk, size: size);
      expect(find.text('Найдётся пять минут без спешки?'), findsOneWidget);
      expect(reopened.state.discovery.answers['energy'], DiscoveryAnswer.no);
      await tapText(tester, 'Не знаю');
      await tapText(tester, 'Нет');
      expect(find.text('Что сейчас чуть ближе?'), findsOneWidget);
      await tapText(tester, 'Пока не знаю');
      expect(find.text('Подготовить мой шаг'), findsOneWidget);
      expect(reopened.goal, isNull);
      expect(reopened.state.chat, isEmpty);
      expect(reopened.profile.xp, 0);
      await screenshot(tester, 'discovery_review_${size.width.toInt()}');
      await tapText(tester, 'Не сейчас');
      expect(find.text('Продолжить короткое знакомство'), findsOneWidget);
      expect(reopened.state.discovery.paused, true);
      expect(reopened.goal, isNull);
    });
  }

  testWidgets(
    'demo full loop edits existing preparation, pauses, records no reply, updates path/profile and restores',
    (tester) async {
      final disk = UiMemoryStorage();
      final store = await pumpApp(tester, disk: disk);
      expect(store.currentMission, isNull);
      expect(find.text('Твоя жизнь.\nТвой следующий ход.'), findsOneWidget);
      await tapText(tester, 'Попробовать демосценарий');
      expect(store.isDemo, true);
      expect(find.text('ДЕМО · пример из макета'), findsOneWidget);
      expect(find.text('Пригласи Андрея на демо'), findsOneWidget);
      final firstId = store.currentMission!.id;
      await screenshot(tester, '01_today');

      await tapText(tester, 'Посмотреть подготовку');
      expect(find.text('Всё уже готово'), findsOneWidget);
      await tester.ensureVisible(find.text('Миссия').first);
      await tester.pumpAndSettle();
      await screenshot(tester, '02_mission');
      final material = store.currentMission!.materials.first;
      await tapText(tester, material.label);
      expect(find.text('Подготовленный материал'), findsOneWidget);
      const edited =
          'Андрей, два экрана готовы. Посмотришь в пятницу? Три вопроса уже подготовлены.';
      await tester.enterText(find.byType(TextField).last, edited);
      await tapText(tester, 'Сохранить изменения');
      expect(store.currentMission!.materials.first.text, edited);
      expect(store.currentMission!.materials.first.edited, true);
      await tapText(tester, 'Перейти к действию');
      expect(store.currentMission!.status, MissionStatus.active);
      await tester.ensureVisible(find.text('В процессе').first);
      await tester.pumpAndSettle();
      await screenshot(tester, '03_in_progress');
      await tester.ensureVisible(find.byIcon(Icons.note_outlined));
      await tester.tap(find.byIcon(Icons.note_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'Приглашение отправлено; не дублировать сегодня.',
      );
      await tapText(tester, 'Сохранить');
      await tester.ensureVisible(find.byIcon(Icons.pause));
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      expect(store.currentMission!.status, MissionStatus.paused);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(store.currentMission!.status, MissionStatus.active);
      await tapText(tester, 'Зафиксировать результат');
      await tester.tap(find.byType(DropdownButtonFormField<OutcomeKind>));
      await tester.pumpAndSettle();
      await tapText(tester, 'Ответа пока нет');
      final fields = find.byType(TextField);
      await tester.enterText(
        fields.at(0),
        'Приглашение отправлено, ответа пока нет',
      );
      await tester.enterText(
        fields.at(1),
        'Нужен запас времени до повторного обращения',
      );
      await tester.enterText(fields.at(2), '3');
      await tapText(tester, 'Действие выполнено или попытка состоялась');
      await tapText(tester, 'Сохранить результат');
      expect(find.text('Опыт сохранён'), findsOneWidget);
      expect(store.lastOutcome!.kind, OutcomeKind.noReply);
      expect(store.state.realChanges, isEmpty);
      expect(store.currentMission!.id, isNot(firstId));
      expect(store.currentMission!.title, 'Оставь приглашению время');
      expect(store.profile.xp, 40);
      await screenshot(tester, '06_result');
      await tapText(tester, 'Посмотреть следующий ход');
      expect(find.text('Оставь приглашению время'), findsOneWidget);
      expect(find.text('Отправить Андрею'), findsNothing);
      await tapText(tester, 'Выбрать день');
      expect(find.text('Когда вернуться к миссии?'), findsOneWidget);
      await tapText(tester, 'Сохранить');
      expect(store.currentMission!.status, MissionStatus.deferred);
      expect(store.currentMission!.deferredUntil, isNotNull);
      await tapText(tester, 'Путь');
      await tester.ensureVisible(find.text('Твой путь'));
      await tester.pumpAndSettle();
      expect(find.text('Твой путь'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      await screenshot(tester, '04_path');
      await tapText(tester, 'Профиль');
      await tester.ensureVisible(find.text('Профиль').first);
      await tester.pumpAndSettle();
      expect(find.text('40 / 1000 XP'), findsOneWidget);
      await screenshot(tester, '05_profile');
      await store.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = await pumpApp(tester, disk: disk);
      expect(restored.currentMission!.title, 'Оставь приглашению время');
      expect(restored.currentMission!.status, MissionStatus.deferred);
      expect(restored.currentMission!.deferredUntil, isNotNull);
      final old = restored.state.missions.firstWhere((m) => m.id == firstId);
      expect(old.materials.first.text, edited);
      expect(old.note, contains('не дублировать'));
      expect(old.outcome!.facts, 'Приглашение отправлено, ответа пока нет');
      expect(old.outcome!.actualMinutes, 3);
      expect(restored.profile.xp, 40);
    },
  );

  testWidgets(
    'personal onboarding failure preserves input without fake AI mission',
    (tester) async {
      final disk = UiMemoryStorage();
      final store = await pumpApp(tester, disk: disk);
      await tapText(tester, 'Я знаю, чего хочу');
      const goal =
          'Хочу научиться рисовать город. Есть 20 минут вечером и бумага, курсов ещё не пробовал.';
      await tester.enterText(find.byType(TextField), goal);
      await tapText(tester, 'Найти первый шаг');
      await tester.pumpAndSettle();
      expect(store.goal!.context, goal);
      expect(store.isDemo, false);
      expect(store.currentMission, isNull);
      expect(store.state.chat.last.text, goal);
      expect(find.textContaining('Подключи сервер RealHero'), findsOneWidget);
      expect(find.text('Проверить подключение'), findsOneWidget);
      await store.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = await pumpApp(tester, disk: disk);
      expect(restored.goal!.context, goal);
      expect(restored.state.chat.last.text, goal);
      expect(restored.state.missions, isEmpty);
    },
  );

  testWidgets('external share is a handoff, never reported as delivery', (
    tester,
  ) async {
    final store = await pumpApp(tester, demo: true);
    MethodCall? handedOff;
    const channel = MethodChannel('realhero/actions');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          handedOff = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tapText(tester, 'Отправить Андрею');
    expect(find.text('Проверь сообщение'), findsOneWidget);
    expect(find.textContaining('RealHero не узнает'), findsOneWidget);
    await tapText(tester, 'Передать в другое приложение');
    expect(handedOff!.method, 'shareText');
    expect(
      (handedOff!.arguments as Map)['text'],
      store.currentMission!.materials.first.text,
    );
    expect(store.currentMission!.status, MissionStatus.active);
    expect(store.currentMission!.actionConfirmed, false);
    expect(store.profile.xp, 0);
  });

  for (final attempted in [false, true]) {
    testWidgets(
      attempted
          ? 'negative attempt changes next mission without fake life success'
          : 'recording an unperformed action awards zero XP',
      (tester) async {
        final store = await pumpApp(tester, demo: true);
        await tapText(tester, 'Посмотреть подготовку');
        await tapText(tester, 'Перейти к действию');
        await tapText(tester, 'Зафиксировать результат');
        if (attempted) {
          await tester.tap(find.byType(DropdownButtonFormField<OutcomeKind>));
          await tester.pumpAndSettle();
          await tapText(tester, 'Отказ / не получилось');
        }
        await tester.enterText(
          find.byType(TextField).at(0),
          attempted
              ? 'Андрей отказался: сейчас не готов смотреть прототип'
              : 'Сегодня приглашение не отправлено',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          attempted
              ? 'Для длинного показа неудобный момент'
              : 'Требуется удобный момент, действие ещё не выполнено',
        );
        await tester.enterText(
          find.byType(TextField).at(2),
          attempted ? '4' : '0',
        );
        if (attempted) {
          await tapText(tester, 'Действие выполнено или попытка состоялась');
          await tester.ensureVisible(find.byType(Slider));
          await tester.pumpAndSettle();
          final rect = tester.getRect(find.byType(Slider));
          await tester.tapAt(Offset(rect.right - 25, rect.center.dy));
          await tester.pumpAndSettle();
        }
        await tapText(tester, 'Сохранить результат');
        expect(store.lastOutcome!.actionTaken, attempted);
        expect(store.profile.xp, attempted ? 40 : 0);
        expect(store.profile.completedCount, attempted ? 1 : 0);
        expect(store.state.realChanges, isEmpty);
        if (attempted) {
          expect(store.lastOutcome!.kind, OutcomeKind.negative);
          expect(store.lastOutcome!.difficulty, greaterThanOrEqualTo(4));
          expect(
            store.currentMission!.title,
            'Сократи показ до одного вопроса',
          );
          expect(store.currentMission!.contactNames, isEmpty);
        }
        expect(find.text('Опыт сохранён'), findsOneWidget);
      },
    );
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(900, 1200),
    const Size(1200, 800),
  ]) {
    testWidgets('process layout, chat return and question resume at $size', (tester) async {
      final disk = UiMemoryStorage();
      final store = await pumpApp(tester, disk: disk, size: size, demo: true);
      store.completeMission(
        outcome: OutcomeKind.positive,
        facts: 'В демо Андрей подтвердил показ',
        actualMinutes: 2,
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Посмотреть подготовку');
      await tapText(tester, 'Перейти к действию');
      expect(find.byType(ProcessView), findsOneWidget);
      if (size.width < 760) {
        expect(find.byType(NavigationBar), findsNothing);
      } else {
        expect(find.byType(NavigationRail), findsOneWidget);
      }

      final secondStep = find.byKey(const ValueKey('process-step-1'));
      await tester.ensureVisible(secondStep);
      await tester.tap(secondStep);
      await tester.pumpAndSettle();
      expect(find.text('ВОПРОС 1 ИЗ 3'), findsOneWidget);
      final nextQuestion = find.byTooltip('Следующий вопрос');
      await tester.ensureVisible(nextQuestion);
      await tester.tap(nextQuestion);
      await tester.pumpAndSettle();
      expect(find.text('Что осталось непонятно?'), findsOneWidget);
      expect(store.currentMission!.currentQuestion, 1);
      expect(store.currentMission!.currentStep, 1);
      expect(store.currentMission!.outcome, isNull);
      expect(store.currentMission!.actionConfirmed, false);
      expect(store.profile.xp, 40); // Only the preceding, recorded invitation.
      expect(find.text('Андрей на связи'), findsNothing);
      expect(find.textContaining('Осталось'), findsNothing);

      final focus = tester.getRect(find.byKey(const ValueKey('process-focus')));
      final title = tester.getRect(find.byKey(const ValueKey('process-step-title')));
      expect(focus.top, greaterThan(title.bottom));
      expect(focus.width, lessThan(tester.getSize(find.byType(ProcessView)).width));
      await tester.ensureVisible(find.text('В процессе'));
      await tester.pumpAndSettle();
      await screenshot(tester, 'process_reference_${size.width.toInt()}x${size.height.toInt()}');

      await tapText(tester, 'Написать Лее');
      expect(find.byType(ProcessView), findsNothing);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      expect(find.byType(ProcessView), findsOneWidget);
      expect(find.text('ВОПРОС 2 ИЗ 3'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProcessView), findsNothing);
      expect(find.text('Миссия'), findsOneWidget);
      await tapText(tester, 'Перейти к действию');
      await store.flush();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = await pumpApp(tester, disk: disk, size: size);
      await tapText(tester, 'Вернуться к действию');
      expect(find.text('ВОПРОС 2 ИЗ 3'), findsOneWidget);
      expect(restored.currentMission!.currentQuestion, 1);
      expect(restored.currentMission!.currentStep, 1);
      expect(restored.profile.xp, 40);
      await tester.ensureVisible(find.byKey(const ValueKey('process-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('process-result')));
      await tester.pumpAndSettle();
      expect(find.text('Что произошло?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'long note remains editable above the keyboard on a small phone',
    (tester) async {
      await pumpApp(tester, size: const Size(320, 640), demo: true);
      await tapText(tester, 'Посмотреть подготовку');
      await tapText(tester, 'Перейти к действию');
      await tester.ensureVisible(find.byIcon(Icons.note_outlined));
      await tester.tap(find.byIcon(Icons.note_outlined));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(
        find.byType(TextField).last,
        List.generate(
          8,
          (i) => 'Наблюдение $i: ответ в своих словах',
        ).join('\n'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Сохранить');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(900, 1000),
  ]) {
    testWidgets(
      'all main scenes fit ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final store = await pumpApp(tester, size: size, demo: true);
        await tapText(tester, 'Посмотреть подготовку');
        await tapText(tester, 'Прототип · 2 экрана');
        expect(
          find.text('Демонстрационные материалы · два готовых экрана'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();
        await tapText(tester, 'Перейти к действию');
        await tapText(tester, 'Зафиксировать результат');
        expect(find.text('Что произошло?'), findsOneWidget);
        await tester.ensureVisible(find.text('Сохранить результат'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();
        if (size.width < 760) {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        await tapText(tester, 'Путь');
        await tapText(tester, 'Профиль');
        if (size.width >= 760) {
          expect(find.byType(NavigationRail), findsOneWidget);
          await screenshot(tester, '07_tablet_profile');
        } else {
          expect(find.byType(NavigationBar), findsOneWidget);
        }
        await tapText(tester, 'Лея');
        expect(find.text('Демо Леи'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Демо Леи'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Демо Леи'), findsOneWidget);
        await store.flush();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
