import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// Milo the monkey drums the beat so children can *see* it.
class Milo extends SpriteComponent {
  Milo({required this.frames, required Rect rect})
      : super(
          sprite: frames['milo_idle'],
          position: Vector2(rect.center.dx, rect.bottom),
          size: Vector2(rect.height * 320 / 340, rect.height),
          anchor: Anchor.bottomCenter,
          priority: 3,
        );

  final Map<String, Sprite> frames;
  bool _left = true;
  double _hitTimer = 0;
  bool celebrating = false;

  /// Called on each heard beat: alternate hands and bob the head.
  void onBeat(int beatInBar) {
    if (celebrating) return;
    sprite = frames[_left ? 'milo_hit_left' : 'milo_hit_right'];
    _left = !_left;
    _hitTimer = 0.16;
    add(SequenceEffect([
      ScaleEffect.to(Vector2(1.03, beatInBar == 0 ? 0.93 : 0.96), EffectController(duration: 0.06)),
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18, curve: Curves.easeOut)),
    ]));
  }

  void celebrate() {
    celebrating = true;
    sprite = frames['milo_celebrate'];
    add(MoveByEffect(Vector2(0, -8), EffectController(duration: 0.25, alternate: true, repeatCount: 4)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitTimer > 0) {
      _hitTimer -= dt;
      if (_hitTimer <= 0 && !celebrating) sprite = frames['milo_idle'];
    }
  }
}

/// Pip the penguin reacts to sorts. Pip never looks sad: on a wrong bin he
/// tilts his head and points at the right bin once.
class Pip extends SpriteComponent {
  Pip({required this.frames, required Rect rect})
      : super(
          sprite: frames['pip_idle'],
          position: Vector2(rect.center.dx, rect.bottom),
          size: Vector2(rect.height * 400 / 360, rect.height),
          anchor: Anchor.bottomCenter,
          priority: 3,
        );

  final Map<String, Sprite> frames;
  double _hold = 0;
  bool dancing = false;

  void _show(String frame, double seconds, {bool flip = false}) {
    if (dancing) return;
    sprite = frames[frame];
    if (flip != isFlippedHorizontally) flipHorizontally();
    _hold = seconds;
  }

  void clap() {
    _show('pip_clap', 0.6);
    add(MoveByEffect(Vector2(0, -10), EffectController(duration: 0.12, alternate: true)));
  }

  /// Points at a spot on screen (the art points right; flip to point left).
  void pointAt(Offset target, {double seconds = 1.4}) =>
      _show('pip_point', seconds, flip: target.dx < position.x);

  void hmm() => _show('pip_hmm', 0.9);

  void dance() {
    _show('pip_dance', 999);
    dancing = true;
    add(RotateEffect.by(0.18, EffectController(duration: 0.3, alternate: true, infinite: true)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hold > 0 && !dancing) {
      _hold -= dt;
      if (_hold <= 0) {
        sprite = frames['pip_idle'];
        if (isFlippedHorizontally) flipHorizontally();
      }
    }
  }
}
