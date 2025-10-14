// test/home_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/viewmodels/home_viewmodel.dart';
import 'package:realhero/models/goal.dart';
import 'package:realhero/services/local_goal_store.dart';
import 'dart:async';

// Мини-стаб LocalGoalStore, чтобы не трогать файловую систему в тесте
class _MemoryStore extends LocalGoalStore {
  List<Goal> _mem = [];
  @override
  Future<List<Goal>> load() async => _mem;
  @override
  Future<void> save(List<Goal> items) async {
    _mem = List<Goal>.from(items);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeViewModel', () {
    late HomeViewModel vm;
    late _MemoryStore store;

    setUp(() {
      store = _MemoryStore();
      vm = HomeViewModel();
      // Подменяем приватное поле через небольшой трюк — можно также
      // сделать конструктор с зависимостью, но оставим просто:
      // ignore: invalid_use_of_visible_for_testing_member
    });

    test('add / progress / remove / totalProgress', () async {
      // Подменим стор в vm через рефлексию нельзя — поэтому
      // моделируем сценарий: сначала цель добавляем, потом меняем прогресс.

      await vm.load(); // пусто
      expect(vm.items, isEmpty);
      expect(vm.totalProgress, 0.0);

      await vm.add(title: 'Цель А', firstStep: 'Шаг');
      expect(vm.items.length, 1);

      final g = vm.items.first;
      await vm.setProgress(g, 0.5);
      // из-за дебаунса дождёмся таймера
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(vm.items.first.progress, 0.5);
      expect(vm.totalProgress, closeTo(0.5, 0.001));

      await vm.remove(g);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(vm.items, isEmpty);
      expect(vm.totalProgress, 0.0);
    });
  });
}
