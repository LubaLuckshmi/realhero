import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'domain.dart';
import 'widgets.dart';

/// Native controls over the approved cafe scene. Selecting a step is navigation,
/// not evidence that a real-world action or conversation has happened.
class ProcessView extends StatelessWidget {
  final Mission mission;
  final bool isDemo;
  final VoidCallback onBack;
  final VoidCallback onPause;
  final VoidCallback onLeia;
  final VoidCallback onNote;
  final VoidCallback onResult;
  final VoidCallback onMaterials;
  final ValueChanged<int> onStep;
  final ValueChanged<int> onQuestion;

  const ProcessView({
    super.key,
    required this.mission,
    required this.isDemo,
    required this.onBack,
    required this.onPause,
    required this.onLeia,
    required this.onNote,
    required this.onResult,
    required this.onMaterials,
    required this.onStep,
    required this.onQuestion,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final scale = math.min(bounds.maxWidth / 390, bounds.maxHeight / 820)
          .clamp(.82, 1.4).toDouble();
      final inset = 22 * scale;
      final index = mission.steps.isEmpty
          ? 0
          : mission.currentStep.clamp(0, mission.steps.length - 1).toInt();
      final step = mission.activeStep;
      final questions = mission.preparedQuestions;
      final asksQuestion = questions.isNotEmpty &&
          (RegExp(r'вопрос|спрос|задай', caseSensitive: false)
                  .hasMatch(step?.title ?? '') ||
              RegExp(r'^(ask|questions?)$', caseSensitive: false)
                  .hasMatch(step?.id ?? ''));
      final questionIndex = questions.isEmpty
          ? 0
          : mission.currentQuestion.clamp(0, questions.length - 1).toInt();
      final focus = asksQuestion
          ? questions[questionIndex]
              .replaceFirst(RegExp(r'^\s*(?:\d+[.)]|[•—–-])\s*'), '')
          : (step?.hint.trim().isNotEmpty ?? false)
              ? step!.hint
              : mission.oneAction;
      final paused = mission.status == MissionStatus.paused;
      final sceneHeight = math.max(
        bounds.maxWidth * 1.5,
        math.min(bounds.maxHeight * .82, bounds.maxWidth * 1.8),
      ).toDouble();

      return Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: ink)),
          Positioned(
            top: 0, left: 0, right: 0, height: sceneHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/workspace.png',
                    fit: BoxFit.cover, alignment: Alignment.topCenter),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ink.withValues(alpha: .46), ink.withValues(alpha: .12),
                        ink.withValues(alpha: .26), ink],
                      stops: const [0, .35, .68, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                key: PageStorageKey('process-${mission.id}'),
                padding: EdgeInsets.fromLTRB(inset, 8, inset, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, viewport.maxHeight - 20).toDouble(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 18 * scale),
                        child: _ProcessHeading(
                          title: (step?.title.trim().isNotEmpty ?? false)
                              ? step!.title : mission.title,
                          position: mission.steps.isEmpty
                              ? null : '${index + 1} / ${mission.steps.length}',
                          status: paused ? 'Миссия на паузе'
                              : isDemo ? 'Демо · Твой текущий шаг' : 'Твой текущий шаг',
                          minutes: mission.minutes,
                          scale: scale,
                          onBack: onBack,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20 * scale),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                              child: _FocusFrame(
                                label: asksQuestion
                                    ? 'ВОПРОС ${questionIndex + 1} ИЗ ${questions.length}'
                                    : 'ТЕКУЩИЙ ШАГ',
                                text: focus,
                                hint: asksQuestion ? 'Дай время на ответ.' : 'В своём темпе.',
                                scale: scale,
                                minimumHeight: 178 * scale,
                                onPrevious: asksQuestion && questionIndex > 0
                                    ? () => onQuestion(questionIndex - 1) : null,
                                onNext: asksQuestion && questionIndex + 1 < questions.length
                                    ? () => onQuestion(questionIndex + 1) : null,
                              ),
                            ),
                            if (mission.steps.isNotEmpty) ...[
                              SizedBox(
                                width: double.infinity, height: 24 * scale,
                                child: const ExcludeSemantics(
                                  child: CustomPaint(painter: _FocusLinkPainter()),
                                ),
                              ),
                              _StepRail(steps: mission.steps, current: index,
                                  scale: scale, onStep: onStep),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LeiaCompanion(scale: scale, onTap: onLeia),
                          SizedBox(height: 12 * scale),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: _ProcessControl(
                                icon: paused ? Icons.play_arrow : Icons.pause,
                                label: paused ? 'Продолжить' : 'Пауза',
                                scale: scale, onTap: onPause)),
                              Expanded(flex: 2, child: _ProcessControl(
                                icon: Icons.chat_bubble_outline, label: 'Написать Лее',
                                scale: scale, onTap: onLeia, primary: true)),
                              Expanded(child: _ProcessControl(
                                icon: Icons.note_outlined, label: 'Заметка',
                                scale: scale, onTap: onNote)),
                            ],
                          ),
                          SizedBox(height: 16 * scale),
                          _ResultButton(
                            label: asksQuestion ? 'Зафиксировать ответ' : 'Зафиксировать результат',
                            scale: scale, onTap: onResult),
                          TextButton(onPressed: onMaterials,
                            child: const Text('Открыть все материалы', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ProcessHeading extends StatelessWidget {
  final String title, status;
  final String? position;
  final int minutes;
  final double scale;
  final VoidCallback onBack;
  const _ProcessHeading({required this.title, required this.position,
    required this.status, required this.minutes, required this.scale, required this.onBack});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        IconButton(onPressed: onBack, tooltip: 'Вернуться к миссии',
          padding: EdgeInsets.zero, alignment: Alignment.centerLeft,
          icon: Icon(Icons.arrow_back, size: 26 * scale)),
        Expanded(child: Text('В процессе',
          style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w500))),
        if (position != null) Text(position!, style: TextStyle(fontSize: 17 * scale)),
      ]),
      SizedBox(height: 12 * scale),
      Row(children: [
        const Icon(Icons.circle, size: 8, color: teal),
        const SizedBox(width: 8),
        Expanded(child: Text(status, style: TextStyle(fontSize: 13 * scale))),
      ]),
      SizedBox(height: 10 * scale),
      Text(title, key: const ValueKey('process-step-title'),
        style: TextStyle(fontSize: 40 * scale, fontWeight: FontWeight.w800,
          height: 1.03, letterSpacing: -.8,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 12)])),
      SizedBox(height: 12 * scale),
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF263341).withValues(alpha: .86),
          border: Border.all(color: muted.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.schedule, size: 18 * scale, color: muted),
            const SizedBox(width: 7),
            Flexible(child: Text('Ориентир · $minutes мин',
              style: TextStyle(fontSize: 13 * scale, color: muted))),
          ]),
        ),
      ),
    ],
  );
}

