#!/usr/bin/env python3
"""Draft voice lines, generated offline with Kokoro-82M (Apache-2.0).

English: voice af_heart. Urdu: the Devanagari form of each line (voice_lines.json,
'ur_tts') read by the Hindi voice hf_alpha. Output: assets/audio/vo/{en,ur}/<id>.ogg at -14 LUFS.

Needs ~/tools/kokoro/kokoro-v1.0.onnx and voices-v1.0.bin (see CLAUDE.md).
Run:  ~/tools/venvs/rhythm/bin/python scripts/make_voice.py
"""
import json
import pathlib

import numpy as np
from kokoro_onnx import Kokoro
from scipy.signal import resample_poly

from audio_lib import AUDIO, SR, write

HERE = pathlib.Path(__file__).resolve().parent
MODEL = pathlib.Path.home() / "tools" / "kokoro"
VOICES = {"en": ("af_heart", "en-us", "en", 0.92), "ur": ("hf_alpha", "hi", "ur_tts", 0.88)}


def trim(y, sr, thresh=0.01, pad=0.06):
    idx = np.where(np.abs(y) > thresh * np.abs(y).max())[0]
    a, b = max(0, idx[0] - int(pad * sr)), min(len(y), idx[-1] + int(pad * sr))
    y = y[a:b].copy()
    f = int(0.008 * sr)
    y[:f] *= np.linspace(0, 1, f)
    y[-f:] *= np.linspace(1, 0, f)
    return y


def compress(y, sr, thresh_db=-24.0, ratio=3.0):
    """Gentle compressor (5 ms attack, 80 ms release) so speech reaches -14 LUFS without clipping."""
    from scipy.signal import lfilter
    level = np.abs(y)
    att, rel = np.exp(-1 / (0.005 * sr)), np.exp(-1 / (0.08 * sr))
    env = lfilter([1 - rel], [1, -rel], level)  # release-shaped follower
    env = np.maximum(env, lfilter([1 - att], [1, -att], level))
    db = 20 * np.log10(env + 1e-9)
    gain_db = np.minimum(0, (thresh_db - db) * (1 - 1 / ratio))
    return y * 10 ** (gain_db / 20)


def main():
    lines = json.loads((HERE / "voice_lines.json").read_text())["lines"]
    k = Kokoro(str(MODEL / "kokoro-v1.0.onnx"), str(MODEL / "voices-v1.0.bin"))
    for lang, (voice, code, field, speed) in VOICES.items():
        for vid, text in lines.items():
            samples, sr = k.create(text[field], voice=voice, speed=speed, lang=code)
            y = trim(np.asarray(samples, dtype=np.float64), sr)
            y = compress(y / np.abs(y).max(), sr)
            y = np.tanh(2.2 * y / np.abs(y).max())  # soft saturation lowers the crest factor
            y = resample_poly(y, SR, sr)  # 24 kHz -> 44.1 kHz, matching the audio engine
            l, pk = write(AUDIO / "vo" / lang / f"{vid}.ogg", y, -14, "OGG")
            print(f"{lang}/{vid}: {len(y) / SR:.2f}s {l:.1f} LUFS peak {pk:.1f}")


if __name__ == "__main__":
    main()
