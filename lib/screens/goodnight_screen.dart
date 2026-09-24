import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../game/effects.dart';
import 'common.dart';

/// Session end: the workshop gets dark, Pip sleeps, a music-box lullaby plays
/// once, then back to Home. It never interrupts a level.
class GoodnightScreen extends StatefulWidget {
  const GoodnightScreen({super.key});

  static const length = Duration(seconds: 14);

  @override
  State<GoodnightScreen> createState() => _GoodnightScreenState();
}

class _GoodnightScreenState extends State<GoodnightScreen> with SingleTickerProviderStateMixin {
  late final AppServices _services = AppScope.read(context);
  late final AnimationController _dark =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _services.audio.startMusic('bgm_goodnight.ogg', loop: false);
      _timers.add(Timer(const Duration(milliseconds: 1500), () => _services.audio.playVoice('vo_goodnight')));
      _timers.add(Timer(GoodnightScreen.length, _goHome));
    });
  }

  void _goHome() {
    if (!mounted) return;
    _services.audio.stopMusic();
    _services.session.reset();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _dark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _dark,
          builder: (context, child) => WorkshopBackground(
            dim: 0.7 * _dark.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: _dark.value, child: const CustomPaint(painter: _NightSky())),
                Align(alignment: const Alignment(0, 0.6), child: character('pip_sleep', height: h * 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NightSky extends CustomPainter {
  const _NightSky();

  @override
  void paint(Canvas canvas, Size size) {
    final moon = Offset(size.width * 0.82, size.height * 0.2);
    final r = size.height * 0.1;
    canvas.drawCircle(moon, r, Paint()..color = const Color(0xFFFFF1B8));
    canvas.drawCircle(moon + Offset(r * 0.45, -r * 0.2), r * 0.85, Paint()..color = const Color(0xFF2A3355));
    final rand = Random(7);
    final star = Paint()..color = const Color(0xFFFFE9A0);
    for (var i = 0; i < 14; i++) {
      final c = Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height * 0.45);
      final s = size.height * (0.012 + rand.nextDouble() * 0.014);
      canvas.drawPath(starPath(c, s, s * 0.45), star);
    }
  }

  @override
  bool shouldRepaint(_NightSky old) => false;
}
