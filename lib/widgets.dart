import 'dart:math' as math;
import 'package:flutter/material.dart';

const ink = Color(0xFF03171F);
const panel = Color(0xFF092630);
const teal = Color(0xFF26EFDA);
const muted = Color(0xFFACC2CF);
const violet = Color(0xFFAF70EF);

class HeroBackdrop extends StatelessWidget {
  final String? image;
  final Widget child;
  final bool dim;
  const HeroBackdrop({
    super.key,
    this.image,
    required this.child,
    this.dim = false,
  });
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: Container(color: ink)),
      if (image != null)
        Positioned.fill(
          child: Image.asset(
            'assets/images/$image',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: ink),
          ),
        ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ink.withValues(alpha: dim ? .7 : .28),
                ink.withValues(alpha: .12),
                ink.withValues(alpha: .94),
                ink,
              ],
              stops: const [0, .36, .76, 1],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  const ActionButton(
    this.text, {
    super.key,
    this.onPressed,
    this.icon,
    this.secondary = false,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final scale = (bounds.maxWidth / 346).clamp(1.0, 1.35).toDouble();
    return SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? panel : teal,
        foregroundColor: secondary ? Colors.white : ink,
        minimumSize: Size(0, 54 * scale),
        side: secondary ? const BorderSide(color: Color(0xFF20505D)) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14 * scale),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24 * scale),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
  });
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: panel.withValues(alpha: .83),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF24505C)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final double size;
  const Avatar({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: teal.withValues(alpha: .5), width: 1.5),
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/images/avatar.png',
        fit: BoxFit.cover,
        alignment: const Alignment(.7, .2),
        errorBuilder: (_, _, _) => const ColoredBox(
          color: panel,
          child: Icon(Icons.person_outline, color: teal),
        ),
      ),
    ),
  );
}

class LeiaPortrait extends StatelessWidget {
  final double size;
  const LeiaPortrait({super.key, this.size = 46});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(shape: BoxShape.circle,
      border: Border.all(color: teal.withValues(alpha: .5), width: 1.3)),
    child: ClipOval(child: Image.asset('assets/images/leia-portrait.png', fit: BoxFit.cover)));
}

class LeiaNavIcon extends StatelessWidget {
  const LeiaNavIcon({super.key});
  @override
  Widget build(BuildContext context) => Container(width: 38, height: 38,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(colors: [violet.withValues(alpha: .22), violet.withValues(alpha: .04)]),
      border: Border.all(color: violet.withValues(alpha: .22)),
      boxShadow: [BoxShadow(color: violet.withValues(alpha: .12), blurRadius: 14)]),
    child: const Icon(Icons.graphic_eq, color: violet, size: 26));
}

class LeiaLine extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double scale;
  const LeiaLine(this.text, {super.key, required this.onTap, this.scale = 1});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Padding(padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Row(children: [
        LeiaPortrait(size: 46 * scale),
        SizedBox(width: 12 * scale),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14 * scale, height: 1.3))),
      ])));
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(action!, style: const TextStyle(color: teal)),
        ),
    ],
  );
}

class BadgeArt extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool unlocked;
  const BadgeArt({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.unlocked = true,
  });
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: unlocked ? 1 : .36,
    child: Column(
      children: [
        SizedBox(
          height: 70,
          width: 67,
          child: CustomPaint(
            painter: _BadgePainter(color),
            child: Icon(icon, color: color, size: 34),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.3),
        ),
      ],
    ),
  );
}

class _BadgePainter extends CustomPainter {
  final Color color;
  _BadgePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 4, 16)
      ..lineTo(size.width - 7, size.height - 18)
      ..lineTo(size.width / 2, size.height - 3)
      ..lineTo(7, size.height - 18)
      ..lineTo(4, 16)
      ..close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: .13));
    canvas.drawPath(
      p,
      Paint()
        ..color = color.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.color != color;
}

enum OrbitStage { done, current, recorded, future }

