#!/usr/bin/env python3
"""Import replacement voice recordings (from Gemini AI Studio or a family recording).

Put WAV files named like the app's lines into art/voice_in/en/ or art/voice_in/ur/
(e.g. art/voice_in/ur/vo_welcome.wav), then run:
    ~/tools/venvs/rhythm/bin/python scripts/import_voice.py
Each file is trimmed, levelled to -14 LUFS, resampled to 44.1 kHz and written to
assets/audio/vo/<lang>/<id>.ogg, replacing the draft. Unknown names are skipped.
"""
import json
import pathlib

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

from audio_lib import AUDIO, ROOT, SR, write
from make_voice import compress, trim

HERE = pathlib.Path(__file__).resolve().parent
IN = ROOT / "art" / "voice_in"


def main():
    known = set(json.loads((HERE / "voice_lines.json").read_text())["lines"])
    done = 0
    for lang in ("en", "ur"):
        for f in sorted((IN / lang).glob("*.wav")):
            if f.stem not in known:
                print(f"skip {f.name}: not a known line id")
                continue
            y, sr = sf.read(str(f), always_2d=True)
            y = trim(y.mean(axis=1), sr)
            if sr != SR:
                y = resample_poly(y, SR, sr)
            y = compress(y / np.abs(y).max(), SR)
            y = np.tanh(2.2 * y / np.abs(y).max())  # same chain as make_voice.py
            l, pk = write(AUDIO / "vo" / lang / f"{f.stem}.ogg", y, -14, "OGG")
            print(f"{lang}/{f.stem}: {len(y) / SR:.2f}s {l:.1f} LUFS")
            done += 1
    print(f"imported {done} file(s)")


if __name__ == "__main__":
    main()
