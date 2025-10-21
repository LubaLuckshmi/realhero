// test/home_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/viewmodels/home_viewmodel.dart';

void main() {
  test('add/remove/setProgress work as expected', () async {
    final vm = HomeViewModel();

    // начально
    expect(vm.items.length, 0);

    // add
    await vm.add(title: 'Test Goal', category: 'Здоровье', firstStep: '10 мин');
    expect(vm.items.length, 1);
    expect(vm.items.first.title, 'Test Goal');

    // progress
    final g = vm.items.first;
    await vm.setProgress(g, 0.5);
    expect(vm.items.first.progress, 0.5);

    // remove
    await vm.remove(vm.items.first);
    expect(vm.items.length, 0);
  });
}
