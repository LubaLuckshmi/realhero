import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/main.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/store.dart';
import 'package:realhero/leia_client.dart';
import 'package:realhero/easy_flow.dart';

class Disk implements JsonStorage {
  final data = <String,String>{};
  @override Future<String?> read(String k) async => data[k];
  @override Future<void> write(String k, String v) async { data[k] = v; }
  @override Future<void> remove(String k) async { data.remove(k); }
}

Map<String,dynamic> choice(String text, List<String> options) => {
  'reply': text, 'needsClarification': true, 'quickReplies': options, 'mission': null,
};

void main() {
  test('Russian minute endings', () {
    expect([1,2,5,11,21].map(minuteLabel).toList(), ['1 минута','2 минуты','5 минут','11 минут','21 минута']);
  });
  testWidgets('choice, uncertainty, prepared action and result continue without repeated onboarding', (tester) async {
    tester.view.physicalSize = const Size(900,1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final disk = Disk(); final store = RealHeroStore(storage: disk); await store.load();
    store.configureServer('https://example.test', 'fixture-token');
    store.setGoal('Коллекция ёлочных игрушек');
    store.acceptPlan(choice('Что хочется попробовать?', ['Домик','Шар','Пока ничего']));
    var calls = 0;
    final client = LeiaClient(transport: (uri, headers, body) async {
      calls++;
      final request = jsonDecode(body) as Map;
      expect(request['version'], 2);
      expect(request['context']['interaction'], isNull);
      expect(request['context'].containsKey('settings'), false);
      if (calls == 1) {
        expect(request['message'], 'Пока ничего');
        return LeiaHttpResponse(200, jsonEncode(choice('Может, что-то другое?', ['Фонарик','Звезда','Не знаю'])));
      }
      if (calls == 2) {
        expect(request['message'], 'Фонарик');
        return LeiaHttpResponse(200, jsonEncode({
          'reply':'Эскиз готов.', 'needsClarification':false, 'quickReplies':[],
          'mission': {'id':'one', 'goalId':store.goal!.id, 'title':'Выбери деталь фонарика',
            'why':'Продолжает выбранную идею фонарика.', 'minutes':1, 'oneAction':'Отметь одну деталь в готовом эскизе.',
            'lightAction':'Посмотри эскиз.', 'steps':[{'id':'one','title':'Выбери деталь','hint':'Эскиз ниже.'}],
            'materials':[{'id':'sketch','kind':'draft','label':'Эскиз','text':'Маленький золотой фонарик с синим стеклом и звёздочкой на крыше.'}]}
        }));
      }
      expect(request['context']['missions'].last['outcome']['facts'], 'Нравится звёздочка');
      return LeiaHttpResponse(200, jsonEncode(choice('Следующая деталь?', ['Синее стекло','Прозрачное','Пока ничего'])));
    });
    await tester.pumpWidget(RealHeroApp(store:store, leiaClient:client)); await tester.pumpAndSettle();
    await tester.tap(find.text('Пока ничего')); await tester.pumpAndSettle();
    expect(find.text('Сейчас есть силы на маленький шаг?'), findsNothing);
    expect(find.text('Фонарик'), findsOneWidget);
    await tester.tap(find.text('Фонарик')); await tester.pumpAndSettle();
    await tester.tap(find.text('Сегодня').last); await tester.pumpAndSettle();
    expect(find.text('Твой проект'), findsOneWidget);
    await tester.tap(find.text('Ранее подготовленная миссия'));await tester.pumpAndSettle();
    await tester.tap(find.text('Выбери деталь фонарика'));await tester.pumpAndSettle();
    expect(find.text('Открыть подготовленную миссию'), findsNothing);
    expect(find.text('Маленький золотой фонарик с синим стеклом и звёздочкой на крыше.'), findsOneWidget);
    store.completeMission(outcome:OutcomeKind.partial,facts:'Нравится звёздочка',actualMinutes:0,difficulty:2,actionTaken:true,timeReported:false,difficultyReported:false);
    await store.flush(); final restored = RealHeroStore(storage:disk); await restored.load();
    expect(restored.currentMission!.outcome!.facts, 'Нравится звёздочка');

    expect(restored.currentMission!.outcome!.timeReported, false);
    expect(restored.currentMission!.outcome!.difficultyReported, false);
    expect(restored.settings.accessToken,'fixture-token');
    expect(tester.takeException(),isNull);
  });
  testWidgets('declined mission is replaced by clear empty state', (tester) async {
    final store = RealHeroStore(storage:Disk()); await store.load();
    store.setGoal('Своя идея');
    store.acceptPlan({'reply':'Готово', 'mission':DemoScenario.invitation(store.goal!.id).toJson()});
    store.declineMission('Не подходит');
    await tester.pumpWidget(RealHeroApp(store:store)); await tester.pumpAndSettle();
    expect(find.text('Твой проект'),findsOneWidget);
    expect(find.text('Пригласи Андрея на демо'),findsNothing);
    expect(store.history,hasLength(1));
  });
}

