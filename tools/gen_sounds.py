#!/usr/bin/env python3
"""Synthesizes the game's sound effects into assets/sounds/*.wav.

    python3 tools/gen_sounds.py

No external assets: everything is noise, sines and envelopes. Change a recipe
below and re-run to tweak a sound. Needs numpy.
"""
import wave
from pathlib import Path

import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
rng = np.random.default_rng(7)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def env(n, attack=0.005, release=None, curve=3.0):
    """Fast attack, exponential-ish decay over n samples."""
    x = np.linspace(0, 1, n)
    a = np.clip(x / max(attack * RATE / n, 1e-6), 0, 1)
    d = (1 - x) ** curve if release is None else np.clip((1 - x) / release, 0, 1) ** curve
    return a * d


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array (sweeps)."""
    cutoff = np.broadcast_to(cutoff, x.shape)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def noise(seconds):
    return rng.uniform(-1, 1, len(t(seconds)))


def tone(freq, seconds, harmonics=((1, 1.0),)):
    tt = t(seconds)
    freq = np.broadcast_to(freq, tt.shape)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return sum(amp * np.sin(phase * h) for h, amp in harmonics)


def save(name, x, gain=0.8):
    x = x / max(np.max(np.abs(x)), 1e-6) * gain
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("wrote", f"assets/sounds/{name}.wav", f"{len(x) / RATE:.2f}s")


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # Throw: rising whoosh.
    d = 0.28
    save("throw", lowpass(noise(d), np.linspace(400, 3500, len(t(d)))) * env(len(t(d)), 0.03, curve=2))

    # Hook bites: metallic clank + click.
    d = 0.25
    clank = tone(1250, d, ((1, 1), (2.76, 0.6), (5.4, 0.3))) * env(len(t(d)), 0.001, curve=6)
    click = noise(d) * env(len(t(d)), 0.0005, curve=30)
    save("hook", clank + 0.8 * click)

    # Miss: dull low tick.
    d = 0.15
    save("miss", lowpass(noise(d), 600) * env(len(t(d)), 0.001, curve=8), 0.5)

    # Zip launch: quick upward snap.
    d = 0.18
    save("zip", tone(np.linspace(300, 1400, len(t(d))), d, ((1, 1), (2, 0.3))) * env(len(t(d)), 0.002, curve=4), 0.6)

    # Landing: low thud.
    d = 0.3
    thud = tone(np.linspace(110, 50, len(t(d))), d) * env(len(t(d)), 0.002, curve=5)
    save("land", thud + 0.5 * lowpass(noise(d), 400) * env(len(t(d)), 0.001, curve=12))

    # Lava: sizzle.
    d = 0.6
    save("lava", lowpass(noise(d), 5000) * env(len(t(d)), 0.01, curve=2) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t(d))), 0.6)

    # Checkpoint: two-tone ding.
    d = 0.35
    half = len(t(d)) // 2
    ding = np.concatenate([tone(880, d / 2, ((1, 1), (2, 0.3)))[:half], tone(1320, d / 2, ((1, 1), (2, 0.3)))])
    save("checkpoint", ding * env(len(ding), 0.003, curve=2), 0.5)

    # GO: short bright beep.
    d = 0.2
    save("go", tone(1046, d, ((1, 1), (3, 0.2))) * env(len(t(d)), 0.003, curve=2), 0.5)

    # Finish: rising arpeggio.
    notes = [523, 659, 784, 1046]
    parts = [tone(f, 0.14, ((1, 1), (2, 0.25))) * env(len(t(0.14)), 0.003, curve=1.5) for f in notes]
    tail = tone(1046, 0.5, ((1, 1), (2, 0.25))) * env(len(t(0.5)), 0.003, curve=3)
    save("finish", np.concatenate(parts + [tail]), 0.6)

    # Wind: seamless 2 s noise loop (crossfaded ends), filtered.
    d = 2.0
    n = len(t(d))
    w = lowpass(noise(d + 0.2), 700)
    fade = int(0.2 * RATE)
    loop = w[:n].copy()
    ramp = np.linspace(0, 1, fade)
    loop[:fade] = w[:fade] * ramp + w[n:n + fade] * (1 - ramp)
    save("wind", loop, 0.7)

    # New sounds go last: the shared random generator keeps the older ones
    # identical when this script runs again.

    # Scrape: gritty slide along rock (wall or ceiling deflection).
    d = 0.35
    grit = lowpass(noise(d), 2500) * (0.5 + 0.5 * (rng.uniform(0, 1, len(t(d))) > 0.7))
    save("scrape", lowpass(grit, 1800) * env(len(t(d)), 0.005, curve=1.5), 0.55)


if __name__ == "__main__":
    main()
