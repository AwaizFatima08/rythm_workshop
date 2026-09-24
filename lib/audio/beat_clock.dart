/// Beat maths, read from the music's play position so it never drifts.
class BeatClock {
  const BeatClock({required this.bpm});

  final double bpm;

  double get beatMs => 60000 / bpm;

  /// Distance to the nearest beat: negative just before a beat (early),
  /// positive just after it (late).
  double offsetFromNearestBeat(double ms) {
    final phase = ms % beatMs;
    return phase <= beatMs / 2 ? phase : phase - beatMs;
  }

  /// Time left until the next beat. Exactly on a beat returns 0.
  double msUntilNextBeat(double ms) {
    final phase = ms % beatMs;
    return phase == 0 ? 0 : beatMs - phase;
  }

  int beatIndex(double ms) => (ms / beatMs).floor();
}

/// Reports each new beat as the music position moves forward, including
/// across the loop point (music loops are whole bars, so beat 0 = bar start).
class BeatTracker {
  BeatTracker(this.clock);

  final BeatClock clock;
  int _last = -1;
  double _lastMs = 0;
  int _total = 0;

  /// Total beats seen since start (keeps counting across loops).
  int get totalBeats => _total;

  /// Returns the beat-in-loop index when a new beat started, else null.
  int? update(double ms) {
    if (ms < 0) return null;
    if (ms + clock.beatMs < _lastMs) _last = -1; // music looped back to 0
    _lastMs = ms;
    final i = clock.beatIndex(ms);
    if (i != _last) {
      _last = i;
      _total++;
      return i;
    }
    return null;
  }
}
