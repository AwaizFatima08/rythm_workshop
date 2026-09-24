import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import 'common.dart';
import 'home_screen.dart';

/// Workshop doors open (about 2.5 s) while all sounds and levels load. No tap needed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _doors =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final services = AppScope.read(context);
    final minTime = Future<void>.delayed(const Duration(milliseconds: 2600));
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _doors.forward();
    });
    await Future.wait([
      services.audio.init(),
      services.levels.load(),
      for (final f in ['ui/background.png', 'characters/pip_wave.png', 'characters/pip_idle.png'])
        precacheImage(AssetImage('assets/images/$f'), context),
    ]);
    await minTime;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  void dispose() {
    _doors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorkshopBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: FractionallySizedBox(heightFactor: 0.55, child: character('pip_wave'))),
            AnimatedBuilder(
              animation: _doors,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_doors.value);
                return LayoutBuilder(
                  builder: (context, c) {
                    final half = c.maxWidth / 2;
                    return Stack(children: [
                      Positioned(left: -half * t, top: 0, bottom: 0, width: half, child: const _Door(left: true)),
                      Positioned(right: -half * t, top: 0, bottom: 0, width: half, child: const _Door(left: false)),
                    ]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({required this.left});

  final bool left;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DoorPainter(left));
}

class _DoorPainter extends CustomPainter {
  _DoorPainter(this.left);

  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Palette.walnut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.wood);
    final planks = size.width / 4;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(planks * i, 0), Offset(planks * i, size.height),
          Paint()..color = Palette.woodDark..strokeWidth = 4);
    }
    for (final y in [size.height * 0.2, size.height * 0.8]) {
      canvas.drawRect(Rect.fromLTWH(0, y - 14, size.width, 28), Paint()..color = Palette.woodDark);
      canvas.drawRect(Rect.fromLTWH(0, y - 14, size.width, 28), outline);
    }
    canvas.drawRect(Offset.zero & size, outline);
    final knob = Offset(left ? size.width - 36 : 36, size.height / 2);
    canvas.drawCircle(knob, 16, Paint()..color = Palette.amber);
    canvas.drawCircle(knob, 16, outline..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_DoorPainter old) => false;
}
