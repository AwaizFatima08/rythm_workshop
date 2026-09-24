import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceLanguage { en, ur }

/// Everything the app remembers, stored on the device only (shared_preferences).
/// Parent settings plus stars per level. "Reset progress" wipes the stars.
class GameSettings extends ChangeNotifier {
  GameSettings._(this._prefs);

  final SharedPreferences _prefs;

  static const sessionChoices = [3, 6, 10, 15, 0]; // 0 = no limit

  static Future<GameSettings> load() async =>
      GameSettings._(await SharedPreferences.getInstance());

  VoiceLanguage get language =>
      _prefs.getString('language') == 'ur' ? VoiceLanguage.ur : VoiceLanguage.en;
  set language(VoiceLanguage v) => _set(() => _prefs.setString('language', v.name));

  /// 0..1 for background music.
  double get musicVolume => _prefs.getDouble('musicVolume') ?? 0.7;
  set musicVolume(double v) => _set(() => _prefs.setDouble('musicVolume', v.clamp(0, 1)));

  /// 0..1 for voice and sound effects.
  double get effectsVolume => _prefs.getDouble('effectsVolume') ?? 0.9;
  set effectsVolume(double v) => _set(() => _prefs.setDouble('effectsVolume', v.clamp(0, 1)));

  bool get haptics => _prefs.getBool('haptics') ?? true;
  set haptics(bool v) => _set(() => _prefs.setBool('haptics', v));

  bool get calmMode => _prefs.getBool('calmMode') ?? false;
  set calmMode(bool v) => _set(() => _prefs.setBool('calmMode', v));

  /// Session length in minutes; 0 means no limit.
  int get sessionMinutes => _prefs.getInt('sessionMinutes') ?? 6;
  set sessionMinutes(int v) => _set(() => _prefs.setInt('sessionMinutes', v));

  /// Extra audio output delay of this device, in ms (0-250).
  int get latencyMs => _prefs.getInt('latencyMs') ?? 0;
  set latencyMs(int v) => _set(() => _prefs.setInt('latencyMs', v.clamp(0, 250)));

  int stars(String levelId) => _prefs.getInt('stars.$levelId') ?? 0;

  Future<void> setStars(String levelId, int value) async {
    if (value <= stars(levelId)) return;
    await _prefs.setInt('stars.$levelId', value);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith('stars.')).toList()) {
      await _prefs.remove(k);
    }
    notifyListeners();
  }

  void _set(Future<bool> Function() write) {
    write();
    notifyListeners();
  }
}
