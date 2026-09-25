import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rhythm_workshop/app.dart';
import 'package:rhythm_workshop/audio/audio_engine.dart';
import 'package:rhythm_workshop/game/rules.dart';
import 'package:rhythm_workshop/game/toy.dart';
import 'package:rhythm_workshop/game/workshop_game.dart';
import 'package:rhythm_workshop/screens/gameplay_screen.dart';
import 'package:rhythm_workshop/screens/home_screen.dart';
import 'package:rhythm_workshop/screens/level_picker_screen.dart';
import 'package:rhythm_workshop/screens/parent_settings_screen.dart';
import 'package:rhythm_workshop/screens/reward_screen.dart';
import 'package:rhythm_workshop/settings/game_settings.dart';
import 'package:rhythm_workshop/widgets/buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end on a real device/emulator with the real audio engine (flutter_soloud).
/// Run: `flutter test integration_test/app_test.dart -d emulator-5590`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Real-time wait while frames keep rendering.
  Future<void> wait(WidgetTester tester, double seconds) async {
    final end = DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> waitFor(WidgetTester tester, Finder f, {double timeout = 20}) async {
    final end = DateTime.now().add(Duration(milliseconds: (timeout * 1000).round()));
    while (f.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        final screens = find
            .byWidgetPredicate((w) => w.runtimeType.toString().endsWith('Screen'))
            .evaluate()
            .map((e) => e.widget.runtimeType)
            .toList();
        fail('timed out waiting for $f; screens now: $screens');
      }
      await wait(tester, 0.1);
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await waitFor(tester, find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await wait(tester, 0.8);
  }

  /// Drags one toy to the right target with real pointer events. Returns false if none was ready.
  Future<bool> sortOne(WidgetTester tester, WorkshopGame game, Size screen) async {
    final ready = game.toys
        .where((t) =>
            t.state == ToyState.onBelt &&
            t.x > 80 &&
            t.x < screen.width - 120 &&
            game.rules.correctTargetFor(t.item) != null)
        .toList();
    if (ready.isEmpty) return false;
    final toy = ready.first;
    final target = game.targets.firstWhere((t) => t.targetId == game.rules.correctTargetFor(toy.item)).rect.center;
    final g = await tester.startGesture(Offset(toy.x, toy.y));
    await wait(tester, 0.05);
    final from = Offset(toy.x, toy.y);
    for (var i = 1; i <= 8; i++) {
      await g.moveTo(Offset.lerp(from, target, i / 8)!);
      await wait(tester, 0.02);
    }
    await g.up();
    await wait(tester, 0.2);
    return true;
  }

  Future<void> playToEnd(WidgetTester tester, WorkshopGame game) async {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final start = DateTime.now();
    while (!game.rules.complete) {
      expect(DateTime.now().difference(start).inSeconds, lessThan(150), reason: 'level took too long');
      if (!await sortOne(tester, game, screen)) await wait(tester, 0.1);
    }
  }

  testWidgets('full journey on device with real audio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await GameSettings.load();
    final audio = SoloudAudioEngine(settings);
    final services = AppServices(settings: settings, audio: audio);
    await tester.pumpWidget(RhythmWorkshopApp(services: services));

    // Splash loads sounds and levels, then Home.
    await waitFor(tester, find.byType(HomeScreen), timeout: 30);
    expect(audio.isReady, isTrue, reason: 'flutter_soloud initialised and effects loaded');
    expect(services.levels.all, hasLength(12));

    await tapKey(tester, 'play');
    await tapKey(tester, 'world-1');
    await tapKey(tester, 'level-colour_01');
    await waitFor(tester, find.byType(GameplayScreen));
    await wait(tester, 1.5);
    final game = WorkshopGame.current!;

    // Beat clock: the music position advances with real time and does not drift.
    final m0 = audio.musicMs();
    final w = Stopwatch()..start();
    await wait(tester, 8);
    final dMusic = audio.musicMs() - m0;
    final dWall = w.elapsedMilliseconds.toDouble();
    debugPrint('beat clock: music ${dMusic.toStringAsFixed(0)} ms vs wall ${dWall.toStringAsFixed(0)} ms');
    // Emulators without a host sound device drain audio slowly and unevenly (70-97%
    // of real time measured here); the game follows the music clock, so sound and
    // visuals stay locked either way. Real phones must be within 1.5%.
    // On a phone, pass --dart-define=RW_REAL_DEVICE=true for the strict check.
    const realDevice = bool.fromEnvironment('RW_REAL_DEVICE');
    expect(dMusic, greaterThan(dWall * (realDevice ? 0.985 : 0.5)), reason: 'music clock advances');
    if (realDevice) expect(dMusic, lessThan(dWall * 1.015));
    // Beats seen by the game match the music position exactly (no separate timer).
    final beatsFromMusic = (audio.musicMs() / game.clock.beatMs).floor();
    expect(game.debugRawBeatsSeen, inInclusiveRange(beatsFromMusic, beatsFromMusic + 2));

    // Play level 1 to the end with real drags.
    await playToEnd(tester, game);
    expect(game.rules.songNotes, hasLength(game.level.itemCount));
    await waitFor(tester, find.byType(RewardScreen));
    expect(settings.stars('colour_01'), 3);
    await waitFor(tester, find.byKey(const ValueKey('next')), timeout: 20);

    // Next goes straight into level 2.
    await tapKey(tester, 'next');
    await waitFor(tester, find.byType(GameplayScreen));
    await wait(tester, 1.5);
    final game2 = WorkshopGame.current!;
    expect(game2.level.id, 'colour_02');

    // Going to the background pauses play and freezes the music clock. While
    // paused Flutter renders no frames, so wait in real time without pumping.
    for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final frozen = audio.musicMs();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(audio.musicMs(), closeTo(frozen, 30), reason: 'music paused in background');
    for (final st in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await wait(tester, 0.5);
    expect(find.byKey(const ValueKey('pause-resume')), findsOneWidget, reason: 'comes back to the pause menu');
    await tapKey(tester, 'pause-resume');
    await wait(tester, 1);
    expect(audio.musicMs(), greaterThan(frozen + 300), reason: 'music resumes');

    // Hold-to-pause (1 s), then leave the level.
    final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pause'))));
    await wait(tester, 1.3);
    await g.up();
    await wait(tester, 0.3);
    await tapKey(tester, 'pause-home');
    await waitFor(tester, find.byType(LevelPickerScreen));
    expect(find.byType(LevelCard), findsNWidgets(3));

    // Pattern level (world 4, level 12).
    await tester.tap(find.byType(BackArrowButton)); // the app's own 64 dp back arrow
    await wait(tester, 0.8);
    await tapKey(tester, 'world-4');
    await tapKey(tester, 'level-pattern_01');
    await waitFor(tester, find.byType(GameplayScreen));
    await wait(tester, 1.5);
    final game3 = WorkshopGame.current!;
    expect(game3.level.isPattern, isTrue);
    await playToEnd(tester, game3);
    expect(game3.rules.patternPlaced.take(6), ['fruit', 'veg', 'fruit', 'veg', 'fruit', 'veg']);
    await waitFor(tester, find.byType(RewardScreen));
    expect(settings.stars('pattern_01'), 3);
    expect(game3.rules.correctTargetFor(game3.level.items.first), anyOf(isNull, shelfId));
  });

  testWidgets('settings through the parental gate; Urdu voice plays', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await GameSettings.load();
    final audio = SoloudAudioEngine(settings);
    await tester.pumpWidget(RhythmWorkshopApp(services: AppServices(settings: settings, audio: audio)));
    await waitFor(tester, find.byType(HomeScreen), timeout: 30);
    await tester.longPress(find.byKey(const ValueKey('settings-gear')));
    await wait(tester, 0.8);
    final text = tester.widget<Text>(find.byKey(const ValueKey('gate-problem'))).data!;
    final m = RegExp(r'(\d) × (\d)').firstMatch(text)!;
    for (final d in '${int.parse(m[1]!) * int.parse(m[2]!)}'.split('')) {
      await tester.tap(find.byKey(ValueKey('gate-key-$d')));
      await wait(tester, 0.2);
    }
    await waitFor(tester, find.byType(ParentSettingsScreen));
    await tester.tap(find.textContaining('Urdu'));
    await wait(tester, 1.5);
    expect(settings.language, VoiceLanguage.ur);
    // Every Urdu and English voice file loads in the real engine.
    for (final id in ['vo_welcome', 'vo_prompt_colour', 'vo_prompt_size', 'vo_prompt_shape', 'vo_prompt_food',
      'vo_prompt_pattern', 'vo_try_here', 'vo_praise_01', 'vo_praise_02', 'vo_goodnight']) {
      await audio.playVoice(id);
    }
    settings.language = VoiceLanguage.en;
    await audio.playVoice('vo_welcome');
    await wait(tester, 0.5);
    expect(audio.isReady, isTrue);
    for (var i = 0; i < 6; i++) {
      audio.playChime(i);
    }
    await audio.startMusic('bgm_goodnight.ogg', loop: false);
    await wait(tester, 1);
    expect(audio.musicMs(), greaterThan(500));
    await audio.stopMusic();
  });
}
