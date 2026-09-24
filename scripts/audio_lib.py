"""Shared helpers for the audio scripts: synth voices, BS.1770 loudness and file output."""
import pathlib

import numpy as np
import soundfile as sf
from scipy.signal import lfilter

SR = 44100
ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO = ROOT / "assets" / "audio"


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def env(n, attack=0.006, decay=None, release=0.0):
    """Soft-attack envelope; every sound in the app starts with a 5-10 ms fade-in."""
    t = np.arange(n) / SR
    a = np.minimum(1.0, t / max(attack, 1e-4))
    d = np.exp(-t / decay) if decay else np.ones(n)
    y = a * d
    if release:
        r = min(n, int(release * SR))
        y[n - r:] *= np.linspace(1, 0, r)
    return y


def partials(freq, dur, spec, attack=0.006):
    """Sum of (ratio, amplitude, decay-seconds) partials."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for ratio, amp, decay in spec:
        f = freq * ratio
        if f < SR / 2.2:
            y += amp * np.sin(2 * np.pi * f * t) * np.exp(-t / decay)
    return y * env(n, attack)


def xylophone(freq, dur=1.2):
    return partials(freq, dur, [(1, 1, 0.45), (3.0, 0.22, 0.12), (6.1, 0.06, 0.05)], 0.005)


def marimba(freq, dur=1.0):
    return partials(freq, dur, [(1, 1, 0.5), (4.0, 0.12, 0.08), (9.9, 0.03, 0.03)], 0.007)


def kalimba(freq, dur=1.2):
    return partials(freq, dur, [(1, 1, 0.7), (5.4, 0.1, 0.06), (2.0, 0.08, 0.3)], 0.006)


def music_box(freq, dur=2.0):
    return partials(freq, dur, [(1, 1, 1.2), (2.0, 0.25, 0.6), (4.0, 0.08, 0.3), (5.9, 0.05, 0.15)], 0.006)


def bass(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(4 * np.pi * freq * t)
    return y * env(n, 0.012, decay=dur * 0.8, release=0.05)


def pad(freqs, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = sum(np.sin(2 * np.pi * f * t) + 0.15 * np.sin(4 * np.pi * f * t) for f in freqs)
    a = np.minimum(1, t / 0.4)
    r = np.minimum(1, (dur - t) / 0.5)
    return y * a * np.clip(r, 0, 1)


def pluck(freq, dur=1.2, seed=0, bright=0.5):
    """Karplus-Strong string (ukulele)."""
    n = int(dur * SR)
    period = int(SR / freq)
    rng = np.random.default_rng(seed)
    buf = rng.uniform(-1, 1, period)
    buf = np.convolve(buf, np.ones(3) / 3, "same") * bright + buf * (1 - bright) * 0.3
    y = np.zeros(n)
    for i in range(n):
        y[i] = buf[i % period]
        buf[i % period] = 0.498 * (buf[i % period] + buf[(i + 1) % period])
    return y * env(n, 0.004)


def noise_burst(dur, attack, decay, lo=None, hi=None, seed=0):
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    y = rng.standard_normal(n)
    if hi:  # crude low-pass: moving average
        k = max(1, int(SR / hi))
        y = np.convolve(y, np.ones(k) / k, "same")
    if lo:  # crude high-pass: subtract a slower average
        k = max(1, int(SR / lo))
        y = y - np.convolve(y, np.ones(k) / k, "same")
    return y * env(n, attack, decay)


def drum(f0, f1, dur, decay, seed=0):
    """Bongo/woodblock style hit: pitch glides from f0 to f1."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t / 0.015)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR)
    y += 0.08 * noise_burst(dur, 0.001, 0.01, seed=seed)
    return y * env(n, 0.002, decay)


def place(total_n, events):
    """Mix (start_seconds, signal, gain) events into a buffer of total_n samples."""
    y = np.zeros(total_n)
    for start, sig, gain in events:
        i = int(round(start * SR))
        if i >= total_n:
            continue
        m = min(len(sig), total_n - i)
        y[i:i + m] += sig[:m] * gain
    return y


# --- ITU-R BS.1770-4 loudness -------------------------------------------------

def _biquad_shelf(sr):
    # High-shelf "head" filter (pyloudnorm derivation).
    G, Q, fc = 3.99984385397, 0.7071752369554193, 1681.9744509555319
    A = 10 ** (G / 40)
    w0 = 2 * np.pi * fc / sr
    alpha = np.sin(w0) / (2 * Q)
    b = [A * ((A + 1) + (A - 1) * np.cos(w0) + 2 * np.sqrt(A) * alpha),
         -2 * A * ((A - 1) + (A + 1) * np.cos(w0)),
         A * ((A + 1) + (A - 1) * np.cos(w0) - 2 * np.sqrt(A) * alpha)]
    a = [(A + 1) - (A - 1) * np.cos(w0) + 2 * np.sqrt(A) * alpha,
         2 * ((A - 1) - (A + 1) * np.cos(w0)),
         (A + 1) - (A - 1) * np.cos(w0) - 2 * np.sqrt(A) * alpha]
    return np.array(b) / a[0], np.array(a) / a[0]


def _biquad_hp(sr):
    Q, fc = 0.5003270373253953, 38.13547087613982
    w0 = 2 * np.pi * fc / sr
    alpha = np.sin(w0) / (2 * Q)
    b = [(1 + np.cos(w0)) / 2, -(1 + np.cos(w0)), (1 + np.cos(w0)) / 2]
    a = [1 + alpha, -2 * np.cos(w0), 1 - alpha]
    return np.array(b) / a[0], np.array(a) / a[0]


def lufs(y, sr=SR):
    b1, a1 = _biquad_shelf(sr)
    b2, a2 = _biquad_hp(sr)
    k = lfilter(b2, a2, lfilter(b1, a1, y))
    block, hop = int(0.4 * sr), int(0.1 * sr)
    if len(k) < block:  # short effect: ungated mean square
        return -0.691 + 10 * np.log10(np.mean(k ** 2) + 1e-12)
    z = np.array([np.mean(k[i:i + block] ** 2) for i in range(0, len(k) - block + 1, hop)])
    l = -0.691 + 10 * np.log10(z + 1e-12)
    z = z[l > -70]
    rel = -0.691 + 10 * np.log10(np.mean(z)) - 10
    z = z[(-0.691 + 10 * np.log10(z)) > rel]
    return -0.691 + 10 * np.log10(np.mean(z))


def normalise(y, target_lufs, peak_db=-1.0):
    y = y * 10 ** ((target_lufs - lufs(y)) / 20)
    peak = np.abs(y).max()
    limit = 10 ** (peak_db / 20)
    if peak > limit:
        y = y * (limit / peak)
    return y


def write(path, y, target_lufs, fmt="WAV"):
    path = pathlib.Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    y = normalise(y, target_lufs)
    if fmt == "OGG":
        # libsndfile's Vorbis encoder crashes on large single writes; feed it in chunks.
        with sf.SoundFile(str(path), "w", SR, 1, format="OGG", subtype="VORBIS") as f:
            for i in range(0, len(y), 4096):
                f.write(y[i:i + 4096].astype(np.float32))
    else:
        sf.write(str(path), y, SR, subtype="PCM_16")
    return lufs(y), 20 * np.log10(np.abs(y).max())
