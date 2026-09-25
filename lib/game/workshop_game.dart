import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/audio_engine.dart';
import '../audio/beat_clock.dart';
import '../levels/level.dart';
import '../settings/game_settings.dart';
import '../theme.dart';
import 'belt.dart';
import 'bin.dart';
import 'characters.dart';
import 'effects.dart';
import 'layout.dart';
import 'pattern_shelf.dart';
import 'rules.dart';
import 'toy.dart';

class LevelResult {
  const LevelResult({required this.level, required this.notes});

  final Level level;

  /// The child's song: one pentatonic note index per correct sort.
  final List<int> notes;
}

/// One level of play: belt, toys, bins, Milo and Pip.
class WorkshopGame extends FlameGame {
  WorkshopGame({
    required this.level,
    required this.audio,
    required this.settings,
    this.onComplete,
    Random? random,
  })  : rules = SortingRules(level, random: random),
        clock = BeatClock(bpm: level.bpm);

  /// Right-bin drops this close to a heard beat earn the bonus sparkle (design: +-200 ms).
  static const onBeatWindowMs = 200.0;

  /// Seconds without any drag before Pip shows where the front toy goes.
  static const idleHintSeconds = 9.0;

  @visibleForTesting
  static WorkshopGame? current;

  final Level level;
  final AudioEngine audio;
  final GameSettings settings;
  final SortingRules rules;
  final BeatClock clock;
  final void Function(LevelResult result)? onComplete;

  late WorkshopLayout layout;
  late Belt belt;
  late Milo milo;
  late Pip pip;
  late StarMeter starMeter;
  final List<DropTarget> targets = [];
  final List<Toy> toys = [];
  PatternShelf? shelf;

  /// Pointer id of the finger currently dragging a toy (one finger only).
  int? activePointer;

  late final BeatTracker _rawBeats = BeatTracker(clock);
  late final BeatTracker _heardBeats = BeatTracker(clock);
  int _beatsSinceSpawn = 0;
  double _idle = 0;
  double _sinceTryHere = 99;
  bool finished = false;
  bool _started = false;

  @visibleForTesting
  int get debugRawBeatsSeen => _rawBeats.totalBeats;

  List<Toy> get activeToys => toys.where((t) => t.isActive).toList();

  double get _latency => settings.latencyMs.toDouble();

  double get beltSpeed =>
      level.beltSpeed * layout.scale * rules.speedFactor * (settings.calmMode ? 0.75 : 1.0);

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    current = this;
    layout = WorkshopLayout(Size(size.x, size.y), binCount: level.bins.length, pattern: level.isPattern);
    await images.loadAll([
      'ui/background.png',
      for (final b in level.bins) b.image,
      for (final i in level.items) i.image,
      for (final f in _characterFrames) 'characters/$f.png',
    ]);
    final frames = {for (final f in _characterFrames) f: Sprite(images.fromCache('characters/$f.png'))};

    // Background covers the screen, anchored to the floor.
    final bg = images.fromCache('ui/background.png');
    final cover = max(size.x / bg.width, size.y / bg.height);
    add(SpriteComponent(
      sprite: Sprite(bg),
      size: Vector2(bg.width * cover, bg.height * cover),
      position: Vector2(size.x / 2, size.y),
      anchor: Anchor.bottomCenter,
      priority: 0,
    ));

    belt = Belt(rect: layout.beltRect, scaleFactor: layout.scale);
    add(belt);

    if (level.isPattern) {
      final repr = {
        for (final b in level.pattern) b: Sprite(images.fromCache(level.items.firstWhere((i) => i.bin == b).image)),
      };
      shelf = PatternShelf(rect: layout.targets.first, sprites: repr, startBins: rules.patternPlaced);
      targets.add(shelf!);
    } else {
      for (var i = 0; i < level.bins.length; i++) {
        final b = level.bins[i];
        targets.add(BinComponent(targetId: b.id, sprite: Sprite(images.fromCache(b.image)), rect: layout.targets[i]));
      }
    }
    addAll(targets.cast<Component>());

    milo = Milo(frames: frames, rect: layout.miloRect);
    pip = Pip(frames: frames, rect: layout.pipRect);
    starMeter = StarMeter(rect: layout.starsRect);
    addAll([milo, pip, starMeter]);

