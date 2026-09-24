import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../game/workshop_game.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import 'common.dart';
import 'gameplay_screen.dart';
import 'goodnight_screen.dart';
import 'world_picker_screen.dart';

/// Colours of the six pentatonic notes (C5 D5 E5 G5 A5 C6), low to high.
const noteColours = [
  Palette.red, Color(0xFFEF6C00), Palette.yellow, Palette.green, Palette.blue, Color(0xFF6A1B9A), //
];

/// Characters dance while "the song you made" replays. Then big pictures for
/// "again" and "next", and a xylophone to play with for up to 20 seconds.
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key, required this.result, this.sessionOver = false});

  final LevelResult result;

  /// When the parent-set session time is up, go to the goodnight scene afterwards.
  final bool sessionOver;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  static const maxSongNotes = 16;
  static const playTime = Duration(seconds: 20);

  late final AppServices _services = AppScope.read(context);
  late final List<int> _song = widget.result.notes.length > maxSongNotes
      ? widget.result.notes.sublist(widget.result.notes.length - maxSongNotes)
      : widget.result.notes;
  final List<Timer> _timers = [];
  int _playing = -1;
  bool _dance = false;
  bool _replayDone = false;
  bool _xyloActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _replay());
  }

  void _after(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  /// Replays the child's notes, two per beat at the level's tempo.
  void _replay() {
    final stepMs = (30000 / widget.result.level.bpm).round();
    const startMs = 600;
    for (var i = 0; i < _song.length; i++) {
      _after(Duration(milliseconds: startMs + i * stepMs), () {
        _services.audio.playChime(_song[i]);
        setState(() {
          _playing = i;
          _dance = !_dance;
        });
      });
    }
    final end = startMs + _song.length * stepMs + 700;
    _after(Duration(milliseconds: end), () {
      setState(() {
        _playing = -1;
        _replayDone = true;
      });
      if (widget.sessionOver) {
        _after(const Duration(milliseconds: 1200), () {
          Navigator.of(context).pushReplacement(fadeRoute(const GoodnightScreen()));
        });
      } else {
        _services.audio.playVoice('vo_praise_02');
        setState(() => _xyloActive = true);
        _after(playTime, () => setState(() => _xyloActive = false));
      }
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _again() => Navigator.of(context).pushReplacement(fadeRoute(GameplayScreen(level: widget.result.level)));

  void _next() {
    final next = _services.levels.after(widget.result.level);
    Navigator.of(context).pushReplacement(
        fadeRoute(next == null ? const WorldPickerScreen() : GameplayScreen(level: next)));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final showButtons = _replayDone && !widget.sessionOver;
    return Scaffold(
      body: WorkshopBackground(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: h * 0.04,
              child: _SongRow(notes: _song, playing: _playing, dot: (h * 0.07).clamp(18, 40)),
            ),
            Align(
              alignment: const Alignment(0, 0.35),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedRotation(
                    turns: _dance ? 0.02 : -0.02,
                    duration: const Duration(milliseconds: 180),
                    child: character(_dance ? 'milo_celebrate' : 'milo_hit_left', height: h * 0.42),
                  ),
                  SizedBox(width: h * 0.08),
                  AnimatedRotation(
                    turns: _dance ? -0.03 : 0.03,
                    duration: const Duration(milliseconds: 180),
                    child: character(_dance ? 'pip_dance' : 'pip_clap', height: h * 0.44),
                  ),
                ],
              ),
            ),
            if (showButtons) ...[
              Positioned(
                left: 16,
                top: h * 0.3,
                child: PictureButton(
                  key: const ValueKey('again'),
                  size: (h * 0.26).clamp(88, 150),
                  color: Palette.cream,
                  semanticLabel: 'Play again',
                  onTap: _again,
                  child: Icon(Icons.replay_rounded, color: Palette.walnut, size: (h * 0.17).clamp(56, 96)),
                ),
              ),
              Positioned(
                right: 16,
                top: h * 0.3,
                child: PictureButton(
                  key: const ValueKey('next'),
                  size: (h * 0.3).clamp(96, 170),
                  color: Palette.green,
                  semanticLabel: 'Next',
                  onTap: _next,
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: (h * 0.2).clamp(64, 110)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: _Xylophone(
                  active: _xyloActive,
                  height: (h * 0.2).clamp(64, 120),
                  onNote: (i) => _services.audio.playChime(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({required this.notes, required this.playing, required this.dot});

  final List<int> notes;
  final int playing;
  final double dot;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < notes.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.fromLTRB(3, i == playing ? 0 : dot * 0.3 + (5 - notes[i]) * 2, 3, 0),
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: noteColours[notes[i]].withValues(alpha: i <= playing || playing < 0 ? 1 : 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Palette.walnut, width: 3),
              ),
            ),
        ],
      );
}

/// Six xylophone bars (low to high). Optional fun; it rests after 20 s.
class _Xylophone extends StatelessWidget {
  const _Xylophone({required this.active, required this.height, required this.onNote});

  final bool active;
  final double height;
  final void Function(int note) onNote;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: active ? 1 : 0.35,
        duration: const Duration(milliseconds: 600),
        child: IgnorePointer(
          ignoring: !active,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 6; i++)
                GestureDetector(
                  key: ValueKey('xylo-$i'),
                  onTapDown: (_) => onNote(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: kMinTouch + 4,
                    height: height * (1 - i * 0.08),
                    decoration: BoxDecoration(
                      color: noteColours[i],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Palette.walnut, width: 4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