class OrbitMap extends StatelessWidget {
  final List<OrbitStage> states;
  final void Function(int) onNode;
  const OrbitMap({super.key, required this.states, required this.onNode});
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1.14,
    child: LayoutBuilder(builder: (context, bounds) {
      final w = bounds.maxWidth, h = bounds.maxHeight;
      final nodeSize = (w * .12).clamp(40.0, 60.0).toDouble();
      final angles = [math.pi, -2.06, -.94, 0.0, .94, 2.06];
      return Stack(alignment: Alignment.center, children: [
        const Positioned.fill(child: CustomPaint(painter: _OrbitPainter())),
        Container(width: w * .30, height: w * .30,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: const Color(0xFFFFAA67).withValues(alpha: .30), blurRadius: w * .06, spreadRadius: 4),
            BoxShadow(color: const Color(0xFFEA8C4A).withValues(alpha: .16), blurRadius: w * .12),
          ]),
          child: ClipOval(child: Stack(fit: StackFit.expand, children: [
            ColorFiltered(colorFilter: const ColorFilter.matrix([
              1.03, .05, 0, 0, 0, .03, .79, 0, 0, 0, 0, .03, .61, 0, 0, 0, 0, 0, 1, 0,
            ]), child: Image.asset('assets/images/earth.png', fit: BoxFit.cover)),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.bottomLeft, end: Alignment.topRight,
              colors: [Color(0xD903171F), Color(0x2003171F), Color(0x40FFB46D)],
              stops: [0, .57, 1]))),
            DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFCA8C).withValues(alpha: .7), width: 1.3))),
          ]))),
        Positioned(left: w * .59, top: h * .32,
          child: IgnorePointer(child: Container(width: w * .09, height: w * .09,
            decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0xCCFFE9BC), Color(0x77FFB865), Color(0x00FFB865)]))))),
        for (var i = 0; i < angles.length; i++)
          Positioned(left: w / 2 + math.cos(angles[i]) * w * .42 - nodeSize / 2,
            top: h / 2 + math.sin(angles[i]) * h * .37 - nodeSize / 2,
            child: _OrbitNode(index: i, state: i < states.length ? states[i] : OrbitStage.future,
              size: nodeSize, onTap: () => onNode(i))),
      ]);
    }));
}

class _OrbitNode extends StatelessWidget {
  final int index;
  final OrbitStage state;
  final double size;
  final VoidCallback onTap;
  const _OrbitNode({required this.index, required this.state, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = state == OrbitStage.done ? teal : state == OrbitStage.current ? violet : muted;
    final active = state == OrbitStage.done || state == OrbitStage.current;
    final label = switch (state) { OrbitStage.done => 'действие выполнено',
      OrbitStage.current => 'текущий', OrbitStage.recorded => 'результат записан', OrbitStage.future => 'будущий' };
    return Semantics(label: 'Этап ${index + 1}: $label', button: true,
      child: Tooltip(message: 'Этап ${index + 1}: $label',
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(size),
          child: Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [active ? color.withValues(alpha: .18) : panel, ink]),
              border: Border.all(color: color, width: active ? 2.5 : 1.6),
              boxShadow: [if (active) ...[
                BoxShadow(color: color.withValues(alpha: .55), blurRadius: 11, spreadRadius: 1),
                BoxShadow(color: color.withValues(alpha: .16), blurRadius: 22, spreadRadius: 4),
              ]]),
            child: state == OrbitStage.future ? null : Icon(
              state == OrbitStage.done ? Icons.check : state == OrbitStage.current ? Icons.circle : Icons.remove,
              color: state == OrbitStage.done ? Colors.white : color,
              size: state == OrbitStage.current ? size * .22 : size * .52)))));
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final random = math.Random(41);
    for (var i = 0; i < 140; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * .7 + .15,
        Paint()..color = const Color(0xFF8EACBA).withValues(alpha: random.nextDouble() * .3));
    }
    canvas.drawCircle(c, size.width * .32, Paint()
      ..shader = const RadialGradient(colors: [Color(0x221B5868), Color(0x001B5868)])
        .createShader(Rect.fromCircle(center: c, radius: size.width * .32)));
    for (var i = 0; i < 5; i++) {
      canvas.save(); canvas.translate(c.dx, c.dy); canvas.rotate((i - 2) * .13);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero,
        width: size.width * (.42 + i * .12), height: size.height * (.36 + i * .13)),
        Paint()..color = const Color(0xFF24728E).withValues(alpha: .14 + i * .025)
          ..style = PaintingStyle.stroke..strokeWidth = .7);
      canvas.restore();
    }
    final orbit = Rect.fromCenter(center: c, width: size.width * .84, height: size.height * .74);
    final shader = const SweepGradient(colors: [Color(0xFF917C5E), Color(0xFFEEC471),
      Color(0xFFB4A36D), Color(0xFFCC9A54), Color(0xFFB56ECD), Color(0xFF917C5E)])
      .createShader(orbit);
    canvas.drawOval(orbit, Paint()..shader = shader..style = PaintingStyle.stroke
      ..strokeWidth = 5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawOval(orbit, Paint()..shader = shader..style = PaintingStyle.stroke..strokeWidth = 1.35);
    for (final angle in [-math.pi / 2, math.pi / 2]) {
      final p = Offset(c.dx + math.cos(angle) * orbit.width / 2, c.dy + math.sin(angle) * orbit.height / 2);
      canvas.drawCircle(p, 4, Paint()..color = const Color(0x55FFD38A)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(p, 1.8, Paint()..color = const Color(0xFFFFD38A));
    }
  }
  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}

Widget gap([double h = 16]) => SizedBox(height: h);
Widget arrowRow(
  IconData icon,
  String title,
  VoidCallback onTap, {
  String? subtitle,
}) => GlassPanel(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  onTap: onTap,
  child: Row(
    children: [
      Icon(icon, color: Colors.white),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right, color: muted),
    ],
  ),
);
