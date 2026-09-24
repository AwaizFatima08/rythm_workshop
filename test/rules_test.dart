import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/game/rules.dart';
import 'package:rhythm_workshop/levels/level.dart';

import 'test_helpers.dart';

void main() {
  final levels = loadAllLevels();

  List<ItemDef> drain(SortingRules r) => [for (ItemDef? i; (i = r.takeNext()) != null;) i!];

  group('item queue', () {
    for (final level in levels.where((l) => !l.isPattern)) {
      test('${level.id}: right count, balanced bins, never 3 of a bin in a row', () {
        for (var seed = 0; seed < 50; seed++) {
          final items = drain(SortingRules(level, random: Random(seed)));
          expect(items, hasLength(level.itemCount));
          final counts = <String, int>{};
          for (final i in items) {
            counts[i.bin] = (counts[i.bin] ?? 0) + 1;
          }
          expect(counts.keys.toSet(), {for (final b in level.bins) b.id});
          final vals = counts.values.toList()..sort();
          expect(vals.last - vals.first, lessThanOrEqualTo(1));
          for (var k = 2; k < items.length; k++) {
            expect(items[k].bin == items[k - 1].bin && items[k].bin == items[k - 2].bin, isFalse);
          }
          for (var k = 1; k < items.length; k++) {
            expect(items[k].id, isNot(items[k - 1].id), reason: 'same picture twice in a row');
          }
        }
      });
    }
  });

  group('judging drops', () {
    final level = loadLevel('colour_01');
    final red = level.items.firstWhere((i) => i.bin == 'red');

    test('right bin correct, other bin wrong, empty space nowhere', () {
      final r = SortingRules(level, random: Random(1));
      expect(r.judge(red, 'red'), DropResult.correct);
      expect(r.judge(red, 'blue'), DropResult.wrong);
      expect(r.judge(red, null), DropResult.nowhere);
    });

    test('streak climbs the pentatonic scale and wraps; song records notes', () {
      final r = SortingRules(level, random: Random(1));
      final notes = [for (var i = 0; i < 8; i++) r.recordCorrect(red)];
      expect(notes, [0, 1, 2, 3, 4, 5, 0, 1]);
      expect(r.songNotes, notes);
      r.recordWrong();
      expect(r.recordCorrect(red), 0, reason: 'a wrong drop restarts the climb');
    });

    test('belt speeds up after 5 in a row (max +30%) and resets after 2 wrong', () {
      final r = SortingRules(level, random: Random(1));
      for (var i = 0; i < 4; i++) {
        r.recordCorrect(red);
      }
      expect(r.speedFactor, 1);
      r.recordCorrect(red);
      expect(r.speedFactor, closeTo(1.1, 1e-9));
      for (var i = 0; i < 30; i++) {
        r.recordCorrect(red);
      }
      expect(r.speedFactor, closeTo(1.3, 1e-9));
      r.recordWrong();
      expect(r.speedFactor, closeTo(1.3, 1e-9), reason: 'one slip does not slow it');
      r.recordWrong();
      expect(r.speedFactor, 1);
    });

    test('wrong drops never reduce progress; stars fill by thirds', () {
      final r = SortingRules(level, random: Random(1));
      for (var i = 0; i < 20; i++) {
        r.recordWrong();
      }
      expect(r.sorted, 0);
      expect(r.starsFilled, 0);
      final third = (level.itemCount / 3).ceil();
      for (var i = 0; i < third; i++) {
        r.recordCorrect(red);
      }
      expect(r.starsFilled, 1);
      while (!r.complete) {
        r.recordCorrect(red);
      }
      expect(r.starsFilled, 3);
    });
  });

  group('pattern level', () {
    final level = loadLevel('pattern_01');

    test('shelf starts with one A-B and then wants A', () {
      final r = SortingRules(level, random: Random(3));
      expect(r.patternPlaced, ['fruit', 'veg']);
      expect(r.expectedPatternBin, 'fruit');
      final veg = level.items.firstWhere((i) => i.bin == 'veg');
      final fruit = level.items.firstWhere((i) => i.bin == 'fruit');
      expect(r.judge(veg, shelfId), DropResult.wrong);
      expect(r.judge(fruit, shelfId), DropResult.correct);
      expect(r.correctTargetFor(veg), isNull);
      expect(r.correctTargetFor(fruit), shelfId);
      r.recordCorrect(fruit);
      expect(r.expectedPatternBin, 'veg');
    });

    test('never stalls: the needed kind is always on the belt or can spawn', () {
      for (var seed = 0; seed < 200; seed++) {
        final rand = Random(seed);
        final r = SortingRules(level, random: Random(seed));
        final belt = <ItemDef>[];
        var guard = 0;
        while (!r.complete) {
          expect(++guard, lessThan(500), reason: 'stalled with seed $seed');
          final bins = [for (final i in belt) i.bin];
          if (r.canSpawn(belt.length, bins)) {
            belt.add(r.takeNext(activeBins: bins)!);
          }
          expect(belt.length, lessThanOrEqualTo(level.maxOnBelt + 1));
          // The child tries random toys; only the right one is accepted.
          final pick = belt[rand.nextInt(belt.length)];
          if (r.judge(pick, shelfId) == DropResult.correct) {
            r.recordCorrect(pick);
            belt.remove(pick);
          } else {
            r.recordWrong();
          }
          if (!r.complete) {
            final have = belt.any((i) => i.bin == r.expectedPatternBin);
            expect(have || r.canSpawn(belt.length, [for (final i in belt) i.bin]), isTrue,
                reason: 'needed ${r.expectedPatternBin} unreachable (seed $seed)');
          }
        }
        expect(r.remainingToSpawn, 0);
      }
    });
  });

  group('findTarget', () {
    final bins = {'a': const Rect.fromLTWH(0, 200, 200, 160), 'b': const Rect.fromLTWH(300, 200, 200, 160)};

    test('inside a bin', () {
      expect(findTarget(const Rect.fromLTWH(50, 250, 90, 90), bins), 'a');
    });

    test('magnetic 40 dp margin catches near misses', () {
      expect(findTarget(const Rect.fromLTWH(-120, 100, 90, 90), bins), 'a'); // touches inflated zone
      expect(findTarget(const Rect.fromLTWH(-200, 0, 90, 90), bins), isNull);
    });

    test('overlapping two zones: the bigger overlap wins', () {
      expect(findTarget(const Rect.fromLTWH(190, 250, 90, 90), bins), 'a');
      expect(findTarget(const Rect.fromLTWH(230, 250, 90, 90), bins), 'b');
    });
  });
}
