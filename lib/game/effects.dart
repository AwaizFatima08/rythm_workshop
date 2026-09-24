import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../theme.dart';

Path starPath(Offset c, double rOut, double rIn) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? rOut : rIn;
    final a = -pi / 2 + i * pi / 5;
    final pt = c + Offset(cos(a) * r, sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Gold sparkles for an on-beat bonus: one soft burst, no flashing.
class SparkleBurst extends PositionComponent {
  SparkleBurst({required Vector2 position, required this.radius})
      : super(position: position, anchor: Anchor.center, priority: 25);

  final double radius;
  double _t = 0;
  static const _life = 0.7;
  final _rand = Random();
  late final List<(double angle, double speed, double size)> _bits = [
    for (var i = 0; i < 10; i++) (i * 2 * pi / 10 + _rand.nextDouble() * 0.4, 0.6 + _rand.nextDouble() * 0.5, 0.5 + _rand.nextDouble() * 0.5),
  ];

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final fill = Paint()..color = Palette.yellow.withValues(alpha: 1 - k);
    final line = Paint()
      ..color = Palette.walnut.withValues(alpha: (1 - k) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final (angle, speed, size) in _bits) {
      final d = radius * speed * Curves.easeOut.transform(k);
      final c = Offset(cos(angle) * d, sin(angle) * d);
      final s = radius * 0.16 * size * (1 - k * 0.5);
      final path = starPath(c, s, s * 0.45);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
  }
}

/// Three stars at the top right that fill as the level progresses (no numbers).
class StarMeter extends PositionComponent {
  StarMeter({required Rect rect})
      : super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height), priority: 10);

  int filled = 0;
  final _pop = [0.0, 0.0, 0.0];

  void setFilled(int n) {
    for (var i = filled; i < n && i < 3; i++) {
      _pop[i] = 1;
    }
    filled = n.clamp(0, 3);
  }

  @override
  void update(double dt) {
    for (var i = 0; i < 3; i++) {
      _pop[i] = max(0, _pop[i] - dt * 2.5);
    }
  }

  @override
  void render(Canvas canvas) {
    final r = min(size.y * 0.5, size.x / 6.6);
    for (var i = 0; i < 3; i++) {
      final c = Offset(size.x - r * 1.1 - i * r * 2.2, size.y / 2);
      final grow = 1 + 0.35 * sin(_pop[2 - i] * pi);
      final on = (2 - i) < filled;
      final path = starPath(c, r * grow, r * 0.48 * grow);
      canvas.drawPath(path, Paint()..color = on ? Palette.yellow : const Color(0x55FFFFFF));
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.walnut
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }
}

/// Small wobble used when a toy lands on the belt again.
Effect wobble() => SequenceEffect([
      RotateEffect.to(0.12, EffectController(duration: 0.1)),
      RotateEffect.to(-0.08, EffectController(duration: 0.1)),
      RotateEffect.to(0, EffectController(duration: 0.1)),
    ]);
