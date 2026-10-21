import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'domain.dart';
import 'store.dart';
import 'leia_client.dart';
import 'widgets.dart';
import 'discovery.dart';
import 'discovery_view.dart';
import 'process_view.dart';
import 'backup.dart';
import 'presentation_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = RealHeroStore();
  await store.load();
  runApp(RealHeroApp(store: store));
}

class RealHeroApp extends StatelessWidget {
  final RealHeroStore store;
  final LeiaClient? leiaClient;
  const RealHeroApp({super.key, required this.store, this.leiaClient});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RealHero',
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: teal,
        secondary: violet,
        surface: panel,
        onPrimary: ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? teal : muted, fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? teal : const Color(0xFFD6E2E7), size: 26)),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
        bodySmall: TextStyle(color: muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: muted),
        ),
      ),
    ),
    home: HeroShell(store: store, leiaClient: leiaClient),
  );
}

class HeroShell extends StatefulWidget {
  final RealHeroStore store;
  final LeiaClient? leiaClient;
  const HeroShell({super.key, required this.store, this.leiaClient});
  @override
  State<HeroShell> createState() => _HeroShellState();
}

class _HeroShellState extends State<HeroShell> with WidgetsBindingObserver {
  RealHeroStore get s => widget.store;
  LeiaClient get leia => widget.leiaClient ?? LeiaClient();
  int tab = 0;
  String scene = 'today';
  bool busy = false;
  String? error;
  final chatInput = TextEditingController();
  final chatScroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    s.addListener(changed);
    if (s.state.discovery.active) tab = 2;
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(s.flush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    s.removeListener(changed);
    chatInput.dispose();
    chatScroll.dispose();
    super.dispose();
  }

  void notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void openChat([String? draft]) {
    setState(() {
      tab = 2;
      if (draft != null) chatInput.text = draft;
    });
  }

  void select(int i) {
    setState(() {
      tab = i;
      if (i == 0) scene = 'today';
    });
  }

