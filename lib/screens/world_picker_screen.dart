import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/buttons.dart';
import 'common.dart';
import 'level_picker_screen.dart';

/// Four picture cards, one per world. Stars show finished levels (no numbers).
class WorldPickerScreen extends StatelessWidget {
  const WorldPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final cardH = (size.height * 0.5).clamp(160.0, 320.0);
    return Scaffold(
      body: WorkshopBackground(
        child: Stack(
          children: [
            const Positioned(top: 8, left: 12, child: BackArrowButton()),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var w = 1; w <= 4; w++)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: _WorldCard(
                            world: w,
                            height: cardH,
                            stars: services.levels.world(w).where((l) => services.settings.stars(l.id) > 0).length,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldCard extends StatefulWidget {
  const _WorldCard({required this.world, required this.height, required this.stars});

  final int world;
  final double height;
  final int stars;

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'World ${widget.world}',
      child: GestureDetector(
        key: ValueKey('world-${widget.world}'),
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () => Navigator.of(context).push(fadeRoute(LevelPickerScreen(world: widget.world))),
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/worlds/world_${widget.world}.png', height: widget.height),
              const SizedBox(height: 6),
              StarRow(count: widget.stars, size: widget.height * 0.16),
            ],
          ),
        ),
      ),
    );
  }
}
