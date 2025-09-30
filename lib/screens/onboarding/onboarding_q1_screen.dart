import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/onboarding_view_model.dart';

class OnboardingQ1Screen extends StatelessWidget {
  const OnboardingQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    const options = <String>[
      'Попробовала себя в чём-то новом',
      'Дала себе отдохнуть',
      'Сменила сферу',
      'Хочу пройти короткий тест, чтобы понять',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('А что бы ты сделала, если бы не боялась?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...options.map(
              (o) => RadioListTile<String>(
                value: o,
                groupValue: vm.fearChoice,
                title: Text(o),
                onChanged: (v) =>
                    context.read<OnboardingViewModel>().setFear(v!),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: vm.canGoNextFromQ1
                  ? () {
                      // Пока заглушка: просто покажем выбранный ответ
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Выбрано'),
                          content: Text(vm.fearChoice ?? ''),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Ок'),
                            ),
                          ],
                        ),
                      );
                      // Следующим шагом сюда добавим переход на Q2
                    }
                  : null,
              child: const Text('Далее'),
            ),
          ],
        ),
      ),
    );
  }
}
