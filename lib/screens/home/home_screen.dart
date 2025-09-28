/// home_screen.dart — UI главного экрана с оффлайн/облако, входом и датой рождения
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../auth/email_auth_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..init(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          final signedIn = vm.user != null;

          return Scaffold(
            appBar: AppBar(
              title: const Text('RealHero — Мои цели'),
              actions: [
                if (!signedIn)
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => const EmailAuthDialog(),
                      );
                      if (ok == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Вход выполнен. Синхронизирую цели...')),
                        );
                      }
                    },
                    child: const Text('Войти', style: TextStyle(color: Colors.white)),
                  )
                else
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.account_circle),
                    onSelected: (v) async {
                      if (v == 'birth' && vm.user != null) {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                          initialDate: DateTime(2000, 1, 1),
                        );
                        if (picked != null) {
                          await vm.saveBirthDateAndSuggest(picked);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Профиль сохранён. Добавлены рекомендации.')),
                          );
                        }
                      } else if (v == 'signout') {
                        await FirebaseAuth.instance.signOut();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Вы вышли из аккаунта. Данные будут храниться локально.')),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'birth',
                        child: Text(vm.profile?.birthDate == null ? 'Указать дату рождения' : 'Изменить дату рождения'),
                      ),
                      const PopupMenuItem(value: 'signout', child: Text('Выйти')),
                    ],
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
              onPressed: () async {
                final ctl = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Новая цель'),
                    content: TextField(controller: ctl, decoration: const InputDecoration(labelText: 'Название')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Добавить')),
                    ],
                  ),
                );
                if (ok == true && ctl.text.trim().isNotEmpty) {
                  await vm.add(ctl.text.trim());
                }
              },
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Сохранение: ${signedIn ? 'в облаке' : 'локально'}'),
                            const SizedBox(height: 8),
                            Text('Прогресс: ${(vm.progress * 100).toStringAsFixed(0)}%'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: vm.progress),
                            if (signedIn && vm.profile?.birthDate == null) ...[
                              const SizedBox(height: 12),
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.cake),
                                  title: const Text('Добавь дату рождения, чтобы получить персональные рекомендации'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(1920),
                                      lastDate: DateTime.now(),
                                      initialDate: DateTime(2000, 1, 1),
                                    );
                                    if (picked != null) {
                                      await vm.saveBirthDateAndSuggest(picked);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Рекомендации добавлены ✨')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Expanded(
                        child: vm.items.isEmpty
                            ? const Center(child: Text('Пока нет целей. Добавь первую ✨'))
                            : ListView.builder(
                                itemCount: vm.items.length,
                                itemBuilder: (ctx, i) => Dismissible(
                                  key: ValueKey(vm.items[i].id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => vm.remove(vm.items[i]),
                                  background: Container(
                                    color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      vm.items[i].title,
                                      style: TextStyle(
                                        decoration: vm.items[i].isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      value: vm.items[i].isCompleted,
                                      onChanged: (_) => vm.toggle(vm.items[i]),
                                    ),
                                    onTap: () => vm.toggle(vm.items[i]),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
