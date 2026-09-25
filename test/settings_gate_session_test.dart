import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/app.dart';
import 'package:rhythm_workshop/settings/game_settings.dart';
import 'package:rhythm_workshop/widgets/parental_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameSettings', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults match the design', () async {
      final s = await GameSettings.load();
      expect(s.language, VoiceLanguage.en);
      expect(s.sessionMinutes, 6);
      expect(s.haptics, isTrue);
      expect(s.calmMode, isFalse);
      expect(s.latencyMs, 0);
      expect(s.stars('colour_01'), 0);
    });

    test('values persist across loads, stars never go down, reset keeps settings', () async {
      final s = await GameSettings.load();
      s.language = VoiceLanguage.ur;
      s.calmMode = true;
      s.latencyMs = 999; // clamped
      await s.setStars('colour_01', 3);
      await s.setStars('colour_01', 1);
      final again = await GameSettings.load();
      expect(again.language, VoiceLanguage.ur);
      expect(again.calmMode, isTrue);
      expect(again.latencyMs, 250);
      expect(again.stars('colour_01'), 3);
      await again.resetProgress();
      expect(again.stars('colour_01'), 0);
      expect(again.language, VoiceLanguage.ur);
    });
  });

  group('SessionClock', () {
    test('ends only after the set minutes; 0 means no limit; reset starts over', () {
      var now = DateTime(2026);
      final c = SessionClock(now: () => now);
      expect(c.isOver(6), isFalse, reason: 'not started');
      c.startIfNeeded();
      now = now.add(const Duration(minutes: 5, seconds: 59));
      c.startIfNeeded(); // does not restart
      expect(c.isOver(6), isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(c.isOver(6), isTrue);
      expect(c.isOver(0), isFalse);
      c.reset();
      expect(c.isOver(6), isFalse);
    });
  });

  group('ParentalGate', () {
    Future<Future<bool>> open(WidgetTester tester, int seed) async {
      late Future<bool> result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => result = ParentalGate.show(context, random: Random(seed)),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    (int, int) problem(WidgetTester tester) {
      final text = tester.widget<Text>(find.byKey(const ValueKey('gate-problem'))).data!;
      final m = RegExp(r'(\d) × (\d)').firstMatch(text)!;
      return (int.parse(m[1]!), int.parse(m[2]!));
    }

    Future<void> type(WidgetTester tester, int n) async {
      for (final d in '$n'.split('')) {
        await tester.tap(find.byKey(ValueKey('gate-key-$d')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('right answer opens; answers are always two digits', (tester) async {
      tester.view.physicalSize = const Size(753, 339); // Galaxy A12 at density 340
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final result = await open(tester, 1);
      final (a, b) = problem(tester);
      expect(a * b, inInclusiveRange(30, 81));
      await type(tester, a * b);
      expect(await result, isTrue);
      expect(tester.takeException(), isNull, reason: 'dialog fits a 339 dp-tall phone');
    });

    testWidgets('three wrong answers close it; each miss gives a new problem', (tester) async {
      tester.view.physicalSize = const Size(753, 339);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final result = await open(tester, 2);
      for (var i = 0; i < 3; i++) {
        final (a, b) = problem(tester);
        await type(tester, a * b == 99 ? 98 : (a * b + 1 > 99 ? 10 : a * b + 1));
      }
      expect(await result, isFalse);
      expect(find.byType(ParentalGate), findsNothing);
    });
  });
}
