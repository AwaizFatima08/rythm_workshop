import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/game/effects.dart';
import 'package:rhythm_workshop/game/rules.dart';
import 'package:rhythm_workshop/game/toy.dart';
import 'package:rhythm_workshop/game/workshop_game.dart';
import 'package:rhythm_workshop/levels/level.dart';
import 'package:rhythm_workshop/settings/game_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Hosts one level in a real GameWidget (800 x 360 dp phone) with a music
/// clock the test controls, so beats and timing are exact.
class Harness {
  Harness(this.tester, this.level);

  final WidgetTester tester;
  final Level level;
  final audio = ManualClockAudio();
  late WorkshopGame game;
  LevelResult? result;

  Future<void> start({int seed = 1, Size size = const Size(800, 360)}) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await GameSettings.load();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    game = WorkshopGame(
      level: level,
      audio: audio,
      settings: settings,
      random: Random(seed),
      onComplete: (r) => result = r,
    );
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    // Images decode on real async time: alternate short real waits with frames.
    for (var i = 0; i < 100 && !game.isLoaded; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    expect(game.isLoaded, isTrue, reason: 'game failed to load');
  }

  /// Unmounts the game and lets its short intro/finish timers run out.
  Future<void> end() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  /// Advances game frames and the music clock together.
  Future<void> run(double seconds, {double frame = 1 / 60}) async {
    for (var t = 0.0; t < seconds; t += frame) {
      audio.t += frame * 1000;
      await tester.pump(Duration(microseconds: (frame * 1e6).round()));
    }
  }

  List<Toy> get onBelt => game.toys.where((t) => t.state == ToyState.onBelt && t.x > 60 && t.x < 740).toList();

  /// Waits until a toy is fully on screen and returns it.
  Future<Toy> waitForToy({bool Function(Toy)? where}) async {
    for (var i = 0; i < 1200; i++) {
      final ok = onBelt.where(where ?? (_) => true).toList();
      if (ok.isNotEmpty) return ok.first;
      await run(1 / 60);
    }
    fail('no toy arrived');
  }

  Offset targetCenter(String id) => game.targets.firstWhere((t) => t.targetId == id).rect.center;

  /// Drags [toy] to [to] with one finger, frame by frame.
  Future<void> drag(Toy toy, Offset to, {int pointer = 1}) async {
    final g = await tester.startGesture(Offset(toy.x, toy.y), pointer: pointer);
    await run(0.05);
    final from = Offset(toy.x, toy.y);
    for (var i = 1; i <= 10; i++) {
      await g.moveTo(Offset.lerp(from, to, i / 10)!);
      await run(1 / 60);
    }
    await g.up();
    await run(0.05);
  }

  String wrongBinFor(ItemDef item) => level.bins.firstWhere((b) => b.id != item.bin).id;
}

