#!/usr/bin/env python3
"""Synthesize VIGIL's four looping music beds offline (dark dungeon-synth).

Doctrine: music is generated, not licensed (same as Sfx). music.gd blends the
four layers by volume — camp (the fire), night (the vigil, the bed you hear
almost always), danger (rises with the horde), boss (dread + a RARE bell toll,
never a constant ring). Loops are seamless: every layer's motion completes an
integer number of cycles across the loop, so the wrap is inaudible.

Run:  python3 tools/gen_music.py        # writes assets/music/*.wav
"""
import math, os, struct, wave
import numpy as np

SR = 16000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "music")

# A minor-ish palette (Hz). Low, cold, roomy.
A1, A2, C3, E3, A3 = 55.0, 110.0, 130.81, 164.81, 220.0
D3, F3, G3 = 146.83, 174.61, 196.00


def _t(dur):
    return np.linspace(0.0, dur, int(SR * dur), endpoint=False)


def _norm(x, peak=0.9):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def _onepole_lp(x, a=0.02):
    """Cheap smoothing / low-pass to take the fizz off saws and noise."""
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def _snap(f, dur):
    """Snap a frequency so an integer number of cycles fits the loop — keeps
    tonal layers perfectly seamless. The shift is a fraction of a cent."""
    return max(1.0, round(f * dur)) / dur


def drone(dur, freqs, detune=0.5, lfo_cycles=2, depth=0.25):
    """Sum of slightly detuned sines with a slow shared amplitude swell."""
    t = _t(dur)
    out = np.zeros_like(t)
    for f in freqs:
        for d in (-detune, 0.0, detune):
            out += np.sin(2 * np.pi * _snap(f + d, dur) * t)
    lfo = 1.0 - depth + depth * np.sin(2 * np.pi * (lfo_cycles / dur) * t)
    return out * lfo / (len(freqs) * 3)


def pad(dur, freqs, lfo_cycles=1):
    """Airy filtered-saw pad on a chord, slow tremolo."""
    t = _t(dur)
    out = np.zeros_like(t)
    for f in freqs:
        fs = _snap(f, dur)
        saw = 2.0 * (t * fs - np.floor(0.5 + t * fs))  # -1..1 saw
        out += saw
    out = _onepole_lp(out / len(freqs), a=0.015)
    trem = 0.7 + 0.3 * np.sin(2 * np.pi * (lfo_cycles / dur) * t)
    return out * trem


def _add_event(out, start, render):
    """Add a decaying event at sample `start` (may be negative to bleed a
    previous-loop tail into the buffer start — this is what makes loops
    seamless). `render(seg_seconds)->samples` gets the time since onset."""
    n = out.size
    idx0 = max(0, start)
    seg = (np.arange(idx0, n) - start) / SR
    if seg.size:
        out[idx0:] += render(seg)


def plucks(dur, notes, period, decay=3.5, gain=0.7):
    """A slow arpeggio: a plucked (fast-decay) sine at each period step. Each
    onset is also placed one loop earlier so its tail wraps in seamlessly."""
    t = _t(dur)
    out = np.zeros_like(t)
    step = int(SR * period)
    n = t.size
    starts = list(range(0, n, step))
    for i, start in enumerate(starts):
        f = notes[i % len(notes)]
        rend = lambda seg, f=f: np.sin(2 * np.pi * f * seg) * np.exp(-decay * seg) * gain
        _add_event(out, start, rend)
        _add_event(out, start - n, rend)  # wrapped tail from the previous loop
    return out


def heartbeat(dur, bpm=44, gain=0.6):
    """A soft low thump (two beats, lub-dub) — presence without melody."""
    t = _t(dur)
    out = np.zeros_like(t)
    beat = 60.0 / bpm
    n = int(dur / beat)
    N = t.size
    for k in range(n):
        for off, g in ((0.0, 1.0), (0.16, 0.6)):
            start = int(SR * (k * beat + off))
            rend = lambda seg, g=g: np.sin(2 * np.pi * 48.0 * seg) * np.exp(-18.0 * seg) * g
            _add_event(out, start, rend)
            _add_event(out, start - N, rend)
    return out * gain


def bell(dur, period, base=440.0, gain=0.5):
    """A struck bell: inharmonic partials with long decay. Spaced by `period`
    seconds so it TOLLS occasionally — never a constant ring."""
    t = _t(dur)
    out = np.zeros_like(t)
    partials = [(1.0, 1.0), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12)]
    step = int(SR * period)
    N = t.size

    def rend(seg):
        tone = np.zeros_like(seg)
        for mult, amp in partials:
            tone += amp * np.sin(2 * np.pi * base * mult * seg)
        return tone * np.exp(-1.6 * seg)

    for start in range(0, N, step):
        _add_event(out, start, rend)
        _add_event(out, start - N, rend)  # wrap the long bell tail
    return out * gain