    await audio.startMusic(level.music);
    _started = true;
    _introduce();
  }

  static const _characterFrames = [
    'milo_idle', 'milo_hit_left', 'milo_hit_right', 'milo_celebrate', //
    'pip_idle', 'pip_clap', 'pip_point', 'pip_hmm', 'pip_dance',
  ];

  /// Voice prompt while Pip points at each target in turn and it glows,
  /// so the rule is clear even with the sound off.
  void _introduce() {
    audio.playVoice(level.voicePrompt);
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      Future.delayed(Duration(milliseconds: 300 + i * 1300), () {
        if (!isMounted || finished) return;
        pip.pointAt(t.rect.center, seconds: 1.2);
        t.glow(1.2);
      });
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;
    final ms = audio.musicMs();

    // Raw position drives sounds we schedule; heard position drives visuals.
    final raw = _rawBeats.update(ms);
    if (raw != null) _onBeat(raw);
    final heard = _heardBeats.update(ms - _latency);
    if (heard != null) milo.onBeat(heard % 4);

    belt.speed = finished ? 0 : beltSpeed;
    for (final t in toys) {
      if (t.state != ToyState.onBelt) continue;
      t.x += belt.speed * dt;
      // Toys that reach the end loop round; the belt never drops them.
      if (t.x - t.size.x / 2 > size.x) t.x -= layout.beltLoopLength;
    }
    toys.removeWhere((t) => t.state == ToyState.sorted && !t.isMounted);

    _sinceTryHere += dt;
    if (activePointer == null && !finished) {
      _idle += dt;
      if (_idle > idleHintSeconds) {
        _idle = 0;
        _hint();
      }
    }
  }

  void _onBeat(int beatInLoop) {
    if (finished) return;
    if (level.practiceTaps) audio.playTap(downbeat: beatInLoop % 4 == 0);
    _beatsSinceSpawn++;
    if (_beatsSinceSpawn >= level.spawnEveryBeats) _trySpawn();
  }

  void _trySpawn() {
    final onBelt = activeToys;
    final bins = [for (final t in onBelt) t.item.bin];
    if (!rules.canSpawn(onBelt.length, bins)) return;
    // Wait a beat if the entry is still busy.
    final entryBusy = onBelt.any((t) => t.state == ToyState.onBelt && t.x < layout.toySize * 1.3);
    if (entryBusy) return;
    final item = rules.takeNext(activeBins: bins);
    if (item == null) return;
    _beatsSinceSpawn = 0;
    final toy = Toy(
      item: item,
      sprite: Sprite(images.fromCache(item.image)),
      baseSize: layout.toySize,
      position: Vector2(-layout.toySize / 2, _toyY(item)),
    );
    toys.add(toy);
    add(toy);
  }

  /// Small toys sit on the belt surface rather than floating in the middle.
  double _toyY(ItemDef item) => layout.beltCenterY + layout.toySize * (1 - item.scale) / 2 * 0.8;

  DropTarget? _target(String? id) => id == null ? null : targets.firstWhere((t) => t.targetId == id);

  void onToyGrabbed(Toy toy) {
    _idle = 0;
    audio.playPickUp();
  }

  void onToyReleased(Toy toy) {
    _idle = 0;
    final rect = toy.toRect();
    // Let go while still over the belt: the child only nudged it. The bins'
    // magnetic margin reaches into the belt row on small phones, so check first.
    final overBelt = toy.y < layout.beltRect.bottom;
    final id = overBelt ? null : findTarget(rect, {for (final t in targets) t.targetId: t.rect});
    switch (rules.judge(toy.item, id)) {
      case DropResult.nowhere:
        audio.playWhoosh();
        toy.returnToBelt(_returnSpot(toy));
      case DropResult.wrong:
        _wrong(toy);
      case DropResult.correct:
        _correct(toy, _target(id)!);
    }
  }

  Vector2 _returnSpot(Toy toy) =>
      Vector2(toy.x.clamp(toy.size.x / 2, size.x - toy.size.x / 2), _toyY(toy.item));

  void _wrong(Toy toy) {
    rules.recordWrong();
    toy.wrongDrops++;
    audio.playSoftNote();
    pip.hmm();
    final right = _target(rules.correctTargetFor(toy.item));
    if (right != null) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!isMounted) return;
        pip.pointAt(right.rect.center);
        right.glow(1.8);
      });
    }
    if (toy.wrongDrops >= 2 && _sinceTryHere > 6) {
      _sinceTryHere = 0;
      audio.playVoice('vo_try_here');
    }
    toy.returnToBelt(_returnSpot(toy), duration: 0.5);
  }

  void _correct(Toy toy, DropTarget target) {
    // Auto-quantise: the drop always counts; the chime waits for the next beat.
    final now = audio.musicMs();
    final onBeat = clock.offsetFromNearestBeat(now - _latency).abs() <= onBeatWindowMs;
    final waitMs = onBeat ? 0.0 : clock.msUntilNextBeat(now);
    final note = rules.recordCorrect(toy.item);
    audio.playChime(note, bright: onBeat, delay: Duration(milliseconds: waitMs.round()));
    if (settings.haptics) HapticFeedback.lightImpact();

    final shelf = this.shelf;
    if (shelf != null) {
      toy.snapInto(shelf.nextSlotCenter);
      shelf.place(toy.sprite!);
    } else {
      toy.snapInto(Vector2(target.rect.center.dx, target.rect.center.dy));
    }
    Future.delayed(Duration(milliseconds: waitMs.round()), () {
      if (isMounted) target.bounce();
    });
    if (onBeat) add(SparkleBurst(position: toy.position.clone(), radius: layout.toySize));
    pip.clap();
    starMeter.setFilled(rules.starsFilled);

    if (rules.complete) {
      _finish();
    } else if (rules.streak % 4 == 0) {
      audio.playVoice(rules.streak % 8 == 0 ? 'vo_praise_02' : 'vo_praise_01');
    }
  }

  /// With no drag for a while, show where the frontmost toy goes.
  void _hint() {
    final onBelt = toys.where((t) => t.state == ToyState.onBelt && t.x > 0 && t.x < size.x).toList();
    if (onBelt.isEmpty) return;
    onBelt.sort((a, b) => b.x.compareTo(a.x));
    for (final t in onBelt) {
      final target = _target(rules.correctTargetFor(t.item));
      if (target == null) continue;
      pip.pointAt(target.rect.center, seconds: 1.6);
      target.glow(2);
      return;
    }
  }

  void _finish() {
    finished = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!isMounted) return;
      audio.playFill();
      milo.celebrate();
      pip.dance();
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!isMounted) return;
      onComplete?.call(LevelResult(level: level, notes: List.of(rules.songNotes)));
    });
  }

  /// Pauses play and music together (pause button or app sent to background).
  void setPaused(bool paused) {
    paused ? pauseEngine() : resumeEngine();
    audio.pauseMusic(paused);
  }

  @override
  void onRemove() {
    if (current == this) current = null;
    audio.stopMusic();
    super.onRemove();
  }
}
