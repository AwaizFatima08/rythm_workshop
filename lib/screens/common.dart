import 'package:flutter/material.dart';

/// The workshop wall and floor behind every child screen.
class WorkshopBackground extends StatelessWidget {
  const WorkshopBackground({super.key, required this.child, this.dim = 0});

  final Widget child;

  /// 0..1 darkening, used by the goodnight scene.
  final double dim;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/ui/background.png', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
          if (dim > 0) ColoredBox(color: const Color(0xFF1A2340).withValues(alpha: dim)),
          SafeArea(child: child),
        ],
      );
}

/// Character art from assets/images/characters/.
Widget character(String frame, {double? height, bool flip = false}) {
  final img = Image.asset('assets/images/characters/$frame.png', height: height, gaplessPlayback: true);
  return flip ? Transform.flip(flipX: true, child: img) : img;
}