def noise_wash(dur, gain=0.12, lfo_cycles=1):
    """A soft airy wash — band-limited pseudo-noise built from many snapped
    sines at random phase, so it is periodic (seamless) over the loop."""
    t = _t(dur)
    n = np.zeros_like(t)
    for _ in range(60):
        f = _snap(np.random.uniform(120.0, 900.0), dur)
        n += np.sin(2 * np.pi * f * t + np.random.uniform(0, 2 * np.pi))
    n = _norm(n)
    swell = 0.5 + 0.5 * np.sin(2 * np.pi * (lfo_cycles / dur) * t)
    return n * swell * gain


def write(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767.0).astype("<i2")
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"wrote {path}  {samples.size / SR:.1f}s")


def main():
    os.makedirs(OUT, exist_ok=True)
    np.random.seed(1349)

    # camp (24s) — the fire: warm low drone + a slow gentle harp, calm.
    dur = 24.0
    camp = (0.55 * drone(dur, [A1, E3], detune=0.3, lfo_cycles=2, depth=0.2)
            + 0.5 * plucks(dur, [A3, C3 * 2, E3 * 2, A2 * 2], period=1.5, decay=4.0, gain=0.5)
            + 0.18 * noise_wash(dur, gain=0.1, lfo_cycles=1))
    write("camp", _norm(camp, 0.82))

    # night (32s) — the vigil, the bed. Airy minor pad + bowed swell + heartbeat.
    # NO bell.
    dur = 32.0
    night = (0.5 * pad(dur, [A2, C3, E3], lfo_cycles=2)
             + 0.45 * drone(dur, [A1, A2], detune=0.4, lfo_cycles=4, depth=0.3)
             + 0.35 * heartbeat(dur, bpm=42, gain=0.5)
             + 0.15 * noise_wash(dur, gain=0.1, lfo_cycles=2))
    write("night", _norm(night, 0.8))

    # danger (16s) — rises with the horde: low pulsing ostinato + tense drone +
    # a quicker heart.
    dur = 16.0
    ostinato = plucks(dur, [A2, A2, C3, A2], period=0.5, decay=6.0, gain=0.6)
    danger = (0.5 * ostinato
              + 0.5 * drone(dur, [A1, D3, F3], detune=0.6, lfo_cycles=4, depth=0.35)
              + 0.4 * heartbeat(dur, bpm=76, gain=0.55)
              + 0.15 * noise_wash(dur, gain=0.12, lfo_cycles=4))
    write("danger", _norm(danger, 0.85))

    # boss (16s) — dread drone + an occasional toll (every 4s), not a ring.
    dur = 16.0
    boss = (0.55 * drone(dur, [A1, F3, G3], detune=0.7, lfo_cycles=2, depth=0.3)
            + 0.5 * bell(dur, period=4.0, base=330.0, gain=0.5)
            + 0.3 * heartbeat(dur, bpm=60, gain=0.5))
    write("boss", _norm(boss, 0.88))

    # --- Act IV (crypt): colder and deeper, with water dripping in the dark.
    # music.gd swaps the night/boss beds to these on the "crypt" theme. ---
    dur = 32.0
    night_crypt = (0.5 * pad(dur, [A2, C3, D3], lfo_cycles=2)          # colder minor
                   + 0.5 * drone(dur, [A1, A1 * 1.5], detune=0.5, lfo_cycles=3, depth=0.35)
                   + 0.3 * heartbeat(dur, bpm=38, gain=0.42)
                   # sparse high plinks = water dripping in a stone dark
                   + 0.28 * plucks(dur, [A3 * 2, E3 * 2, C3 * 3], period=2.7, decay=7.0, gain=0.4)
                   + 0.12 * noise_wash(dur, gain=0.09, lfo_cycles=2))
    write("night_crypt", _norm(night_crypt, 0.78))

    dur = 16.0
    boss_crypt = (0.6 * drone(dur, [A1, D3, F3], detune=0.8, lfo_cycles=2, depth=0.35)
                  + 0.45 * bell(dur, period=5.0, base=220.0, gain=0.55)  # deeper, slower toll
                  + 0.35 * heartbeat(dur, bpm=54, gain=0.55))
    write("boss_crypt", _norm(boss_crypt, 0.88))


if __name__ == "__main__":
    main()
