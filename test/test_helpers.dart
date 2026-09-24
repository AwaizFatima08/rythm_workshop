import 'dart:convert';
import 'dart:io';

import 'package:rhythm_workshop/audio/audio_engine.dart';
import 'package:rhythm_workshop/levels/level.dart';

/// Reads a level straight from the assets folder (no asset bundle needed).
Level loadLevel(String id) =>
    Level.fromJson(jsonDecode(File('assets/levels/$id.json').readAsStringSync()) as Map<String, dynamic>);

List<Level> loadAllLevels() {
  final index = jsonDecode(File('assets/levels/index.json').readAsStringSync()) as Map<String, dynamic>;
  return [for (final id in index['levels'] as List) loadLevel(id as String)];
}

/// Silent engine whose music clock the test moves by hand.
class ManualClockAudio extends SilentAudioEngine {
  double t = 0;

  @override
  double musicMs() => t;
}