class _FocusFrame extends StatelessWidget {
  final String label, text, hint;
  final double scale, minimumHeight;
  final VoidCallback? onPrevious, onNext;
  const _FocusFrame({required this.label, required this.text, required this.hint,
    required this.scale, required this.minimumHeight, this.onPrevious, this.onNext});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16 * scale),
      boxShadow: [BoxShadow(color: teal.withValues(alpha: .18), blurRadius: 24)]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          key: const ValueKey('process-focus'), width: double.infinity,
          constraints: BoxConstraints(minHeight: minimumHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [teal.withValues(alpha: .13), ink.withValues(alpha: .55)]),
            border: Border.all(color: teal, width: 1.5),
            borderRadius: BorderRadius.circular(16 * scale)),
          child: CustomPaint(
            foregroundPainter: _FocusCornersPainter(scale),
            child: Padding(
              padding: EdgeInsets.fromLTRB(22 * scale, 18 * scale, 22 * scale, 22 * scale),
              child: Column(mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onPrevious != null || onNext != null)
                    Row(children: [
                      _QuestionArrow(previous: true, onTap: onPrevious),
                      Expanded(child: Text(label, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11 * scale, color: muted))),
                      _QuestionArrow(previous: false, onTap: onNext),
                    ])
                  else
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(label, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11 * scale, color: muted, letterSpacing: .6))),
                  SizedBox(height: 8 * scale),
                  Text(text, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28 * scale, height: 1.13, fontWeight: FontWeight.w700)),
                  SizedBox(height: 16 * scale),
                  Text(hint, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13 * scale, color: muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuestionArrow extends StatelessWidget {
  final bool previous;
  final VoidCallback? onTap;
  const _QuestionArrow({required this.previous, this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: previous ? 'Предыдущий вопрос' : 'Следующий вопрос',
    color: teal, disabledColor: muted.withValues(alpha: .25), iconSize: 22,
    icon: Icon(previous ? Icons.chevron_left : Icons.chevron_right));
}

class _StepRail extends StatelessWidget {
  final List<MissionStep> steps;
  final int current;
  final double scale;
  final ValueChanged<int> onStep;
  const _StepRail({required this.steps, required this.current,
    required this.scale, required this.onStep});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final nodeSize = 28 * scale;
    return Stack(children: [
      if (steps.length > 1)
        Positioned(left: bounds.maxWidth / (2 * steps.length),
          right: bounds.maxWidth / (2 * steps.length), top: nodeSize / 2 + 8,
          child: Container(height: 1.5, color: muted.withValues(alpha: .45))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(child: Semantics(
            button: true, selected: i == current,
            label: 'Шаг ${i + 1} из ${steps.length}: ${steps[i].title}',
            onTap: () => onStep(i),
            child: ExcludeSemantics(child: Material(color: Colors.transparent,
              child: InkWell(
                key: ValueKey('process-step-$i'), onTap: () => onStep(i),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                  child: Column(children: [
                    Container(width: nodeSize, height: nodeSize,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: i == current ? teal : ink.withValues(alpha: .8),
                        border: Border.all(color: i == current ? teal : muted, width: 1.6),
                        boxShadow: i == current
                          ? [BoxShadow(color: teal.withValues(alpha: .28), blurRadius: 14)] : null),
                      child: i == current ? const Icon(Icons.circle, size: 9, color: ink) : null),
                    SizedBox(height: 7 * scale),
                    Text(steps[i].title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11 * scale, height: 1.2,
                        color: i == current ? teal : muted)),
                  ]),
                ),
              ),
            )),
          )),
      ]),
    ]);
  });
}

