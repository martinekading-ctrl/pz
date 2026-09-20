"""Generate the small, original combat SFX used by the mobile prototype."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


RATE = 22_050
OUTPUT = Path(__file__).resolve().parents[1] / "art" / "audio"


def write_sound(name: str, seconds: float, sample_fn) -> None:
    count = int(RATE * seconds)
    frames = bytearray()
    for index in range(count):
        time = index / RATE
        value = max(-1.0, min(1.0, sample_fn(time, seconds)))
        frames.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(frames)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    rng = random.Random(33017)

    write_sound(
        "melee_swing.wav",
        0.14,
        lambda t, d: (rng.random() * 2.0 - 1.0)
        * (0.28 + 0.72 * math.sin(math.pi * t / d))
        * (1.0 - t / d)
        * 0.34,
    )
    write_sound(
        "melee_hit.wav",
        0.12,
        lambda t, d: (
            math.sin(2.0 * math.pi * (96.0 - 38.0 * t / d) * t) * 0.62
            + (rng.random() * 2.0 - 1.0) * 0.18
        )
        * math.exp(-30.0 * t),
    )
    write_sound(
        "melee_kill.wav",
        0.18,
        lambda t, d: (
            math.sin(2.0 * math.pi * (74.0 - 26.0 * t / d) * t) * 0.58
            + (rng.random() * 2.0 - 1.0) * 0.25
        )
        * math.exp(-20.0 * t),
    )
    write_sound(
        "player_hurt.wav",
        0.16,
        lambda t, d: (
            math.sin(2.0 * math.pi * (138.0 - 48.0 * t / d) * t) * 0.32
            + (rng.random() * 2.0 - 1.0) * 0.12
        )
        * math.exp(-18.0 * t),
    )


if __name__ == "__main__":
    main()
