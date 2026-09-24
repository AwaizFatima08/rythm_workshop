import 'package:flutter/material.dart';

import '../app.dart';
import '../levels/level.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import 'common.dart';
import 'gameplay_screen.dart';

/// Three cards per world. Each card shows its bins as pictures, dots for the
/// level number, and a star once finished. Every level is open from the start.
class LevelPickerScreen extends StatelessWidget {
  const LevelPickerScreen({super.key, required this.world});

  final int world;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final levels = services.levels.world(world);
    final h = MediaQuery.sizeOf(context).height;
    final cardH = (h * 0.55).clamp(160.0, 340.0);
    return Scaffold(
      body: WorkshopBackground(
        child: Stack(
          children: [
            const Positioned(top: 8, left: 12, child: BackArrowButton()),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(84, 16, 16, 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < levels.length; i++)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: LevelCard(
                            level: levels[i],
                            number: i + 1,
                            height: cardH,
                            done: services.settings.stars(levels[i].id) > 0,
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

class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level, required this.number, required this.height, required this.done});

  final Level level;
  final int number;
  final double height;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final binImages = level.isPattern
        ? [for (final b in [...level.pattern, level.pattern.first]) level.bin(b).image]
        : [for (final b in level.bins) b.image];
    final w = height * 1.05;
    return PictureCard(
      key: ValueKey('level-${level.id}'),
      semanticLabel: 'Level $number',
      onTap: () => Navigator.of(context).push(fadeRoute(GameplayScreen(level: level))),
      child: Container(
        width: w,
        height: height,
        padding: EdgeInsets.all(height * 0.06),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Palette.walnut, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < number; i++)
                  Container(
                    margin: const EdgeInsets.all(3),
                    width: height * 0.07,
                    height: height * 0.07,
                    decoration: const BoxDecoration(color: Palette.walnut, shape: BoxShape.circle),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    for (final img in binImages)
                      Image.asset('assets/images/$img', width: (w * 0.86) / binImages.length.clamp(2, 3)),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: height * 0.2,
              child: done
                  ? Icon(Icons.star_rounded,
                      size: height * 0.2,
                      color: Palette.yellow,
                      shadows: const [Shadow(color: Palette.walnut, blurRadius: 2)])
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable picture that squashes a little when pressed.
class PictureCard extends StatefulWidget {
  const PictureCard({super.key, required this.onTap, required this.child, this.semanticLabel});

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<PictureCard> createState() => _PictureCardState();
}

class _PictureCardState extends State<PictureCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(scale: _down ? 0.94 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
        ),
      );
}
