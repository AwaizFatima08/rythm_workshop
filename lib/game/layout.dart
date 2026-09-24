import 'dart:math';
import 'dart:ui';

/// Where everything sits on the gameplay screen, in logical pixels (dp).
///
/// Rows, top to bottom: controls bar (pause, Milo, stars) - belt - bins.
/// The belt sits in the top third so the child's hand does not cover the bins.
/// Sizes scale with the screen but never drop below the child minimums:
/// 64 dp controls, toys drawn at least ~86 dp with a 24 dp grab margin.
class WorkshopLayout {
  WorkshopLayout(this.size, {required this.binCount, this.pattern = false}) {
    const margin = 12.0;
    scale = min(size.height / 400, size.width / 800).clamp(0.85, 1.8);
    barHeight = max(64.0, 72 * scale);
    pauseRect = Rect.fromLTWH(margin, 8, max(64.0, 64 * scale), max(64.0, 64 * scale));
    toySize = max(86.0, 96 * scale);
    final beltTop = 8 + barHeight + 4;
    beltRect = Rect.fromLTWH(0, beltTop, size.width, toySize + 28 * scale);
    miloRect = Rect.fromCenter(
      center: Offset(size.width / 2, 8 + barHeight / 2 + 2),
      width: barHeight * 1.2,
      height: barHeight * 1.1,
    );
    starsRect = Rect.fromLTWH(size.width - margin - barHeight * 2.2, 8, barHeight * 2.2, barHeight * 0.75);

    // Bottom row: bins and Pip.
    final rowTop = beltRect.bottom + 12 * scale;
    final rowBottom = size.height - 8;
    final available = size.width - 2 * margin;
    var binW = 200 * scale, binH = 160 * scale, gap = 48 * scale, pipW = 110 * scale;
    final needed = pattern
        ? pipW + gap + 520 * scale
        : binCount == 2
            ? 2 * binW + 2 * gap + pipW
            : pipW + gap + binCount * binW + (binCount - 1) * gap;
    final fit = min(1.0, min(available / needed, (rowBottom - rowTop) / binH));
    binW *= fit;
    binH *= fit;
    gap *= fit;
    pipW *= fit;
    final rowY = rowBottom - binH;
    final pipH = pipW * 1.1;

    targets = [];
    if (pattern) {
      final shelfW = min(available - pipW - gap, 620 * scale);
      final left = (size.width - (pipW + gap + shelfW)) / 2;
      pipRect = Rect.fromLTWH(left, rowBottom - pipH, pipW, pipH);
      targets.add(Rect.fromLTWH(left + pipW + gap, rowY, shelfW, binH));
    } else if (binCount == 2) {
      final left = (size.width - (2 * binW + 2 * gap + pipW)) / 2;
      targets.add(Rect.fromLTWH(left, rowY, binW, binH));
      pipRect = Rect.fromLTWH(left + binW + gap, rowBottom - pipH, pipW, pipH);
      targets.add(Rect.fromLTWH(pipRect.right + gap, rowY, binW, binH));
    } else {
      final total = pipW + gap + binCount * binW + (binCount - 1) * gap;
      final left = (size.width - total) / 2;
      pipRect = Rect.fromLTWH(left, rowBottom - pipH, pipW, pipH);
      for (var i = 0; i < binCount; i++) {
        targets.add(Rect.fromLTWH(left + pipW + gap + i * (binW + gap), rowY, binW, binH));
      }
    }
  }

  final Size size;
  final int binCount;
  final bool pattern;
  late final double scale;
  late final double barHeight;
  late final double toySize;
  late final Rect pauseRect;
  late final Rect beltRect;
  late final Rect miloRect;
  late final Rect starsRect;
  late final Rect pipRect;

  /// Bin rectangles (or the one pattern shelf), left to right.
  late final List<Rect> targets;

  double get beltCenterY => beltRect.center.dy - 4 * scale;

  /// Toys wrap from the right edge back to the left over this distance.
  double get beltLoopLength => size.width + toySize;
}
