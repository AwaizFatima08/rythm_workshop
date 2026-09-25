import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps the screen on while at least one [KeepAwake] is mounted.
///
/// A child can watch the belt or the reward song without touching the screen
/// for longer than the phone's screen timeout. Menus don't keep it on, so a
/// forgotten phone still goes to sleep.
class KeepAwake extends StatefulWidget {
  const KeepAwake({super.key, required this.child});

  final Widget child;

  static const _channel = MethodChannel('rhythm_workshop/screen');

  /// Screens hand over to each other (the next one mounts before the old one
  /// is disposed), so count holders instead of toggling.
  static int _holders = 0;

  @visibleForTesting
  static int get holders => _holders;

  static void _set(bool on) {
    _channel.invokeMethod<void>('keepOn', on).catchError((Object _) {}); // absent in tests
  }

  @override
  State<KeepAwake> createState() => _KeepAwakeState();
}

class _KeepAwakeState extends State<KeepAwake> {
  @override
  void initState() {
    super.initState();
    if (KeepAwake._holders++ == 0) KeepAwake._set(true);
  }

  @override
  void dispose() {
    if (--KeepAwake._holders == 0) KeepAwake._set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
