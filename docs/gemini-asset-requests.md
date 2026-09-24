# Optional Gemini upgrades (manual, from your own account)

The app is complete without Gemini: every image, sound and voice line was generated locally.
This page is only for upgrades you may want before or after release. Claude does not call Gemini;
you generate the files in your own account and drop them into the folders below.

## 1. Voice lines (recommended check: Urdu)

The draft Urdu voice is Kokoro's Hindi voice reading a Devanagari transliteration. It is clear, but
listen with your child first (design doc, "Voices"). If it sounds flat or unnatural, replace it.

**In Google AI Studio** (aistudio.google.com → *Generate speech*):

1. Model: the current Gemini TTS model (e.g. *Gemini 2.5 Flash Preview TTS*). Mode: single speaker.
2. Voice: a warm, friendly voice (e.g. *Leda* or *Aoede*). Use the same voice for every line.
3. Style instructions (paste into the style box):
   > Speak warmly and slowly to a 4-year-old child, like a kind kindergarten teacher. Cheerful, gentle, clear. Pakistani Urdu pronunciation.
   (For English: *... clear, friendly English for young children.*)
4. Paste one line at a time from the table, press Run, and download the WAV.
5. Save it as `art/voice_in/ur/<file>.wav` (or `art/voice_in/en/<file>.wav`), using the exact file name.

| File | English | Urdu |
| --- | --- | --- |
| `vo_welcome` | Welcome to the workshop! Let's sort to the music! | ورکشاپ میں خوش آمدید! آئیے موسیقی کے ساتھ چیزیں الگ کریں! |
| `vo_prompt_colour` | Red toys in the red box! | لال کھلونے لال ڈبے میں! |
| `vo_prompt_size` | Big ones here, small ones there! | بڑے یہاں، چھوٹے وہاں! |
| `vo_prompt_shape` | Circles here, squares there! | گول یہاں، چوکور وہاں! |
| `vo_prompt_food` | Fruits here, vegetables there! | پھل یہاں، سبزیاں وہاں! |
| `vo_prompt_pattern` | Fruit, vegetable, fruit... what comes next? | پھل، سبزی، پھل... آگے کیا آئے گا؟ |
| `vo_try_here` | Try this one! | یہاں ڈالیں! |
| `vo_praise_01` | Great rhythm! | شاباش! بہت خوب! |
| `vo_praise_02` | Super sorting! | زبردست! |
| `vo_goodnight` | The workshop is sleeping now. See you soon! | ورکشاپ اب سو رہی ہے۔ پھر ملیں گے! |

Then import them (trims silence, levels to -14 LUFS, encodes OGG, replaces the drafts):

```bash
cd /mnt/storage/projects/rythm_workshop && ~/tools/venvs/rhythm/bin/python scripts/import_voice.py
```

Upload the WAVs anywhere you like (e.g. the project's Google Drive folder) and tell Claude; it will run the
import, rebuild and retest. A family member reading the same lines into a phone recorder works the same way
(save as WAV).

## 2. Art (optional; current art is complete)

Only if you want a painted look. Keep the **exact file name and pixel size**, transparent background (PNG),
and the same pose so the game still reads. Style line to prefix every prompt:

> Flat, friendly children's-book vector illustration, thick dark-brown (#4A3728) outlines, soft shading, no text, transparent background, centred, full body visible.

| File (in `assets/images/`) | Size (px) | Prompt after the style line |
| --- | --- | --- |
| `characters/pip_idle.png` | 440 × 396 | A round navy-blue baby penguin with a cream belly, orange beak and feet, pink cheeks, standing, wings relaxed at its sides, facing the viewer |
| `characters/pip_wave.png` | 440 × 396 | The same penguin waving its right wing high, eyes happily closed |
| `characters/pip_clap.png` | 440 × 396 | The same penguin clapping both wings in front of its belly, eyes happily closed |
| `characters/pip_point.png` | 440 × 396 | The same penguin pointing its right wing straight out to the right, curious open eyes |
| `characters/pip_hmm.png` | 440 × 396 | The same penguin tilting its head slightly, left wing to its chin, thinking, friendly (never sad) |
| `characters/pip_dance.png` | 440 × 396 | The same penguin dancing with both wings raised, eyes happily closed |
| `characters/pip_sleep.png` | 440 × 396 | The same penguin asleep standing up, eyes closed, two small "z" shapes |
| `characters/milo_idle.png` | 384 × 408 | A cheerful brown baby monkey with a peach face sitting behind two small bongo drums (red band left, blue band right), hands resting on the drums |
| `characters/milo_hit_left.png` | 384 × 408 | The same monkey striking the left drum, right hand raised |
| `characters/milo_hit_right.png` | 384 × 408 | The same monkey striking the right drum, left hand raised |
| `characters/milo_celebrate.png` | 384 × 408 | The same monkey with both arms up, mouth open in a happy cheer |
| `ui/background.png` | 1600 × 900, **opaque** | A calm, warm wooden toy workshop wall (cream planks), two small shelves with toys at the far left and right, a small window in the middle, light wood floor in the bottom fifth. Low contrast, nothing in the middle third (the game draws there) |

Toys, bins and world cards carry the colour-plus-symbol rule (design D6); if you regenerate any, keep the
symbol badge (red ●, blue ■, yellow ★, green ▲) visible. After replacing images, tell Claude to rebuild and retest.
