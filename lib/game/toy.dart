import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../levels/level.dart';
import 'workshop_game.dart';

enum ToyState { onBelt, dragging, returning, sorted }

/// A toy riding the belt. The child drags it with one finger into a bin.
class Toy extends SpriteComponent with DragCallbacks, HasGameReference<WorkshopGame> {
  Toy({required this.item, required Sprite sprite, required double baseSize, required Vector2 position})
      : super(
          sprite: sprite,
          size: Vector2.all(baseSize * item.scale),
          position: position,
          anchor: Anchor.center,
          priority: 5,
        );

  /// Extra grab area on every side, in dp (design: 24 dp).
  static const grabMargin = 24.0;

  final ItemDef item;
  ToyState state = ToyState.onBelt;
  int? _pointer;
  int wrongDrops = 0;

  bool get isActive => state != ToyState.sorted;

  @override
  bool containsLocalPoint(Vector2 point) {
    final m = grabMargin / scale.x;
    return point.x >= -m && point.y >= -m && point.x <= size.x + m && point.y <= size.y + m;
  }

  @override
  void onDragStart(DragStartEvent event) {
    // One finger only: whichever finger grabbed first owns the drag.
    if (state == ToyState.sorted || state == ToyState.dragging || game.activePointer != null) return;
    super.onDragStart(event);
    _pointer = event.pointerId;
    game.activePointer = event.pointerId;
    state = ToyState.dragging;
    removeAll(children.whereType<Effect>());
    priority = 20;
    add(ScaleEffect.to(Vector2.all(1.12), EffectController(duration: 0.08)));
    game.onToyGrabbed(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId != _pointer) return;
    position += event.canvasDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (event.pointerId != _pointer) return;
    super.onDragEnd(event);
    _release();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (event.pointerId != _pointer) return;
    super.onDragCancel(event);
    _release();
  }

  void _release() {
    _pointer = null;
    game.activePointer = null;
    add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.08)));
    game.onToyReleased(this);
  }

  /// Glides (missed drop) or floats (wrong bin) back onto the belt; never lost.
  void returnToBelt(Vector2 target, {double duration = 0.3}) {
    state = ToyState.returning;
    add(MoveToEffect(
      target,
      EffectController(duration: duration, curve: Curves.easeOutCubic),
      onComplete: () {
        state = ToyState.onBelt;
        priority = 5;
      },
    ));
  }

  /// Snaps into the bin, shrinks and disappears.
  void snapInto(Vector2 target) {
    state = ToyState.sorted;
    removeAll(children.whereType<Effect>());
    add(MoveToEffect(target, EffectController(duration: 0.18, curve: Curves.easeOut)));
    add(SequenceEffect([
      ScaleEffect.to(Vector2.all(0.85), EffectController(duration: 0.18)),
      ScaleEffect.to(Vector2.all(0.05), EffectController(duration: 0.22, curve: Curves.easeIn)),
      RemoveEffect(),
    ]));
  }
}
