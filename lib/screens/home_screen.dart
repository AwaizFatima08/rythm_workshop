import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/parental_gate.dart';
import 'common.dart';
import 'parent_settings_screen.dart';
import 'world_picker_screen.dart';

/// One huge Play button with Pip waving. The faded gear needs a long-press
/// and the parental gate, so children rarely find Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _wave;
  bool _up = true;

  @override
  void initState() {
    super.initState();
    _wave = Timer.periodic(const Duration(milliseconds: 700), (_) => setState(() => _up = !_up));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = AppScope.read(context).session;
      if (!s.welcomed) {
        s.welcomed = true;
        AppScope.read(context).audio.playVoice('vo_welcome');
      }
    });
  }

  @override
  void dispose() {
    _wave?.cancel();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final ok = await ParentalGate.show(context);
    if (ok && mounted) await Navigator.of(context).push(fadeRoute(const ParentSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: WorkshopBackground(
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  character(_up ? 'pip_wave' : 'pip_idle', height: h * 0.55),
                  SizedBox(width: h * 0.06),
                  Padding(
                    padding: EdgeInsets.only(bottom: h * 0.12),
                    child: PictureButton(
                      key: const ValueKey('play'),
                      size: (h * 0.42).clamp(140, 240),
                      color: Palette.green,
                      semanticLabel: 'Play',
                      onTap: () => Navigator.of(context).push(fadeRoute(const WorldPickerScreen())),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: (h * 0.3).clamp(100, 170)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                key: const ValueKey('settings-gear'),
                behavior: HitTestBehavior.opaque,
                onLongPress: _openSettings,
                child: const SizedBox(
                  width: kMinTouch,
                  height: kMinTouch,
                  child: Icon(Icons.settings, color: Palette.faded, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
