import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/app.dart';
import 'package:rhythm_workshop/game/workshop_game.dart';
import 'package:rhythm_workshop/screens/gameplay_screen.dart';
import 'package:rhythm_workshop/screens/goodnight_screen.dart';
import 'package:rhythm_workshop/screens/home_screen.dart';
import 'package:rhythm_workshop/screens/level_picker_screen.dart';
import 'package:rhythm_workshop/screens/parent_settings_screen.dart';
import 'package:rhythm_workshop/screens/reward_screen.dart';
import 'package:rhythm_workshop/screens/world_picker_screen.dart';
import 'package:rhythm_workshop/settings/game_settings.dart';
import 'package:rhythm_workshop/widgets/parental_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<AppServices> pumpApp(WidgetTester tester, {Widget home = const HomeScreen(), Size size = const Size(800, 360)}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(settings: await GameSettings.load(), audio: ManualClockAudio());
  await tester.runAsync(services.levels.load);
  await tester.pumpWidget(RhythmWorkshopApp(services: services, home: home));
  await tester.pump();
  return services;
}

/// Lets real-async image decoding finish, then settles animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  for (final size in const [Size(753, 339), Size(1280, 800)]) {
    testWidgets('every child screen lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      final level = loadLevel('colour_03');
      for (final home in <Widget>[
        const HomeScreen(),
        const WorldPickerScreen(),
        const LevelPickerScreen(world: 1),
        const LevelPickerScreen(world: 4),
        RewardScreen(result: LevelResult(level: level, notes: const [0, 1, 2])),
        const ParentSettingsScreen(),
      ]) {
        await pumpApp(tester, home: home, size: size);
        await settle(tester);
        await tester.pump(const Duration(seconds: 5));
        expect(tester.takeException(), isNull, reason: '${home.runtimeType} at $size');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
  }

  testWidgets('home plays the welcome once, then Play → worlds → levels → gameplay', (tester) async {
    final s = await pumpApp(tester);
    await settle(tester);
    final audio = s.audio as ManualClockAudio;
    expect(audio.log.where((e) => e == 'voice:vo_welcome'), hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('play')));
    await settle(tester);
    expect(find.byType(WorldPickerScreen), findsOneWidget);
    for (var w = 1; w <= 4; w++) {
      final box = tester.getSize(find.byKey(ValueKey('world-$w')));
      expect(box.height, greaterThanOrEqualTo(160), reason: 'world cards 160 dp tall');
    }

    await tester.tap(find.byKey(const ValueKey('world-4')));
    await settle(tester);
    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(find.byType(LevelCard), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('level-pattern_01')));
    await settle(tester);
    expect(find.byType(GameplayScreen), findsOneWidget);
    expect(audio.log, contains('music:bgm_workshop_02.ogg'));

    // A quick tap on pause does nothing; a 1-second hold opens the menu.
    await tester.tap(find.byKey(const ValueKey('pause')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('pause-resume')), findsNothing);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('pause'))));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('pause-resume')), findsOneWidget);
    expect(audio.paused, isTrue);

    await tester.tap(find.byKey(const ValueKey('pause-resume')));
    await tester.pump();
    expect(audio.paused, isFalse);

    // Android back opens the pause menu instead of leaving mid-level.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('pause-home')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pause-home')));
    await settle(tester);
    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings: tap on the gear does nothing; long-press + gate opens them', (tester) async {
    final s = await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('settings-gear')));
    await tester.pump();
    expect(find.byType(ParentalGate), findsNothing);
    await tester.longPress(find.byKey(const ValueKey('settings-gear')));
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGate), findsOneWidget);
    final text = tester.widget<Text>(find.byKey(const ValueKey('gate-problem'))).data!;
    final m = RegExp(r'(\d) × (\d)').firstMatch(text)!;
    for (final d in '${int.parse(m[1]!) * int.parse(m[2]!)}'.split('')) {
      await tester.tap(find.byKey(ValueKey('gate-key-$d')));
      await tester.pump();
    }
    await settle(tester);
    expect(find.byType(ParentSettingsScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('calm-mode')), 150);
    await tester.tap(find.byKey(const ValueKey('calm-mode')));
    await tester.pump();
    expect(s.settings.calmMode, isTrue);
    expect(find.byType(ColorFiltered), findsOneWidget, reason: 'calm mode softens colours app-wide');

    await s.settings.setStars('colour_01', 3);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('reset-progress')), 200);
    await tester.tap(find.byKey(const ValueKey('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(s.settings.stars('colour_01'), 0);
    expect(s.settings.calmMode, isTrue);
    await tester.scrollUntilVisible(find.textContaining('collects no personal information'), 200);
    expect(find.textContaining('collects no personal information'), findsOneWidget);
  });

  testWidgets('finished levels show stars on the pickers', (tester) async {
    SharedPreferences.setMockInitialValues({'stars.colour_01': 3, 'stars.colour_02': 3});
    final settings = await GameSettings.load();
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final services = AppServices(settings: settings, audio: ManualClockAudio());
    await tester.runAsync(services.levels.load);
    await tester.pumpWidget(RhythmWorkshopApp(services: services, home: const LevelPickerScreen(world: 1)));
    await settle(tester);
    final done = [for (final c in tester.widgetList<LevelCard>(find.byType(LevelCard))) c.done];
    expect(done, [true, true, false]);
  });

  testWidgets('reward replays the song, then offers again / next and the xylophone', (tester) async {
    final level = loadLevel('colour_01');
    final s = await pumpApp(tester,
        home: RewardScreen(result: LevelResult(level: level, notes: const [0, 1, 2, 3, 4, 5, 0, 1, 2, 3])));
    final audio = s.audio as ManualClockAudio;
    expect(find.byKey(const ValueKey('next')), findsNothing, reason: 'buttons wait for the song');
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(audio.log.where((e) => e.startsWith('chime:')), hasLength(10));
    expect(find.byKey(const ValueKey('again')), findsOneWidget);
    expect(find.byKey(const ValueKey('next')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('xylo-3')));
    expect(audio.log.last, 'chime:3');
    await tester.pump(const Duration(seconds: 21));
    final before = audio.log.length;
    await tester.tap(find.byKey(const ValueKey('xylo-3')), warnIfMissed: false);
    expect(audio.log.length, before, reason: 'xylophone rests after 20 s');

    await tester.tap(find.byKey(const ValueKey('next')));
    await settle(tester);
    expect(find.byType(GameplayScreen), findsOneWidget);
    expect(audio.log, contains('music:bgm_calm.ogg'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('when the session is over, the reward leads to goodnight, then home', (tester) async {
    final level = loadLevel('colour_01');
    final s = await pumpApp(tester, home: const HomeScreen());
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => RewardScreen(result: LevelResult(level: level, notes: const [0, 1, 2]), sessionOver: true)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    expect(find.byType(GoodnightScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('next')), findsNothing);
    final audio = s.audio as ManualClockAudio;
    expect(audio.log, contains('music:bgm_goodnight.ogg'));
    await tester.pump(const Duration(seconds: 2));
    expect(audio.log, contains('voice:vo_goodnight'));
    await tester.pump(GoodnightScreen.length);
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GoodnightScreen), findsNothing);
  });
}
