#!/usr/bin/env python3
"""Compose and render all music and sound effects for Rhythm Workshop.

Everything is synthesised here, so there are no third-party licences.
Rules from the design: C major only, loops are whole bars (they wrap seamlessly),
chimes use the C pentatonic scale, soft attacks, music -20 LUFS, effects -16 LUFS.

Run with the project venv:  ~/tools/venvs/rhythm/bin/python scripts/make_audio.py
"""
import functools

import numpy as np

from audio_lib import (AUDIO, SR, bass, drum, kalimba, marimba, midi_hz, music_box, noise_burst,
                       pad, partials, place, pluck, write, xylophone)

CHORDS = {  # MIDI chord tones (root position, octave 3)
    "C": [48, 52, 55], "Am": [45, 48, 52], "F": [41, 45, 48], "G": [43, 47, 50],
}
PENTA = [m + 12 * o for o in (4, 5) for m in (0, 2, 4, 7, 9)]  # C4 D4 E4 G4 A4 C5 ... (as offsets from 60)
PENTA = [60 + (p - 48) for p in PENTA]  # C4..A5
RHYTHMS = [  # (start, length) in eighth notes within a 4/4 bar
    [(0, 2), (2, 2), (4, 4)],
    [(0, 2), (2, 1), (3, 1), (4, 2), (6, 2)],
    [(0, 3), (3, 1), (4, 4)],
    [(0, 4), (4, 2), (6, 2)],
    [(0, 2), (4, 2), (6, 2)],
]


def chord_pitches(chord, lo=60, hi=76):
    pcs = {m % 12 for m in CHORDS[chord]}
    return [p for p in PENTA if p % 12 in pcs and lo <= p <= hi]


