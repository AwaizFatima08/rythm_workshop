# Licences for Rhythm Workshop assets

Everything the app ships was either made for this project or comes from an openly licensed source.
No track, sound or image uses an "NC" (non-commercial) or "ND" (no-derivatives) licence.

| Asset | Source | Licence |
| --- | --- | --- |
| Music: `bgm_calm`, `bgm_workshop_01`, `bgm_workshop_02`, `bgm_goodnight` | Composed and synthesised for this app by `scripts/make_audio.py` | Owned by HomiLabs Solutions |
| Sound effects: `assets/audio/sfx/*`, `assets/audio/perc/*` | Synthesised by `scripts/make_audio.py` | Owned by HomiLabs Solutions |
| Voice lines: `assets/audio/vo/en/*`, `assets/audio/vo/ur/*` (draft) | Generated offline by `scripts/make_voice.py` with the Kokoro-82M model ([hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M)) via [kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx) | Model weights Apache-2.0; generated audio owned by HomiLabs Solutions |
| All images: characters, toys, bins, background, world cards, icon, feature graphic | Drawn as SVG by `scripts/make_art.py` and `scripts/make_store_assets.py` | Owned by HomiLabs Solutions |
| Font: Andika (`assets/fonts/`) | SIL International | SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) |
| Code libraries: Flutter, Flame, flutter_soloud (SoLoud), shared_preferences | pub.dev | BSD-3 / MIT / zlib; Flutter shows all package licences via `LicenseRegistry` |

If voice lines are later replaced (Gemini, or a family recording), add a row here with the source and terms.
