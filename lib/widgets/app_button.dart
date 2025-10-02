import 'package:flutter/material.dart';

enum AppButtonKind { green, blue, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.kind = AppButtonKind.green,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onTap;
  final AppButtonKind kind;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = switch (kind) {
      AppButtonKind.green => const LinearGradient(
        colors: [Color(0xFF7EF091), Color(0xFF2CC796)],
        begin: Alignment(0.0, 1.0),
        end: Alignment(1.0, 0.0),
      ),
      AppButtonKind.blue => const LinearGradient(
        colors: [Color(0xFF4666D5), Color(0xFF4666D5)],
      ),
      AppButtonKind.ghost => null,
    };

    final content = Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: enabled ? bg : null,
        color: enabled
            ? (bg == null ? Colors.white.withOpacity(0.18) : null)
            : Colors.white.withOpacity(0.12), // «стекло», когда disabled
        border: kind == AppButtonKind.ghost
            ? Border.all(color: Colors.white.withOpacity(0.45))
            : null,
        boxShadow: bg != null && enabled
            ? [
                BoxShadow(
                  color:
                      (kind == AppButtonKind.green
                              ? const Color(0xFF76ED92)
                              : const Color(0xFF4666D5))
                          .withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16, // компактнее, лучше влезает
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: enabled ? onTap : null,
        child: content,
      ),
    );
  }
}
