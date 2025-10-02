import 'package:flutter/material.dart';

class BackgroundStars extends StatelessWidget {
  const BackgroundStars({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/stars_bg.png', fit: BoxFit.cover),
        ),
        child,
      ],
    );
  }
}
