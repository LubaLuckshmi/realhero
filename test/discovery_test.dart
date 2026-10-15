import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/discovery.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/store.dart';

class DiscoveryDisk implements JsonStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  test('a paused interview restores its actual step, answers and server settings', () async {
    final disk = DiscoveryDisk();
    final first = RealHeroStore(storage: disk);
    await first.load();
    first.configureServer('https://example.invalid', 'test-only-local-access-token');
    first.openGoalEntry();
    first.startDiscovery();
    first.answerDiscovery(DiscoveryAnswer.no);
    first.pauseDiscovery();
    await first.flush();
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.state.discovery.paused, true);
    expect(reopened.state.discovery.answers['energy'], DiscoveryAnswer.no);
    expect(reopened.state.discovery.question.id, 'time');
    expect(reopened.settings.accessToken, 'test-only-local-access-token');
    expect(reopened.goal, isNull);
    expect(reopened.profile.xp, 0);
    reopened.resumeDiscovery();
    expect(reopened.state.discovery.active, true);
  });

  test('all unsure answers allow an exploratory goal without invented preferences or XP', () async {
    final store = RealHeroStore(storage: DiscoveryDisk());
    await store.load();
    store.openGoalEntry();
    store.startDiscovery();
    for (var i = 0; i < 3; i++) { store.answerDiscovery(DiscoveryAnswer.unsure); }
    store.chooseDiscoveryDirection(null);
    final brief = store.finishDiscovery();
    expect(store.goal!.title, 'Найти посильный следующий шаг');
    expect(brief, contains('С направлением пока не определено.'));
    expect(brief, isNot(contains('Сейчас мне ближе:')));
    expect(store.state.discovery.minuteCeiling, 2);
    expect(store.currentMission, isNull);
    expect(store.profile.xp, 0);
    expect(store.profile.achievements, isEmpty);
    expect(store.state.realChanges, isEmpty);
  });

  test('uncertainty preserves an existing idea, conversation and goal ID', () async {
    final store = RealHeroStore(storage: DiscoveryDisk());
    await store.load();
    store.setGoal('Хочу создать коллекцию ёлочных игрушек');
    final id = store.goal!.id;
    store.appendChat('user', 'Пока это только идея');
    store.startDiscovery(keepGoal: true);
    for (var i = 0; i < 3; i++) { store.answerDiscovery(DiscoveryAnswer.no); }
    expect(store.state.discovery.phase, DiscoveryPhase.review);
    store.finishDiscovery();
    expect(store.goal!.id, id);
    expect(store.state.goals, hasLength(1));
    expect(store.state.chat.single.text, 'Пока это только идея');
    expect(store.goal!.context, contains('Сейчас комфортно общаться с людьми? — Нет'));
    expect(store.state.discovery.minuteCeiling, 2);
  });

  test('legacy snapshots do not force existing users through onboarding', () {
    final restored = AppState.fromJson({'version': 1, 'goal': {'id': 'existing', 'title': 'Моя цель'}});
    expect(restored.discovery.active, false);
    expect(restored.goal!.id, 'existing');
    expect(restored.quickReplies, isEmpty);
    expect(restored.needsClarification, false);
  });

  test('corrupt incomplete review returns to the unanswered question', () {
    final restored = DiscoveryState.fromJson({'phase': 'review', 'answers': {'energy': 'no'}});
    expect(restored.phase, DiscoveryPhase.questions);
    expect(restored.question.id, 'time');
    expect(() => restored.brief(), throwsStateError);
  });
}