class _FocusCornersPainter extends CustomPainter {
  final double scale;
  const _FocusCornersPainter(this.scale);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = teal..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.square;
    final inset = 12 * scale, length = 16 * scale;
    for (final point in [Offset(inset, inset), Offset(size.width - inset, inset),
      Offset(inset, size.height - inset), Offset(size.width - inset, size.height - inset)]) {
      final dx = point.dx < size.width / 2 ? length : -length;
      final dy = point.dy < size.height / 2 ? length : -length;
      canvas.drawPath(Path()..moveTo(point.dx, point.dy + dy)
        ..lineTo(point.dx, point.dy)..lineTo(point.dx + dx, point.dy), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _FocusCornersPainter oldDelegate) => scale != oldDelegate.scale;
}

class _FocusLinkPainter extends CustomPainter {
  const _FocusLinkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final end = Offset(size.width * .89, size.height - 3);
    canvas.drawPath(Path()..moveTo(size.width * .82, 0)
      ..lineTo(end.dx, end.dy)..lineTo(size.width * .72, end.dy),
      Paint()..color = teal.withValues(alpha: .7)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    canvas.drawCircle(end, 3, Paint()..color = teal);
  }
  @override
  bool shouldRepaint(covariant _FocusLinkPainter oldDelegate) => false;
}

class _LeiaCompanion extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  const _LeiaCompanion({required this.scale, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: panel.withValues(alpha: .83),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 * scale),
      side: BorderSide(color: teal.withValues(alpha: .15))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(
      padding: EdgeInsets.all(5 * scale),
      child: Row(children: [
        Container(width: 52 * scale, height: 52 * scale,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: teal.withValues(alpha: .7), width: 1.5)),
          child: ClipOval(child: Image.asset('assets/images/leia-portrait.png', fit: BoxFit.cover))),
        SizedBox(width: 12 * scale),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Лея', style: TextStyle(fontSize: 17 * scale, fontWeight: FontWeight.w600)),
          Text('Я помогу зафиксировать главное.', style: TextStyle(fontSize: 13 * scale, color: muted)),
        ])),
        const SizedBox(width: 8),
      ]),
    )),
  );
}

class _ProcessControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;
  final bool primary;
  const _ProcessControl({required this.icon, required this.label,
    required this.scale, required this.onTap, this.primary = false});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: primary
      ? [BoxShadow(color: violet.withValues(alpha: .3), blurRadius: 26)] : null),
      child: IconButton.filledTonal(onPressed: onTap, tooltip: label,
        icon: Icon(icon, size: (primary ? 35 : 23) * scale, color: Colors.white),
        style: IconButton.styleFrom(
          fixedSize: Size.square(math.max(48.0, (primary ? 80 : 54) * scale).toDouble()),
          backgroundColor: primary ? violet.withValues(alpha: .23) : ink.withValues(alpha: .75),
          side: BorderSide(color: primary ? violet : muted.withValues(alpha: .4), width: 1.2)))),
    SizedBox(height: 7 * scale),
    Text(label, textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12 * scale, height: 1.2)),
  ]);
}

class _ResultButton extends StatelessWidget {
  final String label;
  final double scale;
  final VoidCallback onTap;
  const _ResultButton({required this.label, required this.scale, required this.onTap});
  @override
  Widget build(BuildContext context) => FilledButton(
    key: const ValueKey('process-result'), onPressed: onTap,
    style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 58 * scale),
      backgroundColor: teal, foregroundColor: ink,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32 * scale))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.near_me_rounded, size: 28 * scale),
      SizedBox(width: 12 * scale),
      Flexible(child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18 * scale, height: 1.15, fontWeight: FontWeight.w700))),
    ]),
  );
}
