import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/main.dart';
import 'package:realhero/store.dart';
import 'package:realhero/leia_client.dart';

class ProjectDisk implements JsonStorage {
 final data=<String,String>{};
 @override Future<String?> read(String k) async=>data[k];
 @override Future<void> write(String k,String v) async {data[k]=v;}
 @override Future<void> remove(String k) async {data.remove(k);}
}
void main(){
 test('project proposals, saved sources, user decisions and old connection survive restart and project switch',()async{
  final disk=ProjectDisk();final s=RealHeroStore(storage:disk);await s.load();
  s.configureServer('https://realhero.example','fixture-token');s.setGoal('Коллекция по Щелкунчику');final first=s.goal!;
  s.appendChat('user','Поищи костюмы');
  s.acceptPlan({'reply':'Примеры готовы','sources':[{'title':'Костюмы театра','url':'https://theatre.example/gallery','imageUrl':'https://images.example/one.jpg'}],
   'workspace':{'summary':'Коллекция по балету','roadmap':[{'title':'Выбрать образы','detail':'Сравнить примеры'}],'drafts':[{'title':'Вариант','text':'Синий и золотой — предложение для обсуждения.'}]}});
  expect(s.currentMission,isNull);expect(s.profile.xp,0);expect(s.project.roadmap,isEmpty);
  expect(s.project.proposedRoadmap,hasLength(1));s.acceptRoadmap();s.toggleStage(s.project.roadmap.first);
  s.saveProjectSource(s.projectChat.last.sources.first);s.saveProjectSource(s.projectChat.last.sources.first);
  s.addProjectItem('Способ изготовления','Хочу работать с мастером',kind:'decision');
  s.editProjectItem(s.project.items.first,'Мой вариант','Красный и золотой');
  s.acceptPlan({'reply':'Можно иначе','workspace':{'summary':'','roadmap':[{'title':'Другой этап','detail':''}],'drafts':[]}});
  expect(s.project.roadmap.first.done,true);expect(s.project.roadmap.first.title,'Выбрать образы');
  s.setGoal('Учить язык');expect(s.project.items,isEmpty);expect(s.projectChat,isEmpty);
  s.appendChat('user','Хочу читать');await s.flush();
  final loaded=RealHeroStore(storage:disk);await loaded.load();loaded.switchProject(loaded.state.goals.firstWhere((g)=>g.id==first.id));
  expect(loaded.project.roadmap.first.done,true);expect(loaded.project.proposedRoadmap.first.title,'Другой этап');
  expect(loaded.project.items.where((x)=>x.kind=='reference'),hasLength(1));expect(loaded.project.items.first.text,'Красный и золотой');
  expect(loaded.projectChat.any((x)=>x.text=='Хочу читать'),false);expect(loaded.projectChat.last.text,'Можно иначе');
  expect(loaded.settings.accessToken,'fixture-token');expect(loaded.profile.xp,0);
 });
 test('client sends only current project and chat rather than another goal or device settings',()async{
  final s=RealHeroStore(storage:ProjectDisk());await s.load();s.configureServer('https://realhero.example','fixture-token');
  s.setGoal('Первый проект');s.appendChat('user','Чужой контекст');s.addProjectItem('Секрет другого проекта','не пересылать');
  s.setGoal('Второй проект');s.appendChat('user','Найди примеры');
  s.acceptPlan({'reply':'Учла','contextUpdates':[{'text':'Есть мастер','sourceQuote':'Помогает мастер'}]});
  final c=LeiaClient(transport:(uri,headers,body)async{
   final j=jsonDecode(body);expect(j['version'],2);expect(j['operation'],'chat');expect(j['search'],true);
   expect(j['context']['settings'],isNull);expect(j['context']['facts'][0]['sourceQuote'],'Помогает мастер');expect(body.contains('Чужой контекст'),false);expect(body.contains('не пересылать'),false);
   return const LeiaHttpResponse(200,'{"reply":"Ответ","mission":null}');
  });
  await c.respond(state:s.state,message:'Найди примеры',search:true);
 });
 test('legacy snapshot migrates without losing accepted mission or settings',(){
  final old=AppState(goal:Goal(id:'old',title:'Старая цель',context:'Мои слова'),chat:[ChatMessage(role:'user',text:'Мои слова')]);
  final json=old.toJson()..remove('projects');final restored=AppState.fromJson(json);expect(restored.projects,isEmpty);expect(restored.chat.single.text,'Мои слова');
 });
 for(final width in [320.0,900.0]){
 testWidgets('search stays in chat and reference saves directly to project at $width',(tester)async{
  tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,1200);addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final store=RealHeroStore(storage:ProjectDisk());await store.load();store.setGoal('Коллекция «Щелкунчик»');store.configureServer('https://realhero.example','fixture-token');
  final client=LeiaClient(transport:(_,headers,body)async{
   final req=jsonDecode(body);expect(req['operation'],'chat');expect(req['message'],'Поищи примеры костюмов в Петербурге');
   return LeiaHttpResponse(200,jsonEncode({'reply':'Вот примеры костюмов для твоей коллекции.','mission':null,'sources':[{'title':'Театральные костюмы','url':'https://theatre.example/gallery','imageUrl':''}],
    'workspace':{'summary':'','roadmap':[{'title':'Согласовать образы','detail':'Сравнить сохранённые примеры'}],'drafts':[]}}));
  });
  await tester.pumpWidget(RealHeroApp(store:store,leiaClient:client));await tester.pumpAndSettle();
  await tester.tap(find.text('Лея').last);await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField),'Поищи примеры костюмов в Петербурге');
  await tester.tap(find.byIcon(Icons.arrow_upward));await tester.pumpAndSettle();
  expect(find.text('Вот примеры костюмов для твоей коллекции.'),findsOneWidget);expect(find.text('Зафиксировать результат'),findsNothing);
  await tester.ensureVisible(find.text('В проект'));await tester.tap(find.text('В проект'));await tester.pumpAndSettle();
  expect(store.project.items,hasLength(1));expect(store.currentMission,isNull);
  await tester.tap(find.text('Путь').last);await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Принять карту'));await tester.tap(find.text('Принять карту'));await tester.pumpAndSettle();
  expect(store.project.roadmap.single.done,false);expect(tester.takeException(),isNull);
  await store.flush();
 });
 }
}