void main() {
  testWidgets('toys arrive on the beat, ride left to right and loop round', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    expect(h.audio.log, contains('music:bgm_calm.ogg'));
    expect(h.audio.log, contains('voice:vo_prompt_colour'));
    expect(h.game.toys, isEmpty);
    await h.run(4 * 60 / 70 + 0.05); // 4 beats at 70 BPM
    expect(h.game.toys, hasLength(1), reason: 'first toy enters on beat 4');
    expect(h.audio.log.where((e) => e.startsWith('tap')), isNotEmpty, reason: 'practice level taps the beat');
    final toy = h.game.toys.first;
    final x0 = toy.x;
    await h.run(1);
    expect(toy.x, greaterThan(x0 + 50), reason: 'belt moves toys right');
    // Untouched toys never leave: they wrap back to the left.
    await h.run(14);
    expect(h.game.toys.every((t) => t.isMounted && t.x < 800 + t.size.x), isTrue);
    expect(h.game.rules.sorted, 0);
    await h.end();
  });

  testWidgets('right bin: counts, chime waits for the next beat, stars fill', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    // Move the clock to just off-beat so the chime must be quantised.
    h.audio.t = (h.audio.t ~/ (60000 / 70)) * (60000 / 70) + 400;
    await h.drag(toy, h.targetCenter(toy.item.bin));
    expect(h.game.rules.sorted, 1);
    expect(toy.state, ToyState.sorted);
    expect(h.audio.log, contains('pickup'));
    // Released ~0.6 beat after a beat: no bonus, and the chime waits (<= 1 beat).
    final chime = h.audio.log.firstWhere((e) => e.startsWith('chime:'));
    expect(chime, startsWith('chime:0@'));
    expect(int.parse(chime.split('@').last), inInclusiveRange(1, 857));
    await h.run(1);
    expect(toy.isMounted, isFalse, reason: 'sorted toy disappears into the bin');
    await h.end();
  });

  testWidgets('on-beat drop: immediate bright chime and sparkles', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    final g = await tester.startGesture(Offset(toy.x, toy.y));
    await h.run(0.05);
    final to = h.targetCenter(toy.item.bin);
    await g.moveTo(to);
    await h.run(0.05);
    const beat = 60000 / 70;
    h.audio.t = (h.audio.t / beat).ceil() * beat + 30; // 30 ms after a beat
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.audio.log.lastWhere((e) => e.startsWith('chime:')), 'chime:0:bright');
    expect(h.game.children.whereType<SparkleBurst>(), isNotEmpty);
    await h.run(1);
    await h.end();
  });

  testWidgets('wrong bin: soft note, toy floats back, no progress lost', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    await h.drag(toy, h.targetCenter(h.wrongBinFor(toy.item)));
    expect(h.audio.log, contains('soft'));
    expect(h.game.rules.sorted, 0);
    await h.run(0.7);
    expect(toy.state, ToyState.onBelt);
    expect(toy.y, closeTo(h.game.layout.beltCenterY, 1));
    // A second wrong try with the same toy brings the "try this one" voice.
    await h.drag(toy, h.targetCenter(h.wrongBinFor(toy.item)));
    expect(h.audio.log, contains('voice:vo_try_here'));
    await h.end();
  });

  testWidgets('dropped on empty space: glides back to the belt, silently', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    await h.drag(toy, Offset(toy.x + 120, toy.y + 30)); // let go on the belt
    expect(h.audio.log, contains('whoosh'));
    expect(h.audio.log, isNot(contains('soft')));
    await h.run(0.5);
    expect(toy.state, ToyState.onBelt);
    expect(h.game.toys, contains(toy));
    await h.end();
  });

  testWidgets('a second finger cannot grab while one toy is being dragged', (tester) async {
    final h = Harness(tester, loadLevel('colour_02'));
    await h.start(seed: 4);
    await h.waitForToy();
    await h.run(4 * 0.75 * 2); // let a second toy arrive
    final toys = h.onBelt;
    expect(toys.length, greaterThanOrEqualTo(2));
    final a = toys[0], b = toys[1];
    final g1 = await tester.startGesture(Offset(a.x, a.y), pointer: 1);
    await h.run(0.05);
    await g1.moveBy(const Offset(0, 30));
    await h.run(0.05);
    expect(a.state, ToyState.dragging);
    final g2 = await tester.startGesture(Offset(b.x, b.y), pointer: 2);
    await h.run(0.05);
    await g2.moveBy(const Offset(0, 60));
    await h.run(0.05);
    expect(b.state, isNot(ToyState.dragging), reason: 'second touch ignored');
    await g2.up();
    await g1.up();
    await h.run(0.6);
    expect(a.state, ToyState.onBelt);
    await h.end();
  });

  testWidgets('grab area is 24 dp bigger than the picture', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    final edge = Offset(toy.x + toy.size.x / 2 + 20, toy.y); // outside the art, inside the margin
    final g = await tester.startGesture(edge);
    await h.run(0.05);
    await g.moveBy(const Offset(0, 40));
    await h.run(0.05);
    expect(toy.state, ToyState.dragging);
    await g.up();
    await h.run(0.5);
    await h.end();
  });

  for (final id in ['colour_03', 'size_01', 'shape_02', 'food_02', 'pattern_01']) {
    testWidgets('$id can be finished by sorting every toy; reward result has the song', (tester) async {
      final h = Harness(tester, loadLevel(id));
      await h.start(seed: 7, size: const Size(915, 412));
      var guard = 0;
      while (!h.game.rules.complete) {
        expect(++guard, lessThan(60), reason: 'level did not finish');
        final toy = await h.waitForToy(
            where: (t) => h.game.rules.correctTargetFor(t.item) != null);
        await h.drag(toy, h.targetCenter(h.game.rules.correctTargetFor(toy.item)!));
      }
      expect(h.game.rules.sorted, h.level.itemCount);
      expect(h.game.starMeter.filled, 3);
      await h.run(3);
      expect(h.audio.log, contains('fill'));
      expect(h.result, isNotNull);
      expect(h.result!.notes, hasLength(h.level.itemCount));
      if (h.level.isPattern) {
        expect(h.game.rules.patternPlaced.take(4), ['fruit', 'veg', 'fruit', 'veg']);
      }
      await h.end();
    });
  }

  testWidgets('pausing stops the belt and the music clock', (tester) async {
    final h = Harness(tester, loadLevel('colour_01'));
    await h.start();
    final toy = await h.waitForToy();
    h.game.setPaused(true);
    final x = toy.x;
    await tester.pump(const Duration(seconds: 1));
    expect(toy.x, x);
    expect(h.audio.paused, isTrue);
    h.game.setPaused(false);
    await h.run(0.5);
    expect(toy.x, greaterThan(x));
    await h.end();
  });

  testWidgets('pattern shelf rejects the wrong kind', (tester) async {
    final h = Harness(tester, loadLevel('pattern_01'));
    await h.start(seed: 2);
    final wrong = await h.waitForToy(where: (t) => t.item.bin != h.game.rules.expectedPatternBin);
    await h.drag(wrong, h.targetCenter(shelfId));
    expect(h.audio.log, contains('soft'));
    expect(h.game.rules.sorted, 0);
    await h.run(1);
    await h.end();
  });
}
