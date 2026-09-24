import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/audio_engine.dart';
import 'levels/level.dart';
import 'screens/splash_screen.dart';
import 'settings/game_settings.dart';
import 'theme.dart';

/// Tracks play time so the session can end gently at the parent-set length.
class SessionClock {
  SessionClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _start;
  bool welcomed = false;

  void startIfNeeded() => _start ??= _now();

  Duration get elapsed => _start == null ? Duration.zero : _now().difference(_start!);

  bool isOver(int minutes) => minutes > 0 && _start != null && elapsed >= Duration(minutes: minutes);

  /// After the goodnight scene a new session begins with the next Play.
  void reset() {
    _start = null;
    welcomed = false;
  }
}

class AppServices {
  AppServices({required this.settings, required this.audio, LevelRepository? levels, SessionClock? session})
      : levels = levels ?? LevelRepository(),
        session = session ?? SessionClock();

  final GameSettings settings;
  final AudioEngine audio;
  final LevelRepository levels;
  final SessionClock session;
}

class AppScope extends InheritedNotifier<GameSettings> {
  AppScope({super.key, required this.services, required super.child}) : super(notifier: services.settings);

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  static AppServices read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).services;
}

class RhythmWorkshopApp extends StatefulWidget {
  const RhythmWorkshopApp({super.key, required this.services, this.home});

  final AppServices services;

  /// Replaces the splash screen (tests only).
  final Widget? home;

  @override
  State<RhythmWorkshopApp> createState() => _RhythmWorkshopAppState();
}

class _RhythmWorkshopAppState extends State<RhythmWorkshopApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Android can drop immersive mode while the app is away.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp(
        title: 'Rhythm Workshop',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) {
          final calm = AppScope.of(context).settings.calmMode;
          return calm ? ColorFiltered(colorFilter: calmFilter, child: child!) : child!;
        },
        home: widget.home ?? const SplashScreen(),
      ),
    );
  }
}

/// Gentle fade between screens (no sliding, no flashing).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );
