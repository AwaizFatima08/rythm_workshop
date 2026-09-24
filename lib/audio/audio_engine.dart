import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../settings/game_settings.dart';

/// Sound for the whole app. One implementation uses flutter_soloud; tests use
/// [SilentAudioEngine] because the native engine is not available on the host.
abstract class AudioEngine {
  /// Pentatonic chime notes; the streak climbs this list and wraps.
  static const notes = ['c5', 'd5', 'e5', 'g5', 'a5', 'c6'];

  Future<void> init();

  Future<void> startMusic(String file, {bool loop = true});
  Future<void> stopMusic();
  void pauseMusic(bool paused);

  /// Current music play position in ms (0 when nothing plays).
  double musicMs();

  void playPickUp();

  /// Plays chime [noteIndex] (wrapping) after [delay]; [bright] adds sparkle.
  void playChime(int noteIndex, {bool bright = false, Duration delay = Duration.zero});
  void playSoftNote();
  void playWhoosh();
  void playTap({required bool downbeat});
  void playFill();

  /// Speaks voice line [id] (e.g. `vo_welcome`) in the chosen language.
  Future<void> playVoice(String id);

  /// Stops everything that is sounding (used when the app goes to background).
  void silenceAll();
  void dispose();
}

class SoloudAudioEngine implements AudioEngine {
  SoloudAudioEngine(this.settings) {
    settings.addListener(_applyVolumes);
  }

  final GameSettings settings;
  final _s = SoLoud.instance;
  final Map<String, AudioSource> _sfx = {};
  final Map<String, AudioSource> _voice = {};
  final _random = Random();
  AudioSource? _musicSource;
  SoundHandle? _music;
  SoundHandle? _speaking;
  bool _ready = false;

  /// True once the native engine started and all effects loaded.
  bool get isReady => _ready;

  static final _sfxFiles = [
    'sfx/sfx_pick_up.wav', 'sfx/sfx_sparkle.wav', 'sfx/sfx_soft_note.wav', 'sfx/sfx_whoosh.wav',
    'perc/perc_tap_down.wav', 'perc/perc_tap_up.wav', 'perc/perc_fill.wav',
    for (final n in AudioEngine.notes) 'sfx/sfx_note_$n.wav',
  ];

