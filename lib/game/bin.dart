import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../theme.dart';

/// Anything a toy can be dropped into: a bin or the pattern shelf.
abstract interface class DropTarget {
  String get targetId;
  Rect get rect;
  void glow([double seconds]);
  void bounce();
}

/// A bin. Glows gently to show the child where a toy goes.
class BinComponent extends SpriteComponent implements DropTarget {
  BinComponent({required this.targetId, required Sprite sprite, required Rect rect})
      : super(
          sprite: sprite,
          position: Vector2(rect.center.dx, rect.bottom),
          size: Vector2(rect.width, rect.height),
          anchor: Anchor.bottomCenter,
          priority: 2,
        );

  @override
  final String targetId;
  double _glow = 0;
  double _t = 0;

  @override
  Rect get rect => Rect.fromLTWH(position.x - size.x / 2, position.y - size.y, size.x, size.y);

  /// Soft pulsing halo for [seconds] (slow: well under 3 flashes per second).
  @override
  void glow([double seconds = 2]) => _glow = max(_glow, seconds);

  @override
  void bounce() {
    add(SequenceEffect([
      ScaleEffect.to(Vector2(1.06, 0.94), EffectController(duration: 0.08)),
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.25, curve: Curves.elasticOut)),
    ]));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_glow > 0) _glow = max(0, _glow - dt);
  }

  @override
  void render(Canvas canvas) {
    if (_glow > 0) {
      final a = (0.35 + 0.25 * sin(_t * 2 * pi * 1.2)) * min(1, _glow);
      final halo = Paint()
        ..color = Palette.yellow.withValues(alpha: a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-10, -10, size.x + 20, size.y + 20), const Radius.circular(24)),
        halo,
      );
    }
    super.render(canvas);
  }
}
