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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? panel : teal,
        foregroundColor: secondary ? Colors.white : ink,
        minimumSize: const Size(0, 54),
        side: secondary ? const BorderSide(color: Color(0xFF20505D)) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
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

class LeiaLine extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const LeiaLine(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: violet.withValues(alpha: .13),
              border: Border.all(color: violet.withValues(alpha: .65)),
            ),
            child: const Icon(Icons.graphic_eq, color: violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
          const Icon(Icons.chevron_right, color: muted, size: 18),
        ],
      ),
    ),
  );
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

class OrbitMap extends StatelessWidget {
  final int completed;
  final int total;
  final void Function(int) onNode;
  const OrbitMap({
    super.key,
    required this.completed,
    required this.total,
    required this.onNode,
  });
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth;
        final angles = [-2.8, -2.0, -.85, 0.15, 1.0, 2.1];
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _OrbitPainter())),
            Container(
              width: s * .36,
              height: s * .36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB7874E).withValues(alpha: .25),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/earth.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(.5, -.5),
                        colors: [
                          Color(0xFFFFD1A0),
                          Color(0xFF3187A2),
                          Color(0xFF0C374F),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.public, size: 90, color: muted),
                  ),
                ),
              ),
            ),
            for (int i = 0; i < angles.length; i++)
              Positioned(
                left: s / 2 + math.cos(angles[i]) * s * .4 - 21,
                top: s / 2 + math.sin(angles[i]) * s * .34 - 21,
                child: Semantics(
                  label:
                      'Этап ${i + 1}: ${i < completed
                          ? 'завершён'
                          : i == completed
                          ? 'текущий'
                          : 'будущий'}',
                  button: true,
                  child: InkWell(
                    onTap: () => onNode(i),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ink,
                        border: Border.all(
                          color: i < completed
                              ? teal
                              : i == completed
                              ? violet
                              : muted,
                          width: 2,
                        ),
                        boxShadow: [
                          if (i <= completed)
                            BoxShadow(
                              color: (i < completed ? teal : violet).withValues(
                                alpha: .5,
                              ),
                              blurRadius: 16,
                            ),
                        ],
                      ),
                      child: Icon(
                        i < completed
                            ? Icons.check
                            : i == completed
                            ? Icons.near_me_outlined
                            : Icons.circle_outlined,
                        color: i < completed
                            ? teal
                            : i == completed
                            ? violet
                            : muted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i - 1) * .22);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * (.6 + i * .1),
          height: size.height * (.54 + i * .08),
        ),
        Paint()
          ..color = (i == 3 ? const Color(0xFFDAAE64) : const Color(0xFF237B92))
              .withValues(alpha: i == 3 ? 0.55 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 3 ? 1.2 : .8,
      );
      canvas.restore();
    }
    final random = math.Random(41);
    for (int i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * .8 + .2,
        Paint()..color = muted.withValues(alpha: random.nextDouble() * .5),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
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