  Future<void> showText(String title, String text) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gap(),
              SelectableText(text),
              gap(),
              ActionButton('Понятно', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900 && size.width > size.height;
    final inProcess = tab == 0 && scene == 'process';
    final leiaOverProcess = tab == 2 && scene == 'process';
    final content = SafeArea(
      bottom: false,
      child: switch (tab) {
        1 => pathPage(),
        2 => chatPage(),
        3 => profilePage(),
        _ => switch (scene) {
          'mission' => missionPage(),
          'process' => processPage(),
          _ => todayPage(),
        },
      },
    );
    final items = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Сегодня',
      ),
      const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Путь'),
      const NavigationDestination(
        icon: LeiaNavIcon(),
        label: 'Лея',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Профиль',
      ),
    ];
    return PopScope(
      canPop: !inProcess && !leiaOverProcess && (tab != 0 || scene == 'today'),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            if (leiaOverProcess) {
              tab = 0;
            } else {
              scene = inProcess ? 'mission' : 'today';
            }
          });
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                backgroundColor: ink,
                indicatorColor: teal.withValues(alpha: .08),
                selectedIconTheme: const IconThemeData(color: teal),
                selectedLabelTextStyle: const TextStyle(color: teal),
                selectedIndex: tab,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final i in items)
                    NavigationRailDestination(
                      icon: i.icon,
                      selectedIcon: i.selectedIcon,
                      label: Text(i.label),
                    ),
                ],
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width > 660 ? 660 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      if (s.persistenceError != null)
                        SafeArea(
                          bottom: false,
                          child: MaterialBanner(
                            content: Text(s.persistenceError!),
                            actions: [
                              TextButton(
                                onPressed: s.retrySave,
                                child: const Text('Повторить сохранение'),
                              ),
                            ],
                          ),
                        ),
                      if (s.recoveryMessage != null)
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              s.recoveryMessage!,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide || inProcess
            ? null
            : NavigationBar(
                backgroundColor: ink,
                indicatorColor: Colors.transparent,
                height: 76,
                selectedIndex: tab,
                onDestinationSelected: select,
                destinations: items,
              ),
      ),
    );
  }

  Widget heading(String text, {bool back = false, VoidCallback? onBack, Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        if (back)
          IconButton(
            onPressed: onBack ?? () => setState(() => scene = 'today'),
            tooltip: 'Назад',
            icon: const Icon(Icons.arrow_back_ios_new, size: 21),
          ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        ?trailing,
      ],
    ),
  );
  Widget modeChip() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (s.isDemo ? violet : teal).withValues(alpha: .13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.isDemo ? 'ДЕМО · пример из макета' : 'ТВОЯ ЦЕЛЬ',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          color: s.isDemo ? violet : teal,
        ),
      ),
    ),
  );
  Widget scroll(Widget child, {String? image, bool dim = false}) =>
      HeroBackdrop(
        image: image,
        dim: dim,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            key: ValueKey('page-$tab-$scene'),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 44),
              child: child,
            ),
          ),
        ),
      );

  Widget todayPage() {
    final m = s.currentMission;
    if (!s.isDemo && (busy || error != null || s.state.needsClarification)) return easyQuestionPage();
    if (!s.isDemo && m?.status == MissionStatus.declined) return declinedPage();
    if (m == null) {
      if (s.goal != null && !s.isDemo) {
        return scroll(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          heading('Сегодня'),
          gap(32),
          Text(s.goal!.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          gap(20),
          if (s.state.discovery.paused) ...[
            ActionButton('Продолжить короткое знакомство', onPressed: () {
              s.resumeDiscovery();
              openChat();
            }),
            gap(12),
          ],
          ActionButton('Продолжить с Леей', onPressed: () => openChat()),
          gap(12),
          ActionButton('Не знаю, с чего начать', secondary: true, onPressed: () {
            if (busy) return;
            s.startDiscovery(keepGoal: true);
            openChat();
          }),
          gap(12),
          TextButton(onPressed: newGoal, child: const Text('Начать другую цель')),
        ]), image: 'horizon.png', dim: true);
      }
      return welcomePage();
    }
    final draft = m.materials.where((a) => a.kind == 'message').firstOrNull;
    final sendAction =
        draft != null &&
        RegExp(r'отправ|приглас', caseSensitive: false).hasMatch(m.oneAction);
    final scheduleAction = m.steps.firstOrNull?.id == 'date';
    final Widget action;
    if (m.status == MissionStatus.completed) {
      action = ActionButton(s.requiresNextMission ? 'Подготовить следующий ход' : 'Посмотреть продолжение',
        icon: Icons.near_me, onPressed: nextMission);
    } else if (m.status == MissionStatus.paused || m.status == MissionStatus.active) {
      action = ActionButton(m.status == MissionStatus.paused ? 'Продолжить миссию' : 'Вернуться к действию',
        icon: Icons.play_arrow, onPressed: () { s.resumeMission(); setState(() => scene = 'process'); });
    } else if (m.status == MissionStatus.declined) {
      action = ActionButton('Выбрать другой ход', onPressed: () => adapt('Эту миссию я отклонил. Предложи иной способ, учти причину отказа.'));
    } else if (!s.isDemo && m.steps.length == 1 && !sendAction && !scheduleAction) {
      action = ActionButton('Готово', icon: Icons.check, onPressed: quickResult);
    } else {
      action = ActionButton(scheduleAction ? 'Выбрать день' : !sendAction ? 'Перейти к действию'
        : s.isDemo ? 'Отправить Андрею' : 'Проверить и отправить', icon: Icons.near_me,
        onPressed: () => scheduleAction ? chooseDay() : sendAction ? reviewSend(draft) : begin());
    }
    return TodayView(mission: m, name: s.profile.name, isDemo: s.isDemo, action: action,
      onProfile: () => select(3), onLeia: () => openChat(),
      onPreparation: () => setState(() => scene = 'mission'),
      onPreview: () {
        final preview = draft ?? m.materials.firstOrNull;
        if (preview != null) { materialEditor(preview); }
        else { setState(() => scene = 'mission'); }
      },
      onWhy: () => showText('Почему этот ход', m.why),
      onEasier: () => adapt('Подготовь более простой способ двигаться к моей исходной идее. Возьми подготовку на себя, оставь одно действие. Не сокращай только минуты и не подменяй цель упражнением на внимательность.'),
      onOptions: missionOptions);
  }

  Widget easyQuestionPage() {
    final replies = s.state.quickReplies;
    final last = s.state.chat.where((c) => c.role == 'assistant').lastOrNull;
    return scroll(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading('Сегодня'), gap(28),
      LeiaLine(busy ? 'Готовлю один шаг…' : 'Давай найдём, что тебе интересно.', onTap: () => openChat()),
      gap(20),
      if (busy) const Center(child: CircularProgressIndicator())
      else if (error != null) ...[
        Text(error!), gap(16),
        ActionButton('Повторить', onPressed: () => sendChat(message: 'Продолжи с последнего ответа. Подготовь один лёгкий шаг или один выбор.', operation: 'mission')),
        TextButton(onPressed: settings, child: const Text('Подключение')),
      ] else ...[
        Text(last?.text ?? 'Что сейчас тебе ближе?', style: const TextStyle(fontSize: 23, height: 1.3)),
        gap(24),
        for (final reply in replies) ...[
          ActionButton(reply, secondary: true, onPressed: () => sendChat(message: reply)), gap(12),
        ],
        if (!replies.any((r) => r.toLowerCase().contains('ничего')))
          TextButton(onPressed: () => sendChat(message: 'Пока ничего не откликается. Предложи другие два конкретных варианта, без повторного опроса.'), child: const Text('Пока ничего не откликается')),
        TextButton(onPressed: () => openChat(), child: const Text('Написать своими словами')),
      ],
      gap(24), TextButton(onPressed: newGoal, child: const Text('Изменить идею')),
    ]));
  }

  Widget declinedPage() => scroll(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    heading('Сегодня'), gap(36),
    const Text('Этот шаг не подошёл', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
    gap(14), const Text('Выберем другой способ приблизиться к твоей идее.'), gap(24),
    ActionButton('Предложить другой шаг', onPressed: () => adapt('Предыдущая миссия не подошла. Учти причину отказа. Предложи другой конкретный способ к исходной идее; если направление неясно, предложи выбор из двух вариантов.')),
    TextButton(onPressed: newGoal, child: const Text('Изменить идею')),
  ]));

  Future<void> quickResult() async {
    final mission = s.currentMission!;
    final note = TextEditingController();
    await showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      showDragHandle: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, MediaQuery.viewInsetsOf(ctx).bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Как прошло?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), gap(16),
        TextField(controller: note, maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'Можно добавить пару слов')), gap(16),
        for (final item in [(OutcomeKind.positive, 'Сделано, хочу дальше'), (OutcomeKind.partial, 'Попытка была, пока неясно')]) ...[
          ActionButton(item.$2, secondary: true, onPressed: () {
            s.completeMission(missionId: mission.id, outcome: item.$1,
              facts: note.text.trim().isEmpty ? item.$2 : note.text.trim(), actionTaken: true,
              actualMinutes: mission.startedAt == null ? 0 : DateTime.now().toUtc().difference(mission.startedAt!).inMinutes.clamp(0, 1440));
            Navigator.pop(ctx); nextMission();
          }), gap(12),
        ],
        TextButton(onPressed: () {
          s.declineMission(note.text.trim().isEmpty ? 'Этот шаг не подходит' : note.text.trim());
          Navigator.pop(ctx); setState(() => scene = 'today');
        }, child: const Text('Не подходит — без попытки')),
      ]))));
    note.dispose();
  }

  Widget welcomePage() => scroll(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✦  RealHero',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        gap(56),
        const Text(
          'Твоя жизнь.\nТвой следующий ход.',
          style: TextStyle(
            fontSize: 37,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        gap(),
        const Text(
          'Можно прийти с целью или пока без неё. Начнём с того, что сейчас посильно.',
          style: TextStyle(fontSize: 17),
        ),
        gap(64),
        if (s.state.discovery.paused) ...[
          ActionButton('Продолжить короткое знакомство', onPressed: () {
            s.resumeDiscovery();
            openChat();
          }),
          gap(12),
        ],
        ActionButton(
          'Я знаю, чего хочу',
          icon: Icons.flag_outlined,
          onPressed: () {
            s.openGoalEntry();
            s.chooseKnownGoal();
            openChat();
          },
        ),
        gap(12),
        ActionButton(
          'Пока не знаю, чего хочу',
          secondary: true,
          icon: Icons.explore_outlined,
          onPressed: () {
            s.openGoalEntry();
            s.startDiscovery();
            openChat();
          },
        ),
        gap(12),
        ActionButton(
          'Попробовать демосценарий',
          secondary: true,
          onPressed: () {
            s.loadDemo();
            setState(() {
              tab = 0;
              scene = 'today';
            });
          },
        ),
        gap(14),
        const Text(
          'Демо — вымышленный пример с Андреем и двумя экранами прототипа. В твоих миссиях используются только сообщённые тобой факты.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        gap(),
        TextButton(
          onPressed: settings,
          child: const Text('Подключение к серверу Леи'),
        ),
      ],
    ),
    image: 'horizon.png',
    dim: true,
  );

  Widget missionPage() {
    final m = s.currentMission;
    if (m == null) return welcomePage();
    return MissionView(mission: m, isDemo: s.isDemo,
      onBack: () => setState(() => scene = 'today'), onOptions: missionOptions,
      onLeia: () => openChat(), onBegin: begin, onNext: nextMission,
      onMaterial: materialEditor,
      onStepDetails: (step) => showText(step.title, step.hint),
      onChange: () => adapt('Нужен другой способ достижения моей цели вместо текущей миссии.'));
  }

  Widget processPage() {
    final mission = s.currentMission;
    if (mission == null) return welcomePage();
    return ProcessView(
      mission: mission,
      isDemo: s.isDemo,
      onBack: () => setState(() => scene = 'mission'),
      onPause: () => mission.status == MissionStatus.paused ? s.resumeMission() : s.pauseMission(),
      onLeia: () => openChat(),
      onNote: noteEditor,
      onResult: resultEditor,
      onMaterials: () => setState(() => scene = 'mission'),
      onStep: s.setStep,
      onQuestion: s.setQuestion,
    );
  }

  Widget pathPage() {
    final history = s.state.missions
        .where(
          (m) => m.goalId == s.goal?.id && m.status != MissionStatus.declined,
        )
        .toList();
    final done = history
        .where(
          (m) =>
              m.status == MissionStatus.completed &&
              m.outcome?.actionTaken == true,
        )
        .length;
    final visibleHistory = history.skip(history.length > 6 ? history.length - 6 : 0).toList();
    return scroll(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Твой путь'),
          Row(children: [
            Expanded(child: GlassPanel(onTap: chaptersSheet,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Текущая глава', style: TextStyle(color: muted, fontSize: 13)),
                  gap(5),
                  Text(s.currentMission?.chapter ?? 'Начало твоего пути',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ])),
                const Icon(Icons.chevron_right, color: muted),
              ]))),
            const SizedBox(width: 12),
            Semantics(label: 'Главы пути', button: true,
              child: InkWell(onTap: chaptersSheet, borderRadius: BorderRadius.circular(40),
                child: Container(width: 66, height: 66,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: panel.withValues(alpha: .6),
                    border: Border.all(color: const Color(0xFF1B4652))),
                  child: const Icon(Icons.emoji_events, size: 32, color: teal)))),
          ]),
          gap(),
          OrbitMap(
            states: List.generate(6, (i) {
              if (i >= visibleHistory.length) return OrbitStage.future;
              final m = visibleHistory[i];
              if (m.status == MissionStatus.completed) {
                return m.outcome?.actionTaken == true ? OrbitStage.done : OrbitStage.recorded;
              }
              return m.id == s.currentMission?.id ? OrbitStage.current : OrbitStage.recorded;
            }),
            onNode: (i) {
              if (i < visibleHistory.length) {
                missionHistory(visibleHistory[i]);
              } else {
                showText(
                  'Новая возможность',
                  'Следующие этапы появятся из твоего опыта. Лея пока не знает будущий результат.',
                );
              }
            },
          ),
          GlassPanel(
            onTap: () => s.goal == null
                ? openChat()
                : showText(
                    'Твоя цель',
                    '${s.goal!.title}\n\n${s.goal!.context}',
                  ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/horizon-approved.png',
                    width: 105,
                    height: 105,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Твоё направление',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      gap(5),
                      Text(
                        displayGoalTitle(s.goal?.title),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          gap(14),
          GlassPanel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: stat('$done', 'действий')),
                Container(width: 1, height: 38, color: const Color(0xFF31505A)),
                Expanded(child: stat('${s.state.realChanges.length}', 'изменений')),
                Container(width: 1, height: 38, color: const Color(0xFF31505A)),
                Expanded(child: stat('${s.profile.xp}', 'XP героя')),
              ],
            ),
          ),
          gap(14),
          Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(tilePadding: EdgeInsets.zero,
              title: const Text('Что изменилось в жизни', style: TextStyle(fontSize: 15)),
              children: [
                if (s.state.realChanges.isEmpty)
                  const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Здесь появятся реальные результаты твоих действий.',
                    style: TextStyle(color: muted, fontSize: 13))),
                for (final r in s.state.realChanges.reversed)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassPanel(child: Text(r.text))),
              ])),
          gap(16),
          arrowRow(Icons.timeline, 'История миссий', historySheet),
          gap(10),
          LeiaLine(
            'Следующий шаг зависит от того, что произошло в реальности.',
            onTap: () => openChat(),
          ),
        ],
      ),
    );
  }

  String displayGoalTitle(String? title) {
    if (title == null || RegExp(r'^\s*(не знаю|пока не знаю)[.!?]?\s*$', caseSensitive: false).hasMatch(title)) {
      return 'Найти своё направление';
    }
    return title;
  }

  Future<void> chaptersSheet() => showText('Главы пути',
    s.state.missions.isEmpty ? 'Первая глава появится вместе с твоей целью.'
      : s.state.missions.where((m) => m.goalId == s.goal?.id)
        .map((m) => '${m.chapter}\n${m.title}').join('\n\n'));

  Widget stat(String n, String label) => Column(
    children: [
      Text(
        n,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
      ),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  Future<void> exportHistory() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Сохранить историю'),
          content: const Text('В файле будут твои цели, история и подключение к Лее. Сохрани его в личную папку.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
          ],
        ),
      );
      if (confirmed != true) return;
      await s.flush();
      final saved = await const MethodChannel('realhero/actions').invokeMethod<bool>(
        'saveBackup', {'content': s.exportBackup()},
      );
      if (saved == true) notice('История сохранена в файл.');
    } catch (_) {
      notice('Не удалось сохранить файл. История в приложении остаётся на месте.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importHistory() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final raw = await const MethodChannel('realhero/actions').invokeMethod<String>('openBackup');
      if (raw == null || !mounted) return;
      final backup = RealHeroBackup.decode(raw);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Восстановить историю?'),
          content: Text('В файле: ${backup.state.goals.length} целей, ${backup.state.missions.length} миссий. Текущую историю заменит сохранение из файла.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Восстановить')),
          ],
        ),
      );
      if (confirmed != true) return;
      await s.restoreBackup(backup);
      if (!mounted) return;
      setState(() { tab = 0; scene = 'today'; error = null; chatInput.clear(); });
      notice('История и подключение восстановлены.');
    } catch (_) {
      notice('Не удалось восстановить сохранение. Проверь файл и свободное место.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget profilePage() => scroll(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Профиль',
          trailing: IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        GlassPanel(
          onTap: profileEditor,
          child: Row(
            children: [
              const Avatar(size: 88),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    gap(3),
                    Text(
                      'Уровень ${s.profile.level} · Исследователь',
                      style: const TextStyle(fontSize: 13),
                    ),
                    gap(12),
                    LinearProgressIndicator(
                      value: (s.profile.xp % 1000) / 1000,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: ink,
                      color: teal,
                    ),
                    gap(6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${s.profile.xp % 1000} / 1000 XP',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap(24),
        SectionTitle(
          'Твои достижения',
          action: 'Все →',
          onTap: () => showText(
            'Достижения',
            s.profile.achievements.isEmpty
                ? 'Откроются после реальных действий. Нет штрафов за пропуски.'
                : s.profile.achievements.join('\n\n'),
          ),
        ),
        gap(14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BadgeArt(
                icon: Icons.landscape_outlined,
                color: const Color(0xFFEAC79F),
                label: 'Первые\nшаги',
                unlocked: s.profile.completedCount > 0,
              ),
            ),
            Expanded(
              child: BadgeArt(
                icon: Icons.local_fire_department,
                color: const Color(0xFFFFAC64),
                label: 'Смелость\nв действии',
                unlocked: s.profile.completedCount >= 2,
              ),
            ),
            Expanded(
              child: BadgeArt(
                icon: Icons.auto_awesome,
                color: violet,
                label: 'Фокус\nна цели',
                unlocked: s.profile.completedCount >= 3,
              ),
            ),
            Expanded(
              child: BadgeArt(
                icon: Icons.workspace_premium,
                color: const Color(0xFFDDB570),
                label: 'Полезный\nопыт',
                unlocked: s.profile.completedCount >= 1,
              ),
            ),
          ],
        ),
        gap(25),
        InkWell(
          onTap: () => select(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/horizon-approved.png',
                  height: 118,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: ColoredBox(color: ink.withValues(alpha: .4)),
                ),
                const Positioned(
                  right: 17,
                  top: 36,
                  child: Text(
                    'Твоя реальность\nменяется',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        gap(14),
        arrowRow(
          Icons.bolt,
          'Способности',
          () => showText(
            'Способности',
            s.profile.abilities.isEmpty
                ? 'Способности развиваются из выполненных миссий. Это игровой слой, а реальные изменения видны на экране пути.'
                : s.profile.abilities.join('\n\n'),
          ),
        ),
        gap(10),
        arrowRow(Icons.history, 'История миссий', historySheet),
        gap(10),
        arrowRow(Icons.save_alt, 'Сохранить историю в файл', exportHistory),
        gap(10),
        arrowRow(Icons.restore, 'Восстановить историю', importHistory),
        gap(16),
        GlassPanel(
          child: Text(
            'XP — за выполненное действие и фиксацию опыта. Ответ «нет» не означает поражение. Изменения в жизни учитываются отдельно.',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ),
        gap(12),
        TextButton(
          onPressed: newGoal,
          child: const Text('Задать собственную цель'),
        ),
      ],
    ),
  );

  Widget chatPage() {
    if (s.state.discovery.active || (s.goal == null && !s.isDemo)) {
      return DiscoveryView(store: s, onKnownGoal: beginKnownGoal, onPrepare: prepareDiscovery, onPause: () {
        s.pauseDiscovery();
        select(0);
      });
    }
    return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: Column(
      children: [
        heading(
          'Лея',
          back: scene == 'process',
          onBack: () => setState(() => tab = 0),
          trailing: IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        Expanded(
          child: ListView(
            controller: chatScroll,
            children: [
              if (s.state.understanding.isNotEmpty || s.state.assumptions.isNotEmpty)
                ExpansionTile(
                  key: const ValueKey('leia-context'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Контекст Леи', style: TextStyle(color: muted, fontSize: 13)),
                  children: [
                    if (s.state.understanding.isNotEmpty)
                      Align(alignment: Alignment.centerLeft, child: Text(s.state.understanding)),
                    TextButton(onPressed: settings, child: const Text('Исправить понимание')),
                    for (final assumption in s.state.assumptions)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Предположение: $assumption', style: const TextStyle(fontSize: 12, color: muted)),
                        trailing: IconButton(onPressed: () => s.dismissAssumption(assumption),
                          icon: const Icon(Icons.close, size: 18), tooltip: 'Убрать неверное предположение'),
                      ),
                  ],
                ),
              if (s.isDemo)
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Демо Леи',
                        style: TextStyle(
                          color: violet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      gap(7),
                      const Text(
                        'Здесь локальный сценарий для знакомства с интерфейсом. Для разговора о собственной цели нужен подключённый сервер.',
                      ),
                      TextButton(
                        onPressed: newGoal,
                        child: const Text('Перейти к собственной цели'),
                      ),
                    ],
                  ),
                ),
              if (s.state.chat.length > 4)
                ExpansionTile(
                  key: const ValueKey('earlier-chat'),
                  title: const Text('Раньше в разговоре', style: TextStyle(fontSize: 13, color: muted)),
                  children: [for (final c in s.state.chat.take(s.state.chat.length - 4)) _ChatBubble(key: ValueKey(c), message: c)],
                ),
              for (final c in s.state.chat.skip(s.state.chat.length > 4 ? s.state.chat.length - 4 : 0))
                _ChatBubble(key: ValueKey(c), message: c),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Лея готовит следующий ход…')),
                    ],
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFFFBD9A)),
                        ),
                        TextButton(
                          onPressed: settings,
                          child: const Text('Проверить подключение'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (s.currentMission != null && !s.isDemo)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: ActionButton(
                    'Открыть подготовленную миссию',
                    secondary: true,
                    onPressed: () {
                      setState(() {
                        tab = 0;
                        scene = 'mission';
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        if (s.state.needsClarification && !busy) ...[
          gap(10),
          Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, runSpacing: 6, children: [
            for (final reply in s.state.quickReplies)
              ActionChip(label: Text(reply, maxLines: 2, overflow: TextOverflow.ellipsis), onPressed: () {
                if (reply.toLowerCase().contains('не знаю')) {
                  unawaited(sendChat(message: reply));
                } else {
                  unawaited(sendChat(message: reply));
                }
              }),
            ActionChip(label: const Text('Можно без переписки'), onPressed: () => s.startDiscovery(keepGoal: true)),
          ])),
        ],
        gap(12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: chatInput,
                minLines: 1,
                maxLines: 5,
                enabled: !busy,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Расскажи, что важно…',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: busy ? null : () => sendChat(),
              icon: const Icon(Icons.arrow_upward),
              style: IconButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: ink,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  }

  Future<void> sendChat({String? message, String? displayMessage, String operation = 'mission'}) async {
    final text = (message ?? chatInput.text).trim();
    if (text.isEmpty || busy) return;
    if (!s.isDemo && (s.currentMission == null || s.currentMission!.isClosed) &&
        !s.state.needsClarification && RegExp(r'^(?:я\s+)?(?:пока\s+)?не\s+знаю(?:[\s,.!…].*)?$', caseSensitive: false).hasMatch(text)) {
      s.appendChat('user', text);
      chatInput.clear();
      s.startDiscovery(keepGoal: true);
      return;
    }
    if (s.isDemo) {
      s.appendChat('user', text);
      s.appendChat(
        'assistant',
        'Демонстрационный режим: приглашение, вопросы и два примера экранов уже в миссии. Можно открыть материалы, уменьшить действие или зафиксировать ответ Андрея. Для персонального ответа переключись на свою цель.',
      );
      chatInput.clear();
      return;
    }
    if (s.goal == null) s.setGoal(text);
    s.appendChat('user', displayMessage ?? text);
    chatInput.clear();
    setState(() {
      busy = true;
      error = null;
      tab = 0;
      scene = 'today';
    });
    try {
      final response = await leia.respond(
        state: s.state,
        message: text,
        operation: operation,
      );
      s.acceptPlan(response);
      await s.flush();
      if (mounted) {
        setState(() => busy = false);
        setState(() { tab = 0; scene = 'today'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && chatScroll.hasClients) {
        unawaited(chatScroll.animateTo(chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
      }
    });
  }

  void begin() {
    s.beginMission();
    setState(() => scene = 'process');
  }

  Future<void> reviewSend(PreparedMaterial mat) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Проверь сообщение',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              gap(),
              SelectableText(mat.text),
              gap(20),
              const Text(
                'Откроется системное меню Android. Выбери приложение и получателя. RealHero не узнает, было ли сообщение отправлено.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              gap(),
              ActionButton(
                'Передать в другое приложение',
                icon: Icons.send,
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await const MethodChannel('realhero/actions').invokeMethod(
                      'shareText',
                      {'text': mat.text, 'title': 'Сообщение из RealHero'},
                    );
                    s.beginMission();
                    if (mounted) setState(() => scene = 'process');
                  } on MissingPluginException {
                    await Clipboard.setData(ClipboardData(text: mat.text));
                    notice(
                      'Текст скопирован. Отправь его выбранному получателю.',
                    );
                    begin();
                  } catch (_) {
                    notice(
                      'Не удалось открыть меню отправки. Текст доступен в материалах.',
                    );
                  }
                },
              ),
              gap(10),
              ActionButton(
                'Изменить текст',
                secondary: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  materialEditor(mat);
                },
              ),
              gap(8),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mat.text));
                  notice('Сообщение скопировано');
                },
                child: const Text('Скопировать текст'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> materialEditor(PreparedMaterial mat) async {
    final input = TextEditingController(text: mat.text);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          MediaQuery.viewInsetsOf(ctx).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mat.label,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gap(),
              if (s.isDemo && mat.kind == 'prototype') const DemoPrototype(),
              gap(10),
              TextField(
                controller: input,
                minLines: 4,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Подготовленный материал',
                ),
              ),
              gap(),
              ActionButton(
                'Сохранить изменения',
                onPressed: () {
                  s.editMaterial(mat.id, input.text);
                  Navigator.pop(ctx);
                },
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: input.text));
                  notice('Материал скопирован');
                },
                child: const Text('Скопировать'),
              ),
            ],
          ),
        ),
      ),
    );
    // Keep the controller alive until the closing sheet finishes its animation.
  }

  Future<void> noteEditor() async {
    final input = TextEditingController(text: s.currentMission?.note ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          MediaQuery.viewInsetsOf(ctx).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Заметка к миссии', style: TextStyle(fontSize: 22)),
              gap(),
              TextField(
                controller: input,
                minLines: 3,
                maxLines: 8,
                autofocus: true,
              ),
              gap(),
              ActionButton(
                'Сохранить',
                onPressed: () {
                  s.saveNote(input.text);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> resultEditor() async {
    final missionId = s.currentMission!.id;
    bool actionTaken = false;
    final facts = TextEditingController();
    final minutes = TextEditingController(
      text: '${s.currentMission?.minutes ?? 10}',
    );
    final observations = TextEditingController();
    OutcomeKind outcome = OutcomeKind.unknown;
    int difficulty = 2;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, local) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            0,
            22,
            MediaQuery.viewInsetsOf(ctx).bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Что произошло?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                gap(8),
                const Text(
                  'Любой фактический результат помогает выбрать следующий ход.',
                  style: TextStyle(color: muted),
                ),
                gap(),
                DropdownButtonFormField<OutcomeKind>(
                  isExpanded: true,
                  initialValue: outcome,
                  decoration: const InputDecoration(labelText: 'Результат'),
                  items: [
                    for (final kind in OutcomeKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Text(
                          outcomeLabel(kind),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => local(() => outcome = v!),
                ),
                gap(12),
                TextField(
                  controller: facts,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Что произошло в действительности?',
                    hintText: 'Например: согласился на пятницу / не ответил',
                  ),
                ),
                gap(12),
                TextField(
                  controller: observations,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Что удалось узнать? (необязательно)',
                  ),
                ),
                gap(12),
                TextField(
                  controller: minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Потрачено минут',
                  ),
                ),
                gap(12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Действие выполнено или попытка состоялась',
                  ),
                  subtitle: const Text('Без действия XP не начисляется'),
                  value: actionTaken,
                  onChanged: (value) =>
                      local(() => actionTaken = value ?? false),
                ),
                Text('Сложность: $difficulty из 5'),
                Slider(
                  value: difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$difficulty',
                  onChanged: (v) => local(() => difficulty = v.round()),
                ),
                gap(10),
                ActionButton(
                  'Сохранить результат',
                  icon: Icons.check,
                  onPressed: () {
                    if (facts.text.trim().isEmpty) {
                      notice(
                        'Опиши фактический результат хотя бы одним предложением.',
                      );
                      return;
                    }
                    final actual = int.tryParse(minutes.text);
                    if (actual == null || actual < 0 || actual > 1440) {
                      notice('Укажи время от 0 до 1440 минут.');
                      return;
                    }
                    s.completeMission(
                      missionId: missionId,
                      actionTaken: actionTaken,
                      outcome: outcome,
                      facts: facts.text.trim(),
                      actualMinutes: actual,
                      difficulty: difficulty,
                      observations: observations.text.trim(),
                    );
                    Navigator.pop(ctx);
                    setState(() => scene = 'today');
                    showResult(facts.text, observations.text, outcome);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String outcomeLabel(OutcomeKind k) => switch (k) {
    OutcomeKind.positive => 'Получилось / есть ответ',
    OutcomeKind.negative => 'Отказ / не получилось',
    OutcomeKind.noReply => 'Ответа пока нет',
    OutcomeKind.partial => 'Выполнено частично',
    OutcomeKind.unknown => 'Пока неясно',
  };
  Future<void> showResult(
    String facts,
    String learned,
    OutcomeKind outcome,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Опыт сохранён',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              gap(),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Что произошло', style: TextStyle(color: teal)),
                    gap(6),
                    Text(facts),
                    if (learned.isNotEmpty) ...[
                      gap(),
                      const Text(
                        'Что удалось узнать',
                        style: TextStyle(color: teal),
                      ),
                      gap(6),
                      Text(learned),
                    ],
                  ],
                ),
              ),
              gap(),
              Text(
                outcome == OutcomeKind.positive
                    ? 'Появился результат, на который можно опереться.'
                    : outcome == OutcomeKind.noReply
                    ? 'Отсутствие ответа — пока неопределённость. Лея учтёт это, без выдуманного успеха.'
                    : 'Эта попытка дала информацию. Следующий ход должен её учитывать.',
              ),
              gap(),
              Text(
                'Получено ${s.lastOutcome?.xpEarned ?? 0} XP. ${s.lastOutcome?.goalImpact ?? ''}',
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              gap(10),
              Text(
                s.lastOutcome?.nextDirection ??
                    'Следующий ход зависит от твоего результата.',
              ),
              gap(20),
              ActionButton(
                'Посмотреть следующий ход',
                onPressed: () {
                  Navigator.pop(ctx);
                  nextMission();
                },
              ),
              gap(10),
              ActionButton(
                'Открыть твой путь',
                secondary: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  select(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> nextMission() async {
    if (s.isDemo) {
      setState(() {
        tab = 0;
        scene = 'today';
      });
      return;
    }
    openChat();
    await sendChat(
      message:
          'Учти фактический результат последней миссии, потраченное время и сложность. Подготовь обоснованный следующий ход и материалы.',
      operation: 'adapt',
    );
  }

  Future<void> adapt(String reason) async {
    if (s.isDemo) {
      if (reason.contains('другой') ||
          reason.contains('иной') ||
          reason.contains('отклонил')) {
        s.replaceDemoMission(reason);
        notice('Демо: предложен другой ход, история сохранена.');
      } else {
        s.shrinkMission();
        notice('Демо: действие уменьшено, подготовка сохранена.');
      }
      return;
    }
    openChat();
    await sendChat(message: reason, operation: 'adapt');
  }

  Future<void> missionOptions() async {
    if (s.currentMission?.isClosed == true) {
      await showText(
        'Миссия закрыта',
        'Результат и подготовка сохранены в истории. Следующий ход можно обсудить с Леей.',
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton(
              'Уменьшить действие',
              secondary: true,
              onPressed: () {
                Navigator.pop(ctx);
                adapt('Уменьши миссию: сейчас мало времени и сил.');
              },
            ),
            gap(8),
            ActionButton(
              'Предложить другой способ',
              secondary: true,
              onPressed: () {
                Navigator.pop(ctx);
                adapt(
                  'Этот способ мне не подходит. Предложи иной ход к той же цели.',
                );
              },
            ),
            gap(8),
            ActionButton(
              'Отложить до завтра',
              secondary: true,
              onPressed: () {
                s.deferMission(DateTime.now().add(const Duration(days: 1)));
                Navigator.pop(ctx);
                notice('Перенос сохранён. XP не списывается.');
              },
            ),
            gap(8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                declineEditor();
              },
              child: const Text('Отклонить миссию'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> chooseDay() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Когда вернуться к миссии?',
      cancelText: 'Отмена',
      confirmText: 'Сохранить',
    );
    if (day != null) {
      s.deferMission(day);
      notice('День сохранён: ${day.day}.${day.month}.${day.year}.');
    }
  }

  Future<void> declineEditor() async {
    final input = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Почему этот ход не подходит?'),
        content: TextField(
          controller: input,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Необязательно, но поможет Лее',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Назад'),
          ),
          TextButton(
            onPressed: () {
              s.declineMission(input.text);
              Navigator.pop(ctx);
              setState(() => scene = 'today');
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  Future<void> historySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'История миссий',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              gap(),
              if (s.history.isEmpty)
                const Text('Здесь будут твои миссии и результаты.'),
              for (final m in s.history.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.title),
                  subtitle: Text(switch (m.status) {
                    MissionStatus.prepared => 'Подготовлена',
                    MissionStatus.active => 'В процессе',
                    MissionStatus.paused => 'На паузе',
                    MissionStatus.deferred => 'Перенесена',
                    MissionStatus.declined => 'Отклонена',
                    MissionStatus.completed => 'Результат сохранён',
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    missionHistory(m);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void missionHistory(Mission m) {
    showText(
      m.title,
      'Почему: ${m.why}\n\nДействие: ${m.oneAction}\n\nПодготовка:\n${m.materials.map((a) => '${a.label}\n${a.text}').join('\n\n')}\n\n${m.outcome == null ? 'Фактический результат пока не записан.' : m.outcome.toString()}\n\nЗаметка: ${m.note}',
    );
  }

  Future<void> profileEditor() async {
    final input = TextEditingController(text: s.profile.name);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Как к тебе обращаться?'),
        content: TextField(controller: input, maxLength: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Назад'),
          ),
          TextButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                s.updateProfile(name: input.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void newGoal() {
    if (busy) return;
    s.openGoalEntry();
    openChat();
  }

  void beginKnownGoal() {
    if (busy) return;
    final text = s.state.discovery.goalText.trim();
    if (text.isEmpty) return;
    s.setGoal(text);
    unawaited(sendChat(message: '$text\n\nПомоги начать с одного лёгкого действия. Если для этого нужно выбрать направление, предложи два конкретных варианта и «Пока ничего».', displayMessage: text, operation: 'onboard'));
  }

  void prepareDiscovery() {
    if (busy || s.state.discovery.phase != DiscoveryPhase.review) return;
    final brief = s.finishDiscovery();
    openChat();
    unawaited(sendChat(message: brief, displayMessage: 'Мои ответы готовы. Подбери посильный шаг.', operation: 'onboard'));
  }

  Future<void> settings() async {
    final url = TextEditingController(text: s.settings.url);
    final token = TextEditingController(text: s.settings.accessToken);
    final contextInput = TextEditingController(text: s.goal?.context ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
          22,
          MediaQuery.viewInsetsOf(ctx).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Настройки',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              gap(),
              const Text(
                'Моё понимание можно исправить',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              gap(8),
              TextField(
                controller: contextInput,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Важный контекст и ограничения',
                ),
              ),
              gap(20),
              const Text(
                'Подключение Леи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              gap(8),
              const Text(
                'Адрес твоего сервера и код доступа к нему. Ключ OpenAI хранится на сервере.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              gap(12),
              TextField(
                controller: url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Адрес сервера',
                  hintText: 'https://…',
                ),
              ),
              gap(12),
              TextField(
                controller: token,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Код доступа к серверу',
                ),
              ),
              gap(),
              ActionButton(
                'Сохранить',
                onPressed: () {
                  final parsed = Uri.tryParse(url.text.trim());
                  if (token.text.trim().startsWith('sk-')) {
                    notice(
                      'Здесь нужен код доступа к RealHero. Ключ OpenAI остаётся только на сервере.',
                    );
                    return;
                  }
                  if (url.text.trim().isNotEmpty &&
                      (parsed == null ||
                          !['http', 'https'].contains(parsed.scheme) ||
                          parsed.host.isEmpty ||
                          parsed.userInfo.isNotEmpty)) {
                    notice('Укажи полный адрес сервера: https://…');
                    return;
                  }
                  if (url.text.trim().isNotEmpty) {
                    s.configureServer(url.text.trim(), token.text.trim());
                  }
                  if (s.goal != null) s.updateContext(contextInput.text);
                  Navigator.pop(ctx);
                  notice('Настройки сохранены');
                },
              ),
              gap(8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  newGoal();
                },
                child: const Text('Начать другую цель'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoPrototype extends StatelessWidget {
  const DemoPrototype({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Демонстрационные материалы · два готовых экрана',
        style: TextStyle(color: violet, fontSize: 12),
      ),
      gap(12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in [
            ('Сегодня', 'Один следующий ход', Icons.near_me),
            ('Твой путь', 'Опыт складывается в изменения', Icons.public),
          ])
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(minHeight: 220),
                decoration: BoxDecoration(
                  color: ink,
                  border: Border.all(color: teal.withValues(alpha: .4)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    gap(20),
                    Icon(item.$3, color: teal, size: 36),
                    gap(16),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    gap(20),
                    Container(
                      height: 23,
                      decoration: BoxDecoration(
                        color: teal,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      gap(12),
      const Text(
        'Эти два примера существуют в деморежиме. В собственной миссии Лея не будет утверждать, что твой прототип готов, пока ты не предоставишь материалы.',
        style: TextStyle(fontSize: 12, color: muted),
      ),
    ],
  );
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  const _ChatBubble({super.key, required this.message});
  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final lengthy = message.role != 'user' && message.text.length > 260;
    final text = lengthy && !expanded ? '${message.text.substring(0, 257)}…' : message.text;
    return Align(
      alignment: message.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(color: message.role == 'user' ? teal.withValues(alpha: .12) : panel,
          borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          SelectableText(text),
          if (lengthy) TextButton(onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Свернуть' : 'Читать дальше')),
        ]),
      ),
    );
  }
}
