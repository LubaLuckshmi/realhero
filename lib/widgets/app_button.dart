import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool primary;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = primary
        ? const LinearGradient(
            colors: [Color(0xFF7EF091), Color(0xFF2CC796)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          )
        : null;

    final bgColor = primary ? null : const Color(0xFF4565D4);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: bgGradient,
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
        border: primary ? null : Border.all(color: Colors.white, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