def make_phrase(chords, rng, lo=60, hi=76, sparse=False):
    """A 4-bar melody: chord tones on strong beats, pentatonic steps between."""
    scale = [p for p in PENTA if lo <= p <= hi]
    pick = [0, 1, 0, 2] if not sparse else [4, 3, 4, 3]
    shapes = [RHYTHMS[rng.integers(len(RHYTHMS))] for _ in range(3)]
    if sparse:
        shapes = [RHYTHMS[4], RHYTHMS[3], RHYTHMS[0]]
    notes, prev = [], scale[len(scale) // 2]
    for bar, chord in enumerate(chords):
        rhythm = shapes[pick[bar] % len(shapes)] if bar < 3 else [(0, 8)] if sparse else [(0, 2), (2, 6)]
        for k, (start, length) in enumerate(rhythm):
            if k == 0 or start % 4 == 0:
                cands = chord_pitches(chord, lo, hi) or scale
                p = min(cands, key=lambda c: (abs(c - prev), c))
            else:
                i = scale.index(prev) if prev in scale else 0
                i = int(np.clip(i + rng.choice([-1, 1, 1, -2]), 0, len(scale) - 1))
                p = scale[i]
            notes.append((bar * 8 + start, length, p))
            prev = p
    return notes


def strum(chord, seed, dur=1.1):
    return sum(np.pad(_pluck(midi_hz(m + 12), seed + j), (int(j * 0.012 * SR), 0))[:int(dur * SR)]
               for j, m in enumerate(CHORDS[chord]))


@functools.lru_cache(maxsize=None)
def _pluck(freq, seed):
    return pluck(freq, 1.1, seed % 3)


def render_track(bpm, phrases, melody_voice, parts, loop=True, tail=3.0, rng_seed=1):
    """phrases: list of (chord list, melody key). Same key -> same melody (repetition)."""
    beat = 60.0 / bpm
    bars = [c for chords, _ in phrases for c in chords]
    total = len(bars) * 4 * beat
    n = int(round(total * SR))
    events = []
    rng = np.random.default_rng(rng_seed)
    melodies = {}
    t0 = 0.0
    for chords, key in phrases:
        if key is not None:
            if key not in melodies:
                melodies[key] = make_phrase(chords, rng, sparse=(melody_voice is music_box))
            for start8, len8, pitch in melodies[key]:
                dur = max(0.6, len8 * beat / 2 + 0.6)
                events.append((t0 + start8 * beat / 2, melody_voice(midi_hz(pitch), dur), 0.55))
        t0 += len(chords) * 4 * beat
    for bar, chord in enumerate(bars):
        for part in parts:
            events += part(bar, chord, bar * 4 * beat, beat)
    y = place(n + int(tail * SR), events)
    if loop:  # wrap the tail onto the start so the loop is seamless
        y[:int(tail * SR)] += y[n:]
    return y[:n], total


# --- accompaniment parts ------------------------------------------------------

def kalimba_arp(bar, chord, t, beat):
    tones = CHORDS[chord] + [CHORDS[chord][1]]
    return [(t + i * beat, kalimba(midi_hz(m + 12), 1.3), 0.22) for i, m in enumerate(tones)]


def brush(bar, chord, t, beat):
    return [(t + i * beat, noise_burst(0.35, 0.02, 0.09, lo=1500, hi=9000, seed=bar * 4 + i), 0.05)
            for i in (1, 3)]


def bass_1_3(bar, chord, t, beat):
    root = CHORDS[chord][0] - 12
    return [(t, bass(midi_hz(root), beat * 1.8), 0.4), (t + 2 * beat, bass(midi_hz(root + 7), beat * 1.8), 0.28)]


def bass_1(bar, chord, t, beat):
    return [(t, bass(midi_hz(CHORDS[chord][0] - 12), beat * 3.5), 0.35)]


def uke(bar, chord, t, beat):
    return [(t + off * beat, strum(chord, bar + int(off * 2)), g)
            for off, g in ((0, 0.16), (1.5, 0.09), (2, 0.13), (3, 0.1))]


def woodblock(bar, chord, t, beat):
    return [(t + i * beat, drum(1250 if i == 0 else 1000, 900 if i == 0 else 800, 0.12, 0.025, seed=i), 0.16 if i == 0 else 0.1)
            for i in range(4)]


def shaker(bar, chord, t, beat):
    return [(t + (i + 0.5) * beat, noise_burst(0.12, 0.01, 0.03, lo=4000, seed=bar * 8 + i), 0.05) for i in range(4)]


def soft_kick(bar, chord, t, beat):
    return [(t + i * beat, drum(110, 55, 0.3, 0.12, seed=i), 0.35) for i in (0, 2)]


def xylo_low(freq, dur):
    return xylophone(freq, dur)


def goodnight_pad(bar, chord, t, beat):
    return [(t, pad([midi_hz(m + 12) for m in CHORDS[chord]], 4 * beat + 0.3), 0.07)]


# --- music ---------------------------------------------------------------------

def make_music():
    P1, P2, P3 = ["C", "Am", "F", "G"], ["F", "G", "C", "Am"], ["Am", "F", "G", "G"]
    out = AUDIO / "bgm"
    tracks = {
        # name: (bpm, phrases, melody voice, parts)
        "bgm_calm": (70, [(P1, "a"), (P1, "a"), (P2, "b"), (P1, "a"), (P2, "b"), (P1, None), (P3, "c")],
                     kalimba, [kalimba_arp, brush, bass_1]),
        "bgm_workshop_01": (80, [(P1, "a"), (P1, "a"), (P2, "b"), (P1, "a"), (P2, "b"), (P1, "a"), (P3, "c")],
                            marimba, [uke, woodblock, bass_1_3]),
        "bgm_workshop_02": (90, [(P1, "a"), (P1, "a"), (P2, "b"), (P1, "a"), (P2, "b"), (P1, "a"), (P3, "c"),
                                 (["F", "G"], None)],
                            xylo_low, [bass_1_3, shaker, soft_kick]),
    }
    report = []
    for name, (bpm, phrases, voice, parts) in tracks.items():
        y, total = render_track(bpm, phrases, voice, parts)
        l, pk = write(out / f"{name}.ogg", y, -20, "OGG")
        beats = total * bpm / 60
        report.append(f"{name}: {bpm} BPM, {total:.2f}s, {beats:.1f} beats, {l:.1f} LUFS, peak {pk:.1f} dBFS")
    # Goodnight: plays once, slow music box, ends on C with a fade.
    y, total = render_track(60, [(["C", "Am", "F", "G"], "a"), (["C", "F", "G", "C"], "b")], music_box,
                            [goodnight_pad], loop=False)
    fade = int(4 * SR)
    y[-fade:] *= np.linspace(1, 0, fade) ** 2
    l, pk = write(out / "bgm_goodnight.ogg", y, -20, "OGG")
    report.append(f"bgm_goodnight: 60 BPM, {total:.2f}s, {l:.1f} LUFS, peak {pk:.1f} dBFS")
    return report


# --- sound effects -------------------------------------------------------------

def make_sfx():
    sfx, perc = AUDIO / "sfx", AUDIO / "perc"
    rep = []

    def w(path, y, target=-16):
        l, pk = write(path, y, target)
        rep.append(f"{path.name}: {len(y) / SR:.2f}s, {l:.1f} LUFS, peak {pk:.1f} dBFS")

    # Pick-up: soft wooden pop (pitch is varied +-50 cents at play time).
    w(sfx / "sfx_pick_up.wav", drum(700, 420, 0.14, 0.035, seed=3))
    # Correct-drop notes: xylophone on C pentatonic.
    for name, m in [("c5", 72), ("d5", 74), ("e5", 76), ("g5", 79), ("a5", 81), ("c6", 84)]:
        w(sfx / f"sfx_note_{name}.wav", xylophone(midi_hz(m), 1.3))
    # On-beat bonus shimmer: quick glints on high C-major tones.
    glints = [96, 100, 103, 108, 103, 108]
    w(sfx / "sfx_sparkle.wav",
      place(int(0.9 * SR), [(i * 0.055, partials(midi_hz(m), 0.5, [(1, 1, 0.09), (2.0, 0.2, 0.04)]), 1 - i * 0.1)
                            for i, m in enumerate(glints)]), -20)
    # Wrong bin: warm, quiet marimba F3.
    w(sfx / "sfx_soft_note.wav", marimba(midi_hz(53), 0.9), -20)
    # Glide back: very soft air.
    n = int(0.45 * SR)
    wh = noise_burst(0.45, 0.12, None, hi=2500, seed=5) * np.sin(np.pi * np.arange(n) / n) ** 2
    w(sfx / "sfx_whoosh.wav", wh, -24)
    # Milo's bongos: low on beat 1, high on beats 2-4; fill = 4-note roll.
    low = drum(260, 200, 0.3, 0.09, seed=7)
    high = drum(420, 350, 0.25, 0.07, seed=8)
    w(perc / "perc_tap_down.wav", low, -18)
    w(perc / "perc_tap_up.wav", high, -20)
    w(perc / "perc_fill.wav", place(int(1.0 * SR), [(0.0, high, 0.7), (0.11, high, 0.8), (0.22, low, 0.9),
                                                    (0.36, low, 1.0)]))
    return rep


if __name__ == "__main__":
    for line in make_music() + make_sfx():
        print(line)
