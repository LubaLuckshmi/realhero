import 'package:flutter/material.dart';
import 'discovery.dart';
import 'store.dart';
import 'widgets.dart';

class DiscoveryView extends StatelessWidget {
  final RealHeroStore store;
  final VoidCallback onKnownGoal;
  final VoidCallback onPrepare;
  final VoidCallback onPause;
  const DiscoveryView({super.key, required this.store, required this.onKnownGoal, required this.onPrepare, required this.onPause});

  @override
  Widget build(BuildContext context) {
    final state = store.state.discovery;
    final phase = state.phase;
    return HeroBackdrop(
      image: 'horizon.png',
      dim: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(onPressed: phase == DiscoveryPhase.entry || phase == DiscoveryPhase.idle ? onPause : store.backInDiscovery, icon: const Icon(Icons.arrow_back)),
              const Expanded(child: Text('Лея', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
              TextButton(onPressed: onPause, child: const Text('Не сейчас')),
            ]),
            gap(40),
            if (phase == DiscoveryPhase.questions) ...[
              Text('${state.questionIndex + 1} из ${DiscoveryState.questions.length}', style: const TextStyle(color: teal)),
              gap(16),
              _question(state.question.text),
              gap(28),
              for (final answer in DiscoveryAnswer.values) ...[
                ActionButton(discoveryAnswerLabel(answer), secondary: true,
                  onPressed: () => store.answerDiscovery(answer)),
                gap(12),
              ],
              const Text('Можно отвечать «не знаю». Это тоже ответ.', style: TextStyle(color: muted, fontSize: 12)),
            ] else if (phase == DiscoveryPhase.direction) ...[
              _question('Что сейчас чуть ближе?'),
              gap(12),
              const Text('Можно пока не выбирать.', style: TextStyle(color: muted)),
              gap(24),
              Wrap(spacing: 10, runSpacing: 12, children: [
                for (final direction in DiscoveryState.directions)
                  ActionChip(label: Text(direction), onPressed: () => store.chooseDiscoveryDirection(direction)),
              ]),
              gap(24),
              ActionButton('Пока не знаю', secondary: true, onPressed: () => store.chooseDiscoveryDirection(null)),
            ] else if (phase == DiscoveryPhase.review) ...[
              _question('Начнём с маленькой пробы'),
              gap(16),
              Text(state.reviewText, style: const TextStyle(fontSize: 18)),
              gap(28),
              ActionButton('Подготовить мой шаг', icon: Icons.auto_awesome, onPressed: onPrepare),
              gap(14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Мои ответы', style: TextStyle(color: muted, fontSize: 14)),
                children: [
                  for (final question in DiscoveryState.questions)
                    ListTile(contentPadding: EdgeInsets.zero, title: Text(question.text),
                      subtitle: Text(discoveryAnswerLabel(state.answers[question.id]!))),
                ],
              ),
            ] else if (phase == DiscoveryPhase.knownGoal) ...[
              _question('К чему хочется прийти?'),
              gap(16),
              TextFormField(
                key: const ValueKey('known-goal-input'),
                initialValue: state.goalText,
                minLines: 2,
                maxLines: 5,
                onChanged: store.saveGoalDraft,
                decoration: const InputDecoration(hintText: 'Можно одной фразой…'),
              ),
              gap(24),
              ActionButton('Найти первый шаг', onPressed: state.hasIdea ? onKnownGoal : null),
              gap(10),
              TextButton(onPressed: () => store.startDiscovery(), child: const Text('Это пока только идея')),
            ] else ...[
              _question('С чего начнём?'),
              gap(16),
              const Text('Большую цель можно найти по ходу.', style: TextStyle(fontSize: 18)),
              gap(28),
              ActionButton('Я знаю, чего хочу', secondary: true, icon: Icons.flag_outlined, onPressed: store.chooseKnownGoal),
              gap(14),
              ActionButton('Пока не знаю, чего хочу', secondary: true, icon: Icons.explore_outlined, onPressed: () => store.startDiscovery()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _question(String text) => Text(text, style: const TextStyle(
    fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -.5));
}
