# Rhythm Workshop — Build decisions (v1)

Source design: `docs/design-document-v0.md` (reviewed design, Sep 24 2026).
On 2026-09-25 the owner asked for a from-scratch build to Play-ready state with all
permissions granted upfront, so every "Proposed" decision in the design is now **locked**.
Where this file and the design document disagree, **this file wins**.

## 0. Locked decisions

| # | Decision | Locked choice |
| --- | --- | --- |
| D1 | Name | **Rhythm Workshop**. Package `com.homilabs.rhythmworkshop` (never change after first Play upload). |
| D2 | Backend | None. 12 levels ship as JSON in `assets/levels/`. |
| D3 | Analytics | None. No `INTERNET` permission in the release manifest. |
| D4 | Rhythm rule | Auto-quantise. A correct drop always counts; the chime waits for the next beat. |
| D5 | Wrong bin | Toy floats back to the belt with a soft F3 note; belt never stops. |
| D6 | Colour sorting | Every colour bin and toy carries a shape symbol (red ● · blue ■ · yellow ★ · green ▲). |
| D7 | Audio | `flutter_soloud` only. |
| D8 | State | Flame components + one `ChangeNotifier` (`GameSettings`). |
| D9 | Session | Ends after 6 min by default (parent: 3 / 6 / 10 / 15 / off); level in progress always finishes first. |
| D10 | Parental gate | Guards Settings only (multiplication 6–9 × 5–9, own keypad, 3 tries). |
| D11 | Languages | English + Urdu voice, chosen in Settings. No on-screen text for children. |

## 1. Build-time choices (made during implementation)

- **Art is generated locally.** Every image is an SVG written by `scripts/make_art.py` and rendered to PNG by Inkscape. No Gemini. If the owner later wants richer art, `docs/gemini-asset-requests.md` lists a prompt per file; a PNG with the same name and size drops straight in.
- **Music and sound effects are synthesised locally** by `scripts/make_audio.py` (numpy). All music is in C major, loops are whole bars, and loudness is measured with ITU-R BS.1770 (music −20 LUFS, effects −16, voice −14). Because we generate them ourselves, there are no third-party music licences; `LICENSES.md` records this.
- **Voice is generated offline** with Kokoro-82M (Apache-2.0 weights) via `scripts/make_voice.py`. English uses an American female voice; Urdu lines are written in Devanagari transliteration and spoken by Kokoro's Hindi voice, because spoken Urdu and Hindi share their sounds. These are **draft voices**: before release, listen with a child (design §Risks). Replacement options are in `docs/gemini-asset-requests.md` (manual Gemini commands) or a family recording with the same scripts.
- **Extra voice line** `vo_prompt_pattern` ("What comes next?") for the pattern level, which the design's table did not cover.
- **Level 12 (AB pattern)** uses a pattern shelf instead of two bins: fruit, vegetable, fruit … the next empty slot glows and accepts only the item that continues the pattern. Wrong items float back the same as a wrong bin.
- **Level BPM always equals the music's BPM** (the beat clock reads the music position), so world 2 uses 70 and 80 BPM tracks rather than 75.
- **Stars:** the gameplay star meter fills at one-third, two-thirds and all sorted. A finished level always saves 3 stars; there are no scores.
- **Reward xylophone:** six tappable bars (the pentatonic notes), active for 20 s, then they rest.
- **Audio latency** slider (0–250 ms) in Settings shifts when on-beat is judged and when quantised chimes play.
- **Privacy policy** is hosted with GitHub Pages from this public repo (same pattern as VisionCheck):
  `https://awaizfatima08.github.io/rythm_workshop/privacy-policy.html`. Contact email `info@homilabs.org`; change it in `docs/privacy-policy.html` if needed.
- **Minimum Android version:** API 24 (Android 7.0), required by current Flutter.
