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


def cave_reverb(x, wet):
    """Bakes cave reverb into a sound: early reflections plus a dark,
    exponentially decaying tail (1.4 s). Its own random generator, so the dry
    sounds stay the same. Web builds play sounds as plain samples, where bus
    effects are not available - baked reverb works everywhere."""
    room = np.random.default_rng(101)
    n = int(RATE * 1.4)
    tt = np.arange(n) / RATE
    tail = room.uniform(-1, 1, n) * np.exp(-tt * 4.5)
    tail = lowpass(tail, 2200)
    ir = np.zeros(n)
    for delay, gain in ((0.023, 0.6), (0.041, 0.45), (0.067, 0.35), (0.097, 0.25)):
        ir[int(delay * RATE)] += gain
    ir += tail * 0.12
    size = len(x) + n
    wet_signal = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    dry = np.concatenate([x, np.zeros(n)])
    out = dry + wet_signal * wet / max(np.max(np.abs(wet_signal)), 1e-6) * np.max(np.abs(x))
    # Trim silence at the end.
    level = np.abs(out) > 0.002 * np.max(np.abs(out))
    last = np.nonzero(level)[0][-1] if level.any() else len(out) - 1
    return out[: last + 1]


def save(name, x, gain=0.8, room=0.0):
    if room > 0.0:
        x = cave_reverb(x, room)
    x = x / max(np.max(np.abs(x)), 1e-6) * gain
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("wrote", f"assets/sounds/{name}.wav", f"{len(x) / RATE:.2f}s")


