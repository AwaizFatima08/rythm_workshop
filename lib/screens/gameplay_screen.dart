import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../game/layout.dart';
import '../game/workshop_game.dart';
import '../levels/level.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import 'reward_screen.dart';

/// Hosts the Flame game plus the hold-to-pause button and pause menu.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with WidgetsBindingObserver {
  late final AppServices _services = AppScope.read(context);
  late final WorkshopGame _game = WorkshopGame(
    level: widget.level,
    audio: _services.audio,
    settings: _services.settings,
    onComplete: _complete,
  );
  bool _paused = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services.session.startIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app pauses play and silences everything; the child comes
    // back to the pause menu rather than a moving belt.
    if (state != AppLifecycleState.resumed && !_done) {
      _services.audio.silenceAll();
      _setPaused(true);
    }
  }

  void _setPaused(bool p) {
    if (_paused == p || !mounted) return;
    _game.setPaused(p);
    setState(() => _paused = p);
  }

  Future<void> _complete(LevelResult result) async {
    if (_done || !mounted) return;
    _done = true;
    await _services.settings.setStars(result.level.id, 3);
    if (!mounted) return;
    final sessionOver = _services.session.isOver(_services.settings.sessionMinutes);
    Navigator.of(context).pushReplacement(fadeRoute(RewardScreen(result: result, sessionOver: sessionOver)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setPaused(true); // system back opens the pause menu
      },
      child: Scaffold(
        body: LayoutBuilder(builder: (context, c) {
          final pause = _pauseRect(Size(c.maxWidth, c.maxHeight));
          return Stack(
            children: [
              Positioned.fill(child: GameWidget(game: _game)),
              Positioned(
                left: pause.left,
                top: pause.top,
                child: HoldButton(
                  key: const ValueKey('pause'),
                  size: pause.width,
                  semanticLabel: 'Pause (hold)',
                  onHeld: () => _setPaused(true),
                  child: const Icon(Icons.pause_rounded, color: Palette.walnut, size: 36),
                ),
              ),
              if (_paused)
                Positioned.fill(
                  child: _PauseMenu(
                    onResume: () => _setPaused(false),
                    onHome: () => Navigator.of(context).pop(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Rect _pauseRect(Size s) =>
      WorkshopLayout(s, binCount: widget.level.bins.length, pattern: widget.level.isPattern).pauseRect;
}

class _PauseMenu extends StatelessWidget {
  const _PauseMenu({required this.onResume, required this.onHome});

  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ColoredBox(
      color: const Color(0xAA2A1F16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PictureButton(
              key: const ValueKey('pause-home'),
              size: (h * 0.26).clamp(80, 140),
              color: Palette.cream,
              semanticLabel: 'Leave level',
              onTap: onHome,
              child: Icon(Icons.home_rounded, color: Palette.walnut, size: (h * 0.16).clamp(48, 90)),
            ),
            SizedBox(width: h * 0.12),
            PictureButton(
              key: const ValueKey('pause-resume'),
              size: (h * 0.4).clamp(120, 200),
              color: Palette.green,
              semanticLabel: 'Keep playing',
              onTap: onResume,
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: (h * 0.28).clamp(80, 140)),
            ),
          ],
        ),
      ),
    );
  }
}
