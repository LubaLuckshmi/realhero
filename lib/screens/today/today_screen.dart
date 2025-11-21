import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../services/profile_service.dart';
import '../../services/ai_service.dart';
import '../../services/xp_service.dart';
import '../../models/progress_event.dart';
import '../../models/user_xp.dart';
import '../../viewmodels/home_viewmodel.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _loading = false;
  List<String> _actions = const [];
  UserXp? _xp;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final prof = await ProfileService().loadFresh();
    final vm = mounted ? context.read<HomeViewModel>() : null;

    final generated = await AIService.suggestDailyActions(
      profile: prof,
      activeGoals: vm?.items.map((g) => g.title).toList() ?? const [],
    );

    final xp = await XpService().loadUserXp();

    if (!mounted) return;
    setState(() {
      _actions = generated.isNotEmpty ? generated : _actions;
      _xp = xp;
      _loading = false;
    });
  }

  Future<void> _markDone(int idx) async {
    if (idx < 0 || idx >= _actions.length) return;
    final act = _actions[idx];

    await XpService().addEvent(
      ProgressEvent(
        at: DateTime.now(),
        kind: ProgressKind.actionDone,
        xp: 10, // базовая награда за мини-шаг
      ),
    );
    final xp = await XpService().loadUserXp();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Шаг выполнен: $act  (+10 XP)')));
    setState(() => _xp = xp);
  }

  @override
  Widget build(BuildContext context) {
    final prof = _xp;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сегодня'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить предложения',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // XP панель
              if (prof != null) _XpPanel(xp: prof),
              const SizedBox(height: 8),

              Row(
                children: const [
                  Text(
                    'Мини-шаги на сегодня',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_actions.isEmpty)
                    ? const Center(
                        child: Text('Нет предложений. Нажми «обновить».'),
                      )
                    : ListView.separated(
                        itemCount: _actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ActionTile(
                          text: _actions[i],
                          onDone: () => _markDone(i),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.text, required this.onDone});
  final String text;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          const SizedBox(width: 8),
          FilledButton(onPressed: onDone, child: const Text('Готово')),
        ],
      ),
    );
  }
}

class _XpPanel extends StatelessWidget {
  const _XpPanel({required this.xp});
  final UserXp xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech),
          const SizedBox(width: 8),
          Text('Уровень ${xp.level}'),
          const Spacer(),
          Text('${xp.xp} XP'),
          const SizedBox(width: 12),
          Text('до ↑ ${xp.nextLevel}'),
        ],
      ),
    );
  }
}
