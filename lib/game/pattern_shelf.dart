import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../theme.dart';
import 'bin.dart';
import 'rules.dart';

/// Pattern level target: a shelf showing fruit, veg, fruit ... with the next
/// empty slot glowing. It accepts only the toy that continues the pattern.
class PatternShelf extends PositionComponent implements DropTarget {
  PatternShelf({required Rect rect, required this.sprites, required List<String> startBins})
      : _placed = [for (final b in startBins) sprites[b]!],
        super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height), priority: 2);

  static const slots = 6;

  /// One representative picture per bin id, used for the starting pattern.
  final Map<String, Sprite> sprites;
  final List<Sprite> _placed;
  double _glow = 0;
  double _t = 0;

  @override
  String get targetId => shelfId;

  @override
  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  double get _slotW => size.x / slots;

  /// Centre of the next empty slot, where a correct toy snaps to.
  Vector2 get nextSlotCenter {
    final i = min(_placed.length, slots - 1);
    return position + Vector2(_slotW * (i + 0.5), size.y * 0.52);
  }

  void place(Sprite sprite) {
    _placed.add(sprite);
    // Keep the newest items visible, leaving the last slot empty for "next".
    while (_placed.length > slots - 1) {
      _placed.removeAt(0);
    }
  }

  @override
  void glow([double seconds = 2]) => _glow = max(_glow, seconds);

  @override
  void bounce() => add(SequenceEffect([
        ScaleEffect.to(Vector2(1.02, 0.97), EffectController(duration: 0.08)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.25, curve: Curves.elasticOut)),
      ]));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_glow > 0) _glow = max(0, _glow - dt);
  }

  @override
  void render(Canvas canvas) {
    final outline = Paint()
      ..color = Palette.walnut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final board = Rect.fromLTWH(0, size.y * 0.78, size.x, size.y * 0.16);
    final back = RRect.fromRectAndRadius(Rect.fromLTWH(4, 0, size.x - 8, size.y * 0.8), const Radius.circular(18));
    canvas.drawRRect(back, Paint()..color = const Color(0xFFFBE3BC));
    canvas.drawRRect(back, outline);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(8)), Paint()..color = Palette.wood);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(8)), outline);

    final item = min(_slotW * 0.86, size.y * 0.66);
    for (var i = 0; i < _placed.length; i++) {
      final c = Offset(_slotW * (i + 0.5), size.y * 0.45);
      _placed[i].render(canvas,
          position: Vector2(c.dx - item / 2, c.dy - item / 2), size: Vector2.all(item));
    }
    // The next slot: a softly pulsing dashed ring.
    final i = min(_placed.length, slots - 1);
    final c = Offset(_slotW * (i + 0.5), size.y * 0.45);
    final pulse = 0.5 + 0.5 * sin(_t * 2 * pi * 0.9);
    final ring = Paint()
      ..color = Palette.amber.withValues(alpha: 0.55 + 0.45 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final r = item * (0.44 + 0.03 * pulse);
    for (var a = 0.0; a < 2 * pi; a += pi / 8) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, pi / 13, false, ring);
    }
    if (_glow > 0) {
      canvas.drawCircle(
        c,
        r * 1.2,
        Paint()
          ..color = Palette.yellow.withValues(alpha: 0.4 * min(1, _glow))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }
}
