# Testing Rhythm Workshop

## 1. Host tests (`flutter test`, 94 tests, ~20 s)

| File | Covers |
| --- | --- |
| `test/rules_test.dart` | Item queue (count, balance, never 3 of a bin in a row, no repeated picture) for every level; right/wrong/nowhere; streak climbs C5 D5 E5 G5 A5 C6 and wraps; speed-up after 5 in a row (max +30%) and reset after 2 wrong; wrong drops never cost progress; stars by thirds; pattern level never stalls (200 random children); `findTarget` magnetic margin and biggest-overlap rule |
| `test/beat_clock_test.dart` | Beat maths, signed offsets, time to next beat, beat tracker across the music loop point |
| `test/layout_test.dart` | 11 screen sizes (700×320, the Galaxy A12's 753×339, up to 2000×1200) × 2 bins / 3 bins / pattern: ≥64 dp controls, ≥86 dp toys, belt in the top half, nothing off screen or overlapping |
| `test/levels_and_assets_test.dart` | 12 levels / 4 worlds; level BPM = music BPM; practice taps only on levels 1, 4, 7; colour bins carry symbols; size/shape rules; every image and all 34 audio files exist (both languages) |
| `test/game_test.dart` | The real Flame game in a `GameWidget` with real pointer drags: toys arrive on the beat and loop round; correct drop counts and the chime waits for the beat; on-beat drop gets the bright chime and sparkles; wrong bin floats back with the soft note (and "try this one" after two tries); letting go on the belt glides back silently; second finger ignored; 24 dp grab margin; pause; pattern shelf rejects the wrong kind; colour_03, size_01, shape_02, food_02 and pattern_01 played to the end |
| `test/app_flow_test.dart` | Every child screen at 753×339 and 1280×800 with no overflow; welcome voice once; Play → worlds → levels → gameplay; quick tap on pause does nothing, 1 s hold opens the menu; Android Back opens the pause menu; gear needs long-press + gate; calm mode; reset progress keeps settings; stars on pickers; reward song, xylophone rests after 20 s, Next; session end → goodnight → Home; screen kept on through gameplay → reward → next level with no flicker, released on menus |
| `test/settings_gate_session_test.dart` | Settings defaults and persistence; session clock; parental gate (answers always 2 digits, closes after 3 wrong, fits the A12's 339 dp height) |

## 2. On-device test (`integration_test/app_test.dart`)

Runs the real app with the real `flutter_soloud` engine: splash loads all sounds; the music clock advances and the game's beats match the music position; Level 1 is played to the end with real drags; the reward screen saves 3 stars; Next opens Level 2; sending the app to the background freezes the music and returns to the pause menu; hold-to-pause; the pattern level is played to the end; the settings gate; every English and Urdu voice line, all six chimes and the lullaby load and play.

```bash
flutter build apk --debug -t integration_test/app_test.dart
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart --use-application-binary build/app/outputs/flutter-apk/app-debug.apk -d emulator-5590
```

On a real phone add `--dart-define=RW_REAL_DEVICE=true` to the build: the music clock must then stay within 1.5% of real time. Emulators without a host sound device drain audio slowly (70–97% of real time measured on this machine), so that check is relaxed there. This is harmless because the game reads the beat from the music, so sound and visuals stay together.

**Real-phone runs:** keep the screen awake for the whole run (e.g. `adb shell svc power stayon usb`, then turn it back off), because the menus deliberately let the phone sleep between tests. Wake the phone first with `adb shell input keyevent KEYCODE_WAKEUP`.

**Result 2026-09-25, Galaxy A12** (SM-A125F, Android 12, Helio P35, 753×339 dp; run by the device-testing session at commit 17a4d68 with `RW_REAL_DEVICE=true`): **3/3 passed**. The music clock was within 0.3% of real time (8034 vs 8010 ms, and −0.17% on a second run), with no steady drift.

**Result 2026-09-25** (emulator `rhythm_api35`, Android 15, 915×411 dp): **3/3 passed** (journey, settings/voices, harness). The music clock ran at 90–92% of real time on this emulator (no host sound device); the game's beats matched the music position exactly.

## 3. Release checks (done)

- `aapt2 dump permissions` on the release APK: **no `INTERNET` permission**.
- Target SDK 36, min SDK 24, signed with the upload key (`apksigner verify`).
- Release APK launched on the emulator: splash → Home in landscape, AAudio stream active (44.1 kHz stereo); cold start 4.2 s on the emulator (the debug build took ~15 s on the Galaxy A12, as expected for JIT).
- Galaxy A12 release APK: native first frame in 0.76–0.78 s, animated splash by 1.5 s (4.1 s on the very first launch after install, which is Android's one-time setup); no crashes.
- Keep-screen-on (found through the A12 run, where the screen timed out mid-level): the release build sets `FLAG_KEEP_SCREEN_ON` during gameplay, reward and goodnight and clears it on menus. Checked with `dumpsys window` on the emulator.

## 4. Owner checklist before release (needs a real phone and a child)

- [ ] Budget phone (the Galaxy A12): play 10 minutes by ear; the chimes still land on the beat by ear (no drift) and the belt stays smooth.
- [ ] Flight mode, fresh install: everything works on first launch.
- [ ] Listen to the Urdu voice lines with your child. If they sound unnatural, replace them (`docs/gemini-asset-requests.md`).
- [ ] Bluetooth speaker: if chimes feel late, try Settings → Audio delay.
- [ ] 3–5 children aged 3–6, a parent present: they can play Levels 1–3 without help.
