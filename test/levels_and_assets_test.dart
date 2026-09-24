import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/audio/audio_engine.dart';
import 'package:rhythm_workshop/levels/level.dart';

import 'test_helpers.dart';

/// Checks the content rules from the design against the shipped files.
void main() {
  final levels = loadAllLevels();
  const musicBpm = {'bgm_calm.ogg': 70, 'bgm_workshop_01.ogg': 80, 'bgm_workshop_02.ogg': 90};
  const colourSymbols = {'red': 'circle', 'blue': 'square', 'yellow': 'star', 'green': 'triangle'};

  test('12 levels across 4 worlds, 3 per world, in order', () {
    expect(levels, hasLength(12));
    expect([for (final l in levels) l.index], List.generate(12, (i) => i + 1));
    for (var w = 1; w <= 4; w++) {
      expect(levels.where((l) => l.world == w), hasLength(3));
    }
    expect({for (final l in levels) l.id}, hasLength(12));
  });

  test('level BPM equals its music BPM (the beat is read from the music)', () {
    for (final l in levels) {
      expect(l.bpm, musicBpm[l.music], reason: l.id);
    }
  });

  test('practice taps only on the first level of worlds 1-3 (levels 1, 4, 7)', () {
    expect([for (final l in levels) if (l.practiceTaps) l.index], [1, 4, 7]);
  });

  test('every colour bin carries its shape symbol (never colour alone)', () {
    for (final l in levels.where((l) => l.sortBy == 'colour')) {
      for (final b in l.bins) {
        expect(b.symbol, colourSymbols[b.id], reason: '${l.id}/${b.id}');
      }
    }
  });

  test('every item points at a real bin and every bin has items', () {
    for (final l in levels) {
      final ids = {for (final b in l.bins) b.id};
      for (final i in l.items) {
        expect(ids, contains(i.bin), reason: '${l.id}/${i.id}');
      }
      for (final b in ids) {
        expect(l.items.where((i) => i.bin == b).length, greaterThanOrEqualTo(2), reason: '${l.id}/$b');
      }
      expect(l.itemCount, inInclusiveRange(10, 12), reason: 'design: 10-12 items per level');
      if (l.isPattern) expect(l.pattern.every(ids.contains), isTrue);
    }
  });

  test('size levels use the same picture at two sizes; shapes come in mixed colours', () {
    for (final l in levels.where((l) => l.sortBy == 'size')) {
      final big = {for (final i in l.items.where((i) => i.bin == 'big')) i.image};
      final small = {for (final i in l.items.where((i) => i.bin == 'small')) i.image};
      expect(big, small);
      final smallScale = l.items.firstWhere((i) => i.bin == 'small').scale;
      expect(smallScale, lessThan(0.7));
      expect(smallScale * 86 + 48, greaterThanOrEqualTo(64), reason: 'grab area stays >= 64 dp');
    }
    for (final l in levels.where((l) => l.sortBy == 'shape')) {
      for (final b in l.bins) {
        final colours = {for (final i in l.items.where((i) => i.bin == b.id)) i.id.split('_').last};
        expect(colours.length, greaterThanOrEqualTo(3), reason: 'learn to ignore colour');
      }
    }
  });

  test('all referenced images exist', () {
    for (final l in levels) {
      for (final path in [...l.bins.map((b) => b.image), ...l.items.map((i) => i.image)]) {
        expect(File('assets/images/$path').existsSync(), isTrue, reason: path);
      }
    }
    for (final f in [
      'ui/background.png',
      for (var w = 1; w <= 4; w++) 'worlds/world_$w.png',
      for (final c in ['milo_idle', 'milo_hit_left', 'milo_hit_right', 'milo_celebrate', 'pip_idle', 'pip_clap',
        'pip_point', 'pip_hmm', 'pip_dance', 'pip_wave', 'pip_sleep'])
        'characters/$c.png',
    ]) {
      expect(File('assets/images/$f').existsSync(), isTrue, reason: f);
    }
  });

  test('complete audio manifest, in both languages', () {
    final files = [
      for (final m in ['bgm_calm', 'bgm_workshop_01', 'bgm_workshop_02', 'bgm_goodnight']) 'bgm/$m.ogg',
      for (final s in ['sfx_pick_up', 'sfx_sparkle', 'sfx_soft_note', 'sfx_whoosh']) 'sfx/$s.wav',
      for (final n in AudioEngine.notes) 'sfx/sfx_note_$n.wav',
      for (final p in ['perc_tap_down', 'perc_tap_up', 'perc_fill']) 'perc/$p.wav',
      for (final lang in ['en', 'ur'])
        for (final v in [
          'vo_welcome', 'vo_prompt_colour', 'vo_prompt_size', 'vo_prompt_shape', 'vo_prompt_food',
          'vo_prompt_pattern', 'vo_try_here', 'vo_praise_01', 'vo_praise_02', 'vo_goodnight',
        ])
          'vo/$lang/$v.ogg',
    ];
    for (final f in files) {
      expect(File('assets/audio/$f').existsSync(), isTrue, reason: f);
    }
    for (final l in levels) {
      expect(File('assets/audio/vo/en/${l.voicePrompt}.ogg').existsSync(), isTrue);
    }
  });

  test('LevelRepository loads through the asset bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = LevelRepository();
    final all = await repo.load();
    expect(all.map((l) => l.id), levels.map((l) => l.id));
    expect(repo.world(4).map((l) => l.index), [10, 11, 12]);
    expect(repo.after(all[3])!.id, all[4].id);
    expect(repo.after(all.last), isNull);
  });
}
