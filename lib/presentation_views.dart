import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'domain.dart';
import 'widgets.dart';

double sceneScale(BoxConstraints bounds) =>
    math.min(bounds.maxWidth / 390, bounds.maxHeight / 780).clamp(.85, 1.4).toDouble();

String materialCount(int n) {
  if (n % 100 >= 11 && n % 100 <= 14) return '$n материалов готовы';
  return switch (n % 10) {
    1 => '$n материал готов',
    2 || 3 || 4 => '$n материала готовы',
    _ => '$n материалов готовы',
  };
}

/// The photo has its own extent. It never stretches with the scrollable text.
class TodayView extends StatelessWidget {
  final Mission mission;
  final String name;
  final bool isDemo;
  final Widget action;
  final VoidCallback onProfile, onLeia, onPreparation, onPreview, onWhy, onEasier, onOptions;
  const TodayView({super.key, required this.mission, required this.name,
    required this.isDemo, required this.action, required this.onProfile,
    required this.onLeia, required this.onPreparation, required this.onPreview,
    required this.onWhy, required this.onEasier, required this.onOptions});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final scale = sceneScale(bounds);
    final inset = 22 * scale;
    final stageHeight = (bounds.maxHeight * .60).clamp(390 * scale, 470 * scale).toDouble();
    final draft = mission.materials.where((m) => m.kind == 'message').firstOrNull;
    final preview = draft ?? mission.materials.firstOrNull;
    final ready = mission.status == MissionStatus.completed
        ? 'Результат сохранён. Выберем следующий ход.'
        : draft != null ? 'Сообщение и материалы готовы.'
        : preview != null ? 'Я подготовила первый шаг.' : 'Начнём с одного действия.';
    return ColoredBox(color: ink, child: SingleChildScrollView(
      key: ValueKey('today-${mission.id}'),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: stageHeight + 64 * scale,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/horizon.png', key: const ValueKey('today-landscape'),
              fit: BoxFit.cover, alignment: Alignment.bottomCenter),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [ink.withValues(alpha: .82), ink.withValues(alpha: .40),
                Colors.transparent, Colors.transparent, ink],
              stops: const [0, .24, .49, .83, 1]))),
            const ExcludeSemantics(child: CustomPaint(painter: SkyStarsPainter())),
          ])),
        Padding(padding: EdgeInsets.symmetric(horizontal: inset), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: stageHeight, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14 * scale),
                Row(children: [
                  HeroStar(size: 36 * scale), SizedBox(width: 10 * scale),
                  Expanded(child: Text('RealHero', style: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.w600))),
                  Semantics(label: 'Открыть профиль', button: true,
                    child: InkWell(onTap: onProfile, borderRadius: BorderRadius.circular(32),
                      child: Avatar(size: 46 * scale))),
                ]),
                SizedBox(height: 24 * scale),
                if (isDemo) ...[
                  Text('ДЕМО · пример из макета', style: TextStyle(color: violet, fontSize: 10 * scale)),
                  SizedBox(height: 6 * scale),
                ],
                Text('Привет, $name', style: TextStyle(fontSize: 20 * scale, color: const Color(0xFFD9E4E9))),
                SizedBox(height: 10 * scale),
                Text(mission.title, key: const ValueKey('today-title'),
                  style: TextStyle(fontSize: 34 * scale, height: 1.06,
                    letterSpacing: -.7, fontWeight: FontWeight.w800)),
                SizedBox(height: 12 * scale),
                Text('${materialCount(mission.materials.length)} · ${mission.minutes} минут',
                  style: TextStyle(fontSize: 16 * scale, color: const Color(0xFFE2EAED))),
              ],
            )),
            LeiaLine(ready, onTap: onLeia, scale: scale),
            Material(color: panel.withValues(alpha: .94), borderRadius: BorderRadius.circular(12),
              child: InkWell(onTap: onPreview, borderRadius: BorderRadius.circular(12),
                child: Container(key: const ValueKey('today-preparation'),
                  padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 11 * scale),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: teal, width: 4 * scale)),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(preview?.text ?? mission.oneAction,
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15 * scale, height: 1.35))))),
            SizedBox(height: 16 * scale),
            action,
            TextButton(onPressed: onPreparation, child: Text('Посмотреть подготовку',
              style: TextStyle(fontSize: 14 * scale))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: TextButton(onPressed: onWhy, child: const Text('Почему этот ход', style: TextStyle(fontSize: 12)))),
              Flexible(child: TextButton(onPressed: onEasier, child: const Text('Сделать легче', style: TextStyle(fontSize: 12)))),
              IconButton(onPressed: onOptions, tooltip: 'Изменить или перенести миссию', icon: const Icon(Icons.more_horiz)),
            ]),
            if (mission.status == MissionStatus.deferred)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Миссия перенесена. Вернись, когда будет удобно.',
                style: TextStyle(color: muted, fontSize: 13))),
            const SizedBox(height: 8),
          ],
        )),
      ]),
    ));
  });
}

