import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_workshop/audio/beat_clock.dart';

void main() {
  const clock = BeatClock(bpm: 80); // 750 ms per beat

  test('beat length follows BPM', () {
    expect(clock.beatMs, 750);
    expect(const BeatClock(bpm: 70).beatMs, closeTo(857.14, 0.01));
  });

  test('offset from nearest beat is signed: early negative, late positive', () {
    expect(clock.offsetFromNearestBeat(1500), 0);
    expect(clock.offsetFromNearestBeat(1550), 50);
    expect(clock.offsetFromNearestBeat(1450), -50);
    expect(clock.offsetFromNearestBeat(1500 + 375), 375); // exactly half way counts as late
  });

  test('time until next beat never exceeds one beat', () {
    expect(clock.msUntilNextBeat(0), 0);
    expect(clock.msUntilNextBeat(1), 749);
    expect(clock.msUntilNextBeat(749), 1);
    for (var ms = 0.0; ms < 5000; ms += 37) {
      expect(clock.msUntilNextBeat(ms), inInclusiveRange(0, clock.beatMs));
    }
  });

  test('tracker reports each beat once, and again after the music loops', () {
    final t = BeatTracker(clock);
    final beats = <int>[];
    for (var ms = 0.0; ms < 3100; ms += 16) {
      final b = t.update(ms);
      if (b != null) beats.add(b);
    }
    expect(beats, [0, 1, 2, 3, 4]);
    // Loop back to the start of the track.
    expect(t.update(5), 0);
    expect(t.update(20), isNull);
    expect(t.totalBeats, 6);
  });

  test('tracker ignores negative time (latency before music starts)', () {
    final t = BeatTracker(clock);
    expect(t.update(-100), isNull);
    expect(t.update(0), 0);
  });
}
