import 'dart:convert';

import 'package:flutter/services.dart';

class BinDef {
  const BinDef({required this.id, required this.symbol, required this.image});

  factory BinDef.fromJson(Map<String, dynamic> j) =>
      BinDef(id: j['id'] as String, symbol: j['symbol'] as String, image: j['image'] as String);

  final String id;

  /// Picture on the bin that carries meaning without colour (design D6).
  final String symbol;
  final String image;
}

class ItemDef {
  const ItemDef({required this.id, required this.bin, required this.image, this.scale = 1});

  factory ItemDef.fromJson(Map<String, dynamic> j) => ItemDef(
        id: j['id'] as String,
        bin: j['bin'] as String,
        image: j['image'] as String,
        scale: (j['scale'] as num?)?.toDouble() ?? 1,
      );

  final String id;
  final String bin;
  final String image;
  final double scale;
}

/// One level, read from `assets/levels/<id>.json`.
class Level {
  const Level({
    required this.id,
    required this.index,
    required this.world,
    required this.sortBy,
    required this.music,
    required this.bpm,
    required this.beltSpeed,
    required this.practiceTaps,
    required this.voicePrompt,
    required this.spawnEveryBeats,
    required this.maxOnBelt,
    required this.itemCount,
    required this.bins,
    required this.items,
    this.pattern = const [],
  });

  factory Level.fromJson(Map<String, dynamic> j) => Level(
        id: j['id'] as String,
        index: j['index'] as int,
        world: j['world'] as int,
        sortBy: j['sortBy'] as String,
        music: j['music'] as String,
        bpm: (j['bpm'] as num).toDouble(),
        beltSpeed: (j['beltSpeed'] as num).toDouble(),
        practiceTaps: j['practiceTaps'] as bool? ?? false,
        voicePrompt: j['voicePrompt'] as String,
        spawnEveryBeats: j['spawnEveryBeats'] as int? ?? 4,
        maxOnBelt: j['maxOnBelt'] as int? ?? 3,
        itemCount: j['itemCount'] as int,
        bins: [for (final b in j['bins'] as List) BinDef.fromJson(b as Map<String, dynamic>)],
        items: [for (final i in j['items'] as List) ItemDef.fromJson(i as Map<String, dynamic>)],
        pattern: [for (final p in (j['pattern'] as List?) ?? const []) p as String],
      );

  final String id;
  final int index;
  final int world;
  final String sortBy;
  final String music;
  final double bpm;

  /// Belt speed in dp per second at scale 1.
  final double beltSpeed;
  final bool practiceTaps;
  final String voicePrompt;
  final int spawnEveryBeats;
  final int maxOnBelt;
  final int itemCount;
  final List<BinDef> bins;
  final List<ItemDef> items;

  /// For pattern levels: the repeating bin sequence (e.g. fruit, veg).
  final List<String> pattern;

  bool get isPattern => pattern.isNotEmpty;

  BinDef bin(String id) => bins.firstWhere((b) => b.id == id);
}

/// Loads all levels once, in ladder order.
class LevelRepository {
  LevelRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<Level>? _levels;

  List<Level> get all => _levels ?? const [];

  Future<List<Level>> load() async {
    if (_levels != null) return _levels!;
    final index = jsonDecode(await _bundle.loadString('assets/levels/index.json')) as Map<String, dynamic>;
    final levels = <Level>[];
    for (final id in index['levels'] as List) {
      final raw = await _bundle.loadString('assets/levels/$id.json');
      levels.add(Level.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    return _levels = levels;
  }

  List<Level> world(int w) => all.where((l) => l.world == w).toList();

  Level? after(Level level) {
    final i = all.indexWhere((l) => l.id == level.id);
    return i >= 0 && i + 1 < all.length ? all[i + 1] : null;
  }
}
