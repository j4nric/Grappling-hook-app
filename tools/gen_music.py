#!/usr/bin/env python3
"""Synthesizes the music loop into assets/music/*.wav: three stems of the same
length that play in sync and are mixed by speed in the game (scripts/music.gd).

    python3 tools/gen_music.py

- base:  dark pad, sub bass, water drips (always on)
- pulse: kick and hats (fades in with speed)
- arp:   bright arpeggio with echo (fades in at high speed and in flow)

A minor, 96 BPM, 8 bars: Am | Am | F | E | Am | Am | F | E. Every stem is
rendered with its echo/reverb tail wrapped around to the start, so the loop
has no seam. Fixed seed: the same files every run. Needs numpy.
"""
import wave
from pathlib import Path

import numpy as np

RATE = 22050
BPM = 96
BEAT = 60.0 / BPM
BARS = 8
LENGTH = BARS * 4 * BEAT
N = int(RATE * LENGTH)
OUT = Path(__file__).resolve().parent.parent / "assets" / "music"
rng = np.random.default_rng(3)

# Chords per bar as MIDI notes (root, third, fifth).
CHORDS = [(57, 60, 64), (57, 60, 64), (53, 57, 60), (52, 56, 59)] * 2


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def env(n, attack, release):
    a = np.clip(np.arange(n) / max(attack * RATE, 1), 0, 1)
    r = np.clip((n - np.arange(n)) / max(release * RATE, 1), 0, 1)
    return a * r


def lowpass(x, cutoff):
    alpha = 1 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def place(track, start, sound):
    """Adds sound at start (s), wrapping around the loop end."""
    i = int(start * RATE) % N
    end = i + len(sound)
    if end <= N:
        track[i:end] += sound
    else:
        track[i:] += sound[: N - i]
        rest = sound[N - i:]
        track[: len(rest)] += rest


def echo(track, delay, feedback, taps=6):
    """Circular feedback echo: the tail wraps around (seamless loop)."""
    out = track.copy()
    shift = int(delay * RATE)
    gain = 1.0
    for k in range(1, taps + 1):
        gain *= feedback
        out += np.roll(track, shift * k) * gain
    return out


def save(name, x, gain):
    x = x / max(np.max(np.abs(x)), 1e-6) * gain
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("wrote", path.relative_to(OUT.parent.parent), f"{LENGTH:.1f}s")
    imp = path.with_suffix(".wav.import")
    if not imp.exists():
        # QOA: small files, cheap to decode in the browser; loops seamlessly.
        imp.write_text('[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\n\n'
                       "compress/mode=2\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n")


def base():
    track = np.zeros(N)
    bar = 4 * BEAT
    for b, chord in enumerate(CHORDS):
        # Pad: detuned saws an octave down, slow swell, low-passed below.
        tt = t(bar)
        pad = np.zeros_like(tt)
        for note in chord:
            for detune in (-0.08, 0.08):
                f = hz(note - 12 + detune)
                pad += 2 * ((tt * f) % 1.0) - 1
        pad = lowpass(pad, 700) * env(len(tt), 1.2, 1.0) * 0.12
        place(track, b * bar, pad)
        # Sub bass on beats 1 and 3.
        for beat in (0, 2):
            d = BEAT * 1.6
            tt = t(d)
            sub = np.sin(2 * np.pi * hz(chord[0] - 24) * tt) * env(len(tt), 0.01, d * 0.9)
            place(track, b * bar + beat * BEAT, sub * 0.5)
    # Water drips: high plinks with a quick pitch drop, scattered.
    for _ in range(14):
        start = rng.uniform(0, LENGTH)
        d = 0.35
        tt = t(d)
        f = rng.uniform(1400, 2600) * (1 - 0.25 * tt / d)
        drip = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-tt * 14)
        place(track, start, drip * rng.uniform(0.08, 0.18))
    return echo(track, BEAT * 0.75, 0.35)


def pulse():
    track = np.zeros(N)
    for beat in range(BARS * 4):
        start = beat * BEAT
        # Kick: pitch-swept sine.
        d = 0.35
        tt = t(d)
        f = 120 * np.exp(-tt * 18) + 45
        kick = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-tt * 9)
        place(track, start, kick * 0.9)
        # Hats on the off-beats, softer 16ths in between.
        for k, level in ((0.5, 0.3), (0.25, 0.1), (0.75, 0.12)):
            d = 0.06
            hat = rng.uniform(-1, 1, len(t(d)))
            hat = (hat - lowpass(hat, 6000)) * np.exp(-t(d) * 70)
            place(track, start + k * BEAT, hat * level)
        # A low tom fill at the end of every second bar.
        if beat % 8 == 7:
            for k, note in ((0.0, 50), (0.25, 47), (0.5, 45), (0.75, 43)):
                d = 0.25
                tt = t(d)
                tom = np.sin(2 * np.pi * hz(note) * (1 - 0.3 * tt) * tt) * np.exp(-tt * 12)
                place(track, start + k * BEAT, tom * 0.35)
    return track


def arp():
    track = np.zeros(N)
    pattern = [0, 1, 2, 1, 0, 2, 1, 2]
    for b, chord in enumerate(CHORDS):
        for step in range(16):
            note = chord[pattern[step % len(pattern)]] + 12 + (12 if step % 8 >= 6 else 0)
            d = BEAT / 4 * 0.9
            tt = t(d)
            f = hz(note)
            # Soft square: odd harmonics, fading out.
            tone = sum(np.sin(2 * np.pi * f * h * tt) / h for h in (1, 3, 5))
            tone *= env(len(tt), 0.003, d * 0.8) * (0.7 if step % 4 else 1.0)
            place(track, b * 4 * BEAT + step * BEAT / 4, tone)
    return echo(lowpass(track, 3500), BEAT * 0.75, 0.4)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save("music_base", base(), 0.6)
    save("music_pulse", pulse(), 0.55)
    save("music_arp", arp(), 0.35)


if __name__ == "__main__":
    main()