  double get _fx => settings.effectsVolume;
  double get _musicVol => settings.musicVolume * (settings.calmMode ? 0.45 : 0.55);

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      await _s.init(bufferSize: 1024, channels: Channels.stereo);
      _s.setMaxActiveVoiceCount(24);
      for (final f in _sfxFiles) {
        _sfx[f] = await _s.loadAsset('assets/audio/$f');
      }
      _ready = true;
    } catch (e) {
      // The game stays fully playable without sound (Pip points, bins glow).
      debugPrint('Audio init failed: $e');
    }
  }

  void _play(String file, double volume, {double speed = 1}) {
    final src = _sfx[file];
    if (!_ready || src == null || volume <= 0) return;
    final h = _s.play(src, volume: volume);
    if (speed != 1) _s.setRelativePlaySpeed(h, speed);
  }

  @override
  Future<void> startMusic(String file, {bool loop = true}) async {
    if (!_ready) return;
    await stopMusic();
    try {
      _musicSource = await _s.loadAsset('assets/audio/bgm/$file');
      _music = _s.play(_musicSource!, looping: loop, volume: _musicVol);
      _s.setProtectVoice(_music!, true);
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  @override
  Future<void> stopMusic() async {
    final h = _music, src = _musicSource;
    _music = null;
    _musicSource = null;
    if (h != null && _s.getIsValidVoiceHandle(h)) await _s.stop(h);
    if (src != null) await _s.disposeSource(src);
  }

  @override
  void pauseMusic(bool paused) {
    final h = _music;
    if (h != null && _s.getIsValidVoiceHandle(h)) _s.setPause(h, paused);
  }

  @override
  double musicMs() {
    final h = _music;
    if (!_ready || h == null || !_s.getIsValidVoiceHandle(h)) return 0;
    return _s.getPosition(h).inMicroseconds / 1000.0;
  }

  void _applyVolumes() {
    final h = _music;
    if (_ready && h != null && _s.getIsValidVoiceHandle(h)) _s.setVolume(h, _musicVol);
  }

  @override
  void playPickUp() {
    // Only this pop gets a random pitch (+-50 cents); musical notes never do.
    final cents = _random.nextDouble() * 100 - 50;
    _play('sfx/sfx_pick_up.wav', 0.6 * _fx, speed: pow(2, cents / 1200).toDouble());
  }

  @override
  void playChime(int noteIndex, {bool bright = false, Duration delay = Duration.zero}) {
    final note = AudioEngine.notes[noteIndex % AudioEngine.notes.length];
    void go() {
      _play('sfx/sfx_note_$note.wav', 0.85 * _fx);
      if (bright) _play('sfx/sfx_sparkle.wav', 0.6 * _fx);
    }

    delay <= Duration.zero ? go() : Timer(delay, go);
  }

  @override
  void playSoftNote() => _play('sfx/sfx_soft_note.wav', 0.5 * _fx);

  @override
  void playWhoosh() => _play('sfx/sfx_whoosh.wav', 0.5 * _fx);

  @override
  void playTap({required bool downbeat}) =>
      _play(downbeat ? 'perc/perc_tap_down.wav' : 'perc/perc_tap_up.wav', 0.45 * _fx);

  @override
  void playFill() => _play('perc/perc_fill.wav', 0.7 * _fx);

  @override
  Future<void> playVoice(String id) async {
    if (!_ready || _fx <= 0) return;
    final path = 'assets/audio/vo/${settings.language.name}/$id.ogg';
    try {
      final src = _voice[path] ??= await _s.loadAsset(path);
      final prev = _speaking;
      if (prev != null && _s.getIsValidVoiceHandle(prev)) await _s.stop(prev);
      _speaking = _s.play(src, volume: _fx);
    } catch (e) {
      debugPrint('Voice $id failed: $e');
    }
  }

  @override
  void silenceAll() {
    pauseMusic(true);
    final v = _speaking;
    if (v != null && _s.getIsValidVoiceHandle(v)) _s.stop(v);
  }

  @override
  void dispose() {
    settings.removeListener(_applyVolumes);
    if (_ready) _s.deinit();
    _ready = false;
  }
}

/// No-op engine for tests and devices where audio fails. Music time comes
/// from a stopwatch so the beat still advances.
class SilentAudioEngine implements AudioEngine {
  final _watch = Stopwatch();
  bool _paused = false;
  final List<String> log = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> startMusic(String file, {bool loop = true}) async {
    log.add('music:$file');
    _watch
      ..reset()
      ..start();
  }

  @override
  Future<void> stopMusic() async => _watch.stop();

  @override
  void pauseMusic(bool paused) {
    _paused = paused;
    paused ? _watch.stop() : _watch.start();
  }

  bool get paused => _paused;

  @override
  double musicMs() => _watch.elapsedMicroseconds / 1000.0;

  @override
  void playPickUp() => log.add('pickup');

  @override
  void playChime(int noteIndex, {bool bright = false, Duration delay = Duration.zero}) =>
      log.add('chime:$noteIndex${bright ? ':bright' : ''}${delay > Duration.zero ? '@${delay.inMilliseconds}' : ''}');

  @override
  void playSoftNote() => log.add('soft');

  @override
  void playWhoosh() => log.add('whoosh');

  @override
  void playTap({required bool downbeat}) => log.add(downbeat ? 'tapDown' : 'tapUp');

  @override
  void playFill() => log.add('fill');

  @override
  Future<void> playVoice(String id) async => log.add('voice:$id');

  @override
  void silenceAll() => log.add('silence');

  @override
  void dispose() {}
}
