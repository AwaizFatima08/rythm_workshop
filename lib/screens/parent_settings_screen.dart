import 'package:flutter/material.dart';

import '../app.dart';
import '../settings/game_settings.dart';
import '../theme.dart';

/// Shown in Settings as plain text (no web link, so no extra gate is needed).
const privacyPolicyText = '''
Rhythm Workshop collects no personal information and does not connect to the internet.

• No accounts, no ads, no in-app purchases, no analytics, no tracking.
• The app has no internet permission, so it cannot send anything anywhere.
• Stars and these settings are stored only on this device. "Reset progress" below deletes the stars; uninstalling the app removes everything.

Published by HomiLabs Solutions. Questions: info@homilabs.org''';

const appVersion = '1.0.0';

/// Grown-up settings, reached only through the parental gate. Plain text is fine here.
class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final s = services.settings;
    const title = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Palette.walnut);
    const note = TextStyle(fontSize: 14, color: Palette.walnut);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent settings'),
        backgroundColor: Palette.cream,
        foregroundColor: Palette.walnut,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const Text('Voice language', style: title),
            const SizedBox(height: 8),
            SegmentedButton<VoiceLanguage>(
              segments: const [
                ButtonSegment(value: VoiceLanguage.en, label: Text('English')),
                ButtonSegment(value: VoiceLanguage.ur, label: Text('اردو  Urdu')),
              ],
              selected: {s.language},
              onSelectionChanged: (v) {
                s.language = v.first;
                services.audio.playVoice('vo_praise_01');
              },
            ),
            const Divider(height: 32),
            const Text('Music volume', style: title),
            Slider(
              key: const ValueKey('music-volume'),
              value: s.musicVolume,
              onChanged: (v) => s.musicVolume = v,
            ),
            const Text('Voice and sounds volume', style: title),
            Slider(
              value: s.effectsVolume,
              onChanged: (v) => s.effectsVolume = v,
              onChangeEnd: (_) => services.audio.playChime(2),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gentle vibration on a correct sort', style: title),
              value: s.haptics,
              onChanged: (v) => s.haptics = v,
            ),
            SwitchListTile(
              key: const ValueKey('calm-mode'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Calm mode', style: title),
              subtitle: const Text('Softer colours, slower belt and quieter music, for children with sensory sensitivity.',
                  style: note),
              value: s.calmMode,
              onChanged: (v) => s.calmMode = v,
            ),
            const Divider(height: 32),
            const Text('Session length', style: title),
            const Text('When time is up, the current level finishes, then a goodnight scene plays.', style: note),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in GameSettings.sessionChoices)
                  ChoiceChip(
                    label: Text(m == 0 ? 'No limit' : '$m min'),
                    selected: s.sessionMinutes == m,
                    onSelected: (_) => s.sessionMinutes = m,
                  ),
              ],
            ),
            const Divider(height: 32),
            Text('Audio delay: ${s.latencyMs} ms', style: title),
            const Text(
                'If chimes seem to land after the beat on this device (common with Bluetooth speakers), raise this until they feel on time.',
                style: note),
            Slider(
              value: s.latencyMs.toDouble(),
              min: 0,
              max: 250,
              divisions: 25,
              label: '${s.latencyMs} ms',
              onChanged: (v) => s.latencyMs = v.round(),
            ),
            const Divider(height: 32),
            const Text('Keep your child in the app', style: title),
            const Text(
                'Android cannot let an app block the Home or Back gestures. Use screen pinning instead: '
                'Settings → Security → App pinning (or "Pin app"), turn it on, then open Recent apps, '
                'tap the Rhythm Workshop icon and choose Pin. To unpin, hold Back and Recents together '
                '(or swipe up and hold).',
                style: note),
            const Divider(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('reset-progress'),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset progress (stars)'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Reset progress?'),
                      content: const Text('This removes all stars. Settings stay the same.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (ok == true) await s.resetProgress();
                },
              ),
            ),
            const Divider(height: 32),
            const Text('Privacy policy', style: title),
            const SizedBox(height: 6),
            const Text(privacyPolicyText, style: note),
            const SizedBox(height: 24),
            const Text('Rhythm Workshop $appVersion · HomiLabs Solutions', style: note),
          ],
        ),
      ),
    );
  }
}
