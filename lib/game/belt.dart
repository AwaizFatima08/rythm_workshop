import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../theme.dart';

/// The conveyor belt: moving chevrons and turning rollers, drawn in code.
class Belt extends PositionComponent {
  Belt({required Rect rect, required this.scaleFactor})
      : super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height), priority: 1);

  final double scaleFactor;

  /// Current speed in dp/s, set by the game each frame.
  double speed = 0;
  double _travel = 0;

  static final _frame = Paint()..color = Palette.woodDark;
  static final _surface = Paint()..color = const Color(0xFF6B5645);
  static final _chevron = Paint()
    ..color = const Color(0xFF8A7360)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _outline = Paint()
    ..color = Palette.walnut
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final _roller = Paint()..color = const Color(0xFFB9A48E);

  @override
  void update(double dt) => _travel += speed * dt;

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;
    final top = h * 0.30, bottom = h * 0.92;
    final surface = Rect.fromLTRB(-10, top, w + 10, bottom);
    canvas.drawRect(Rect.fromLTRB(-10, bottom - 6, w + 10, h), _frame);
    canvas.drawRRect(RRect.fromRectAndRadius(surface, const Radius.circular(10)), _surface);
    // Chevrons show direction (left to right) and speed.
    final gap = 64 * scaleFactor;
    _chevron.strokeWidth = 5 * scaleFactor;
    final offset = _travel % gap;
    final cy = (top + bottom) / 2, ch = (bottom - top) * 0.28;
    for (var x = -gap + offset; x < w + gap; x += gap) {
      canvas.drawPath(
        Path()
          ..moveTo(x - ch * 0.5, cy - ch)
          ..lineTo(x + ch * 0.5, cy)
          ..lineTo(x - ch * 0.5, cy + ch),
        _chevron,
      );
    }
    canvas.drawRRect(RRect.fromRectAndRadius(surface, const Radius.circular(10)), _outline);
    // Rollers turn with the belt.
    final r = (h - bottom) * 0.9 + 6 * scaleFactor;
    final spin = _travel / max(r, 1);
    for (var x = 40 * scaleFactor; x < w; x += 120 * scaleFactor) {
      final c = Offset(x, bottom + 2);
      canvas.drawCircle(c, r, _roller);
      canvas.drawCircle(c, r, _outline);
      canvas.drawLine(c, c + Offset(cos(spin) * r * 0.8, sin(spin) * r * 0.8), _outline);
    }
  }
}