class MissionView extends StatelessWidget {
  final Mission mission;
  final bool isDemo;
  final VoidCallback onBack, onOptions, onLeia, onBegin, onNext, onChange;
  final ValueChanged<PreparedMaterial> onMaterial;
  const MissionView({super.key, required this.mission, required this.isDemo,
    required this.onBack, required this.onOptions, required this.onLeia,
    required this.onBegin, required this.onNext, required this.onChange, required this.onMaterial});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final scale = sceneScale(bounds);
    final inset = 22 * scale;
    final photoHeight = 184 * scale;
    return ColoredBox(color: ink, child: SingleChildScrollView(
      key: ValueKey('mission-${mission.id}'),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: photoHeight + 42 * scale,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/mission-header.png', key: const ValueKey('mission-header-photo'),
              fit: BoxFit.cover, alignment: Alignment.center),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [ink.withValues(alpha: .28), Colors.transparent, ink],
              stops: const [0, .53, 1]))),
          ])),
        Padding(padding: EdgeInsets.fromLTRB(inset, 10 * scale, inset, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: photoHeight - 10 * scale, child: Align(alignment: Alignment.topCenter,
              child: Row(children: [
                IconButton(onPressed: onBack, tooltip: 'Назад', icon: const Icon(Icons.arrow_back_ios_new, size: 23)),
                Expanded(child: Text('Миссия', style: TextStyle(fontSize: 23 * scale, fontWeight: FontWeight.w600))),
                IconButton(onPressed: onOptions, tooltip: 'Изменить или перенести миссию', icon: const Icon(Icons.more_horiz)),
              ]))),
            Text(isDemo ? 'Демо уже готово' : 'Всё уже готово',
              style: TextStyle(fontSize: 34 * scale, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -.6)),
            SizedBox(height: 7 * scale),
            Text('${mission.title} · ${mission.minutes} минут',
              style: TextStyle(fontSize: 16 * scale, color: muted, height: 1.25)),
            if (isDemo) Padding(padding: const EdgeInsets.only(top: 6),
              child: Text('ДЕМО · пример из макета', style: TextStyle(color: violet, fontSize: 10 * scale))),
            SizedBox(height: 24 * scale),
            for (var i = 0; i < mission.steps.length; i++)
              MissionTimelineRow(step: mission.steps[i], number: i + 1,
                current: i == mission.currentStep, last: i == mission.steps.length - 1, scale: scale),
            SizedBox(height: 9 * scale),
            for (final material in mission.materials) ...[
              GlassPanel(padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 11 * scale),
                onTap: () => onMaterial(material), child: Row(children: [
                  Icon(material.kind == 'questions' ? Icons.help_outline
                    : material.kind == 'message' ? Icons.send_outlined : Icons.attach_file,
                    size: 25 * scale, color: const Color(0xFFD5E2E6)),
                  SizedBox(width: 15 * scale),
                  Expanded(child: Text(material.label, style: TextStyle(fontSize: 15 * scale, height: 1.2))),
                  SizedBox(width: 7 * scale),
                  Icon(Icons.chevron_right, size: 23 * scale, color: muted),
                ])),
              SizedBox(height: 8 * scale),
            ],
            LeiaLine('Я всё подготовила.', onTap: onLeia, scale: scale),
            ActionButton(mission.isClosed ? 'Подготовить следующий ход' : 'Перейти к действию',
              icon: Icons.near_me, onPressed: mission.isClosed ? onNext : onBegin),
            TextButton(onPressed: onChange, child: const Text('Изменить миссию', style: TextStyle(fontSize: 13))),
          ])),
      ]),
    ));
  });
}

class MissionTimelineRow extends StatelessWidget {
  final MissionStep step;
  final int number;
  final bool current, last;
  final double scale;
  const MissionTimelineRow({super.key, required this.step, required this.number,
    required this.current, required this.last, required this.scale});
  @override
  Widget build(BuildContext context) => Stack(children: [
    if (!last) Positioned(left: 23 * scale, top: 45 * scale, bottom: 0,
      child: Container(width: 1.2, color: current ? teal.withValues(alpha: .6) : const Color(0xFF35515B))),
    Padding(padding: EdgeInsets.only(bottom: 22 * scale), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 47 * scale, height: 47 * scale,
        decoration: BoxDecoration(shape: BoxShape.circle, color: current ? teal : panel,
          border: Border.all(color: current ? teal : const Color(0xFF62818E)),
          boxShadow: [if (current) BoxShadow(color: teal.withValues(alpha: .27), blurRadius: 18)]),
        alignment: Alignment.center,
        child: Text('$number', style: TextStyle(fontSize: 24 * scale, color: current ? ink : muted))),
      SizedBox(width: 19 * scale),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step.title, style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w700, height: 1.2)),
        SizedBox(height: 4 * scale),
        Text(step.hint, style: TextStyle(fontSize: 14 * scale, color: muted, height: 1.3)),
      ])),
    ])),
  ]);
}

class HeroStar extends StatelessWidget {
  final double size;
  const HeroStar({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size,
    child: const CustomPaint(painter: _StarPainter()));
}

class _StarPainter extends CustomPainter {
  const _StarPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width * .3, Paint()..color = Colors.white24
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    final p = Path()..moveTo(c.dx, 0)..lineTo(c.dx + 3, c.dy - 3)
      ..lineTo(size.width, c.dy)..lineTo(c.dx + 3, c.dy + 3)
      ..lineTo(c.dx, size.height)..lineTo(c.dx - 3, c.dy + 3)
      ..lineTo(0, c.dy)..lineTo(c.dx - 3, c.dy - 3)..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFF4FCFF));
  }
  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

class SkyStarsPainter extends CustomPainter {
  const SkyStarsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(23);
    for (var i = 0; i < 65; i++) {
      final y = random.nextDouble() * size.height * .46;
      canvas.drawCircle(Offset(random.nextDouble() * size.width, y),
        random.nextDouble() * .55 + .2,
        Paint()..color = const Color(0xFFECC48E).withValues(alpha: .14 + random.nextDouble() * .3));
    }
  }
  @override
  bool shouldRepaint(SkyStarsPainter oldDelegate) => false;
}
