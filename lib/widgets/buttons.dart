import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Round picture button for children: at least 64 dp, squashes when pressed.
class PictureButton extends StatefulWidget {
  const PictureButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 88,
    this.color = Palette.blue,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  State<PictureButton> createState() => _PictureButtonState();
}

class _PictureButtonState extends State<PictureButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = max(kMinTouch, widget.size);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Palette.walnut, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 5), blurRadius: 0)],
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Back arrow, 64 dp, top-left on picker screens.
class BackArrowButton extends StatelessWidget {
  const BackArrowButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PictureButton(
        size: 64,
        color: Palette.cream,
        semanticLabel: 'Back',
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const Icon(Icons.arrow_back_rounded, color: Palette.walnut, size: 40),
      );
}

/// Needs a 1-second press-and-hold (a ring fills) so accidental taps do nothing.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.onHeld,
    required this.child,
    this.size = 64,
    this.hold = const Duration(seconds: 1),
    this.semanticLabel,
  });

  final VoidCallback onHeld;
  final Widget child;
  final double size;
  final Duration hold;
  final String? semanticLabel;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _c.reset();
        widget.onHeld();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_c.status != AnimationStatus.completed) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s = max(kMinTouch, widget.size);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onLongPress: widget.onHeld,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _c.forward(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => CustomPaint(painter: _RingPainter(_c.value), child: child),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = Palette.cream.withValues(alpha: 0.92));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Palette.walnut
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = Palette.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Row of small gold stars (no numbers) showing finished levels.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.count, this.of = 3, this.size = 28});

  final int count;
  final int of;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < of; i++)
            Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < count ? Palette.yellow : Palette.faded,
              shadows: i < count ? const [Shadow(color: Palette.walnut, blurRadius: 1.5)] : null,
            ),
        ],
      );
}