def save_loop(name, x, gain):
    """A seamless ambient loop: the end crossfades into the start. Its import
    settings loop it (written once; Godot fills in the rest)."""
    fade = int(0.3 * RATE)
    n = len(x) - fade
    loop = x[:n].copy()
    ramp = np.linspace(0, 1, fade)
    loop[:fade] = x[:fade] * ramp + x[n:] * (1 - ramp)
    save(name, loop, gain)
    imp = OUT / f"{name}.wav.import"
    if not imp.exists():
        imp.write_text('[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\n\n'
                       "edit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n")


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # Throw: rising whoosh.
    d = 0.28
    save("throw", lowpass(noise(d), np.linspace(400, 3500, len(t(d)))) * env(len(t(d)), 0.03, curve=2), room=0.25)

    # Hook bites: metallic clank + click.
    d = 0.25
    clank = tone(1250, d, ((1, 1), (2.76, 0.6), (5.4, 0.3))) * env(len(t(d)), 0.001, curve=6)
    click = noise(d) * env(len(t(d)), 0.0005, curve=30)
    save("hook", clank + 0.8 * click, room=0.35)

    # Miss: dull low tick.
    d = 0.15
    save("miss", lowpass(noise(d), 600) * env(len(t(d)), 0.001, curve=8), 0.5, room=0.3)

    # Zip launch: quick upward snap.
    d = 0.18
    save("zip", tone(np.linspace(300, 1400, len(t(d))), d, ((1, 1), (2, 0.3))) * env(len(t(d)), 0.002, curve=4), 0.6, room=0.3)

    # Landing: low thud.
    d = 0.3
    thud = tone(np.linspace(110, 50, len(t(d))), d) * env(len(t(d)), 0.002, curve=5)
    save("land", thud + 0.5 * lowpass(noise(d), 400) * env(len(t(d)), 0.001, curve=12), room=0.4)

    # Lava: sizzle.
    d = 0.6
    save("lava", lowpass(noise(d), 5000) * env(len(t(d)), 0.01, curve=2) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t(d))), 0.6)

    # Checkpoint: two-tone ding.
    d = 0.35
    half = len(t(d)) // 2
    ding = np.concatenate([tone(880, d / 2, ((1, 1), (2, 0.3)))[:half], tone(1320, d / 2, ((1, 1), (2, 0.3)))])
    save("checkpoint", ding * env(len(ding), 0.003, curve=2), 0.5, room=0.2)

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
    save("scrape", lowpass(grit, 1800) * env(len(t(d)), 0.005, curve=1.5), 0.55, room=0.25)

    # Crack: a brittle stalactite snaps (sharp crack, then a falling rumble).
    d = 0.6
    snap = noise(d) * env(len(t(d)), 0.0005, curve=25)
    rumble = lowpass(noise(d), 300) * env(len(t(d)), 0.05, curve=2)
    save("crack", snap + 0.8 * rumble, 0.7, room=0.45)

    # Ring: bright rising chime when flying through a speed ring.
    d = 0.4
    sweep = np.linspace(880, 1760, len(t(d)))
    chime = tone(sweep, d, ((1, 1), (2, 0.4), (3, 0.15))) * env(len(t(d)), 0.002, curve=2.5)
    save("ring", chime, 0.5, room=0.3)

    # Perfect chain: quick bright double chime with a shimmer on top.
    d = 0.12
    first = tone(1318, d, ((1, 1), (2, 0.35), (4, 0.1))) * env(len(t(d)), 0.002, curve=2.0)
    d2 = 0.45
    second = tone(1976, d2, ((1, 1), (2, 0.3), (3, 0.12))) * env(len(t(d2)), 0.002, curve=3.0)
    shimmer = tone(3951, d2, ((1, 1),)) * env(len(t(d2)), 0.01, curve=5.0) * 0.25
    save("perfect", np.concatenate([first, second + shimmer]), 0.55, room=0.3)

    # Bounce: soft rubbery boing (rising pitch with a wobble) and a puff.
    d = 0.45
    tt = t(d)
    pitch = np.linspace(150, 420, len(tt)) * (1 + 0.06 * np.sin(2 * np.pi * 18 * tt))
    boing = tone(pitch, d, ((1, 1), (2, 0.25))) * env(len(tt), 0.004, curve=3.0)
    puff = lowpass(noise(d), 900) * env(len(tt), 0.002, curve=14)
    save("bounce", boing + 0.4 * puff, 0.6, room=0.35)

    # --- Ambience, played at places in the cave (AudioStreamPlayer3D). Own
    # generator, so the sounds above stay as they are.
    amb = np.random.default_rng(55)

    # Lava: deep rumble with bubbles popping.
    d = 4.3
    n = len(t(d))
    rumble = lowpass(amb.uniform(-1, 1, n), 90) * 6.0
    rumble *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.5 * t(d))
    for _ in range(18):
        at = int(amb.uniform(0, d - 0.2) * RATE)
        bd = 0.12
        bt = t(bd)
        bubble = np.sin(2 * np.pi * np.cumsum(amb.uniform(150, 320) * (1 + 2 * bt / bd)) / RATE) * np.exp(-bt * 30)
        rumble[at:at + len(bt)] += bubble * amb.uniform(0.2, 0.5)
    save_loop("amb_lava", rumble, 0.7)

    # Crystal: soft shimmering hum (two tones beating slowly).
    d = 4.3
    hum = tone(1320, d) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.37 * t(d))) + 0.6 * tone(1983, d) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.23 * t(d) + 1))
    save_loop("amb_crystal", hum, 0.35)

    # Updraft: rushing air, swelling.
    d = 4.3
    rush = lowpass(amb.uniform(-1, 1, len(t(d))), 900) - lowpass(amb.uniform(-1, 1, len(t(d))), 120)
    rush *= 0.65 + 0.35 * np.sin(2 * np.pi * 0.6 * t(d))
    save_loop("amb_updraft", rush, 0.6)

    # Drip: one water drop falling into a pool, with the cave's echo.
    d = 0.3
    tt = t(d)
    f = amb.uniform(1500, 1900) * (1 + 0.6 * tt / d)
    drip = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-tt * 22)
    save("drip", drip, 0.5, room=0.6)


if __name__ == "__main__":
    main()
