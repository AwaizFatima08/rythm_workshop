import 'dart:math';
import 'dart:ui';

import '../levels/level.dart';

enum DropResult { nowhere, wrong, correct }

/// Id of the single drop target in pattern levels.
const shelfId = 'shelf';

/// Game rules with no drawing or sound, so they can be unit tested.
///
/// - A correct drop always counts (auto-quantise happens in the game).
/// - A wrong drop never costs anything except the streak.
/// - The belt speeds up 10% after every 5 correct in a row (max +30%) and
///   returns to normal after 2 wrong drops in a row.
class SortingRules {
  SortingRules(this.level, {Random? random}) : _random = random ?? Random() {
    _queue = _buildQueue();
    if (level.isPattern) {
      // The shelf starts with one full A-B so the child can see the pattern.
      patternPlaced.addAll(level.pattern);
    }
  }

  static const speedStep = 0.1;
  static const maxSpeed = 1.3;

  final Level level;
  final Random _random;
  late final List<ItemDef> _queue;

  int sorted = 0;
  int streak = 0;
  int wrongInRow = 0;
  double speedFactor = 1;

  /// Note index (0-5) of every correct sort, replayed on the reward screen.
  final List<int> songNotes = [];

  /// Bin ids shown on the pattern shelf, oldest first.
  final List<String> patternPlaced = [];

  int get remainingToSpawn => _queue.length;
  bool get complete => sorted >= level.itemCount;

  /// Stars in the gameplay meter: one per third of the level.
  int get starsFilled => (sorted * 3 ~/ level.itemCount).clamp(0, 3);

  /// Bin that the pattern shelf wants next.
  String get expectedPatternBin => level.pattern[patternPlaced.length % level.pattern.length];

  /// The drop target that accepts [item] right now (null: none, pattern only).
  String? correctTargetFor(ItemDef item) {
    if (!level.isPattern) return item.bin;
    return item.bin == expectedPatternBin ? shelfId : null;
  }

  List<ItemDef> _buildQueue() {
    final binIds = level.isPattern ? level.pattern : [for (final b in level.bins) b.id];
    final perBin = <String, int>{for (final b in binIds) b: level.itemCount ~/ binIds.length};
    final extra = [...binIds]..shuffle(_random);
    for (var i = 0; i < level.itemCount % binIds.length; i++) {
      perBin[extra[i]] = perBin[extra[i]]! + 1;
    }
    // Shuffle until the same bin never comes 3 times in a row. With balanced
    // counts almost every shuffle qualifies, so this ends within a few tries.
    final order = [for (final e in perBin.entries) for (var i = 0; i < e.value; i++) e.key];
    bool tripled(List<String> o) =>
        [for (var k = 2; k < o.length; k++) o[k] == o[k - 1] && o[k] == o[k - 2]].any((x) => x);
    for (var tries = 0; tries < 500; tries++) {
      order.shuffle(_random);
      if (!tripled(order)) break;
    }
    String? lastId;
    return [
      for (final b in order) lastId = _pickItem(b, lastId),
    ].map((id) => level.items.firstWhere((i) => i.id == id)).toList();
  }

  String _pickItem(String bin, String? avoid) {
    final pool = level.items.where((i) => i.bin == bin && i.id != avoid).toList();
    return pool[_random.nextInt(pool.length)].id;
  }

  /// Next toy for the belt. In pattern levels, if no toy of the needed kind is
  /// already out ([activeBins]), one is pulled forward so play can never stall.
  ItemDef? takeNext({List<String> activeBins = const []}) {
    if (_queue.isEmpty) return null;
    var i = 0;
    if (level.isPattern && !activeBins.contains(expectedPatternBin)) {
      final j = _queue.indexWhere((it) => it.bin == expectedPatternBin);
      if (j >= 0) i = j;
    }
    return _queue.removeAt(i);
  }

  /// In pattern levels the belt may take one extra toy when the needed kind is missing.
  bool canSpawn(int onBelt, List<String> activeBins) {
    if (_queue.isEmpty) return false;
    if (onBelt < level.maxOnBelt) return true;
    return level.isPattern && !activeBins.contains(expectedPatternBin) && onBelt <= level.maxOnBelt;
  }

  DropResult judge(ItemDef item, String? targetId) {
    if (targetId == null) return DropResult.nowhere;
    if (level.isPattern) {
      return targetId == shelfId && item.bin == expectedPatternBin ? DropResult.correct : DropResult.wrong;
    }
    return targetId == item.bin ? DropResult.correct : DropResult.wrong;
  }

  /// Records a correct sort and returns the chime note index (streak climbs the scale).
  int recordCorrect(ItemDef item) {
    sorted++;
    streak++;
    wrongInRow = 0;
    if (level.isPattern) patternPlaced.add(item.bin);
    if (streak % 5 == 0) speedFactor = min(maxSpeed, speedFactor + speedStep);
    final note = (streak - 1) % 6;
    songNotes.add(note);
    return note;
  }

  void recordWrong() {
    streak = 0;
    wrongInRow++;
    if (wrongInRow >= 2) speedFactor = 1;
  }
}

/// Returns the target the toy was dropped into, or null for "nowhere".
/// Each zone is [snapMargin] bigger than its drawing; the biggest overlap wins.
String? findTarget(Rect toyRect, Map<String, Rect> targets, {double snapMargin = 40}) {
  String? best;
  double bestArea = 0;
  for (final e in targets.entries) {
    final overlap = e.value.inflate(snapMargin).intersect(toyRect);
    if (overlap.width <= 0 || overlap.height <= 0) continue;
    final area = overlap.width * overlap.height;
    if (area > bestArea) {
      bestArea = area;
      best = e.key;
    }
  }
  return best;
}
