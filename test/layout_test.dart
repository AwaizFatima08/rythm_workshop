import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/game/layout.dart';

void main() {
  // Landscape logical sizes: small old phone, common phones, tablets.
  const screens = [
    Size(640, 360), Size(732, 412), Size(800, 360), Size(915, 412), Size(960, 540),
    Size(1024, 600), Size(1280, 800), Size(1368, 1024), Size(2000, 1200),
  ];

  for (final s in screens) {
    for (final (bins, pattern) in [(2, false), (3, false), (1, true)]) {
      test('${s.width.toInt()}x${s.height.toInt()} with ${pattern ? 'pattern shelf' : '$bins bins'}', () {
        final l = WorkshopLayout(s, binCount: bins, pattern: pattern);
        final screen = Offset.zero & s;
        // Child minimums.
        expect(l.pauseRect.width, greaterThanOrEqualTo(64));
        expect(l.pauseRect.height, greaterThanOrEqualTo(64));
        expect(l.toySize, greaterThanOrEqualTo(86));
        // Belt in the top part, below the controls bar.
        expect(l.beltRect.top, greaterThanOrEqualTo(l.pauseRect.bottom));
        expect(l.beltRect.center.dy, lessThan(s.height / 2));
        expect(l.targets, hasLength(bins));
        final all = [...l.targets, l.pipRect];
        for (final r in all) {
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue,
              reason: 'off screen: $r');
          expect(r.top, greaterThan(l.beltRect.bottom), reason: 'overlaps belt: $r');
        }
        for (var i = 0; i < all.length; i++) {
          for (var j = i + 1; j < all.length; j++) {
            expect(all[i].overlaps(all[j]), isFalse, reason: '${all[i]} overlaps ${all[j]}');
          }
        }
        for (final t in l.targets) {
          expect(t.width, greaterThanOrEqualTo(64 * 2));
          expect(t.height, greaterThanOrEqualTo(64 * 1.5));
        }
        expect(l.miloRect.overlaps(l.pauseRect), isFalse);
        expect(l.starsRect.overlaps(l.miloRect), isFalse);
      });
    }
  }
}
