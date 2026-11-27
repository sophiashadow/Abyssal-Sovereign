#!/usr/bin/env python3
"""Deterministic procedural dark liturgical SFX, Sphere ambience & placeholder music mastering (M9.5).

Generates 44.1 kHz OGG Vorbis assets (libvorbis -q:a 3) with RMS normalization and
soft true-peak limiting, and updates content/presentation/asset_provenance.json
while preserving existing sprite/icon provenance entries.

Note: All 16 liturgical music stems remain tagged `placeholder_liturgical_temp` /
`project-original-placeholder` pending owner-authorized VENEFICA LUX recordings.
"""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
PRES = ROOT / "content" / "presentation"
SR = 44100


def ensure_dirs() -> None:
    (ASSETS / "audio" / "sfx").mkdir(parents=True, exist_ok=True)
    (ASSETS / "audio" / "ambience").mkdir(parents=True, exist_ok=True)
    (ASSETS / "audio" / "music").mkdir(parents=True, exist_ok=True)


def normalize_master(samples: np.ndarray, target_rms_db: float, peak_db: float) -> np.ndarray:
    """Normalizes active RMS level and applies gentle soft-clip peak limiting."""
    if len(samples) == 0:
        return samples
    # Measure RMS over active signal (> -50 dB of peak) so short decays don't over-boost.
    pk = float(np.max(np.abs(samples)))
    if pk < 1e-6:
        return samples
    active = samples[np.abs(samples) >= pk * 0.01]
    rms = float(np.sqrt(np.mean(active * active))) if len(active) else pk * 0.5
    target_rms = 10.0 ** (target_rms_db / 20.0)
    gain = min(target_rms / max(rms, 1e-6), 8.0)
    y = samples * gain

    peak_lim = 10.0 ** (peak_db / 20.0)
    knee = peak_lim * 0.82
    over = np.abs(y) > knee
    if np.any(over):
        sign = np.sign(y[over])
        excess = (np.abs(y[over]) - knee) / max(peak_lim - knee, 1e-4)
        y[over] = sign * (knee + (peak_lim - knee) * np.tanh(excess))
    return np.clip(y, -peak_lim, peak_lim)


def write_ogg(out_path: Path, samples: np.ndarray, loop: bool = False,
              target_rms_db: float = -16.0, peak_db: float = -1.5) -> None:
    mastered = normalize_master(samples, target_rms_db=target_rms_db, peak_db=peak_db)
    pcm = np.clip(mastered * 32767.0, -32768, 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        wav_path = tf.name
    try:
        with wave.open(wav_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(SR)
            wf.writeframes(pcm.tobytes())
        cmd = [
            "ffmpeg", "-y", "-v", "error", "-i", wav_path,
            "-c:a", "libvorbis", "-q:a", "3", "-ar", str(SR),
        ]
        if loop:
            cmd += ["-metadata", "LOOP=true"]
        cmd.append(str(out_path))
        subprocess.run(cmd, check=True)
    finally:
        if os.path.exists(wav_path):
            os.unlink(wav_path)


def env_ad(n: int, attack_s: float, decay_p: float = 3.0) -> np.ndarray:
    t = np.linspace(0.0, 1.0, n, endpoint=False)
    atk_n = max(1, int(attack_s * SR))
    atk = np.minimum(1.0, np.arange(n) / float(atk_n))
    dec = np.exp(-decay_p * t)
    tail_n = max(1, int(0.015 * SR))
    fade = np.ones(n)
    fade[-tail_n:] = np.linspace(1.0, 0.0, tail_n)
    return atk * dec * fade


def bp_noise(rng: np.random.Generator, n: int, lo_hz: float, hi_hz: float) -> np.ndarray:
    noise = rng.standard_normal(n)
    spec = np.fft.rfft(noise)
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    mask = (freqs >= lo_hz) & (freqs <= hi_hz)
    spec *= mask
    out = np.fft.irfft(spec, n=n)
    mx = np.max(np.abs(out))
    return out / mx if mx > 1e-6 else out


def circular_reverb(sig: np.ndarray, delays_ms=(37, 61, 89, 127), mix_wet: float = 0.24) -> np.ndarray:
    """Wrap-around multi-tap comb reverb preserving sample-exact seamless loop boundaries."""
    wet = np.zeros_like(sig)
    for idx, ms in enumerate(delays_ms):
        shift = int(ms * SR / 1000.0) % len(sig)
        gain = 0.55 ** (idx + 1)
        wet += np.roll(sig, shift) * gain
    return sig * (1.0 - mix_wet) + wet * mix_wet


def t_arr(dur: float) -> np.ndarray:
    return np.linspace(0.0, dur, int(dur * SR), endpoint=False)


def gen_sfx() -> list[dict]:
    entries: list[dict] = []

    def add(name: str, samples: np.ndarray, desc: str, entities: list[str], rms_db: float = -15.5) -> None:
        out = ASSETS / "audio" / "sfx" / f"{name}.ogg"
        write_ogg(out, samples, loop=False, target_rms_db=rms_db, peak_db=-1.5)
        entries.append({
            "asset_id": f"sfx_{name}",
            "path": f"res://assets/audio/sfx/{name}.ogg",
            "source": "Abyssal Sovereign internal procedural audio synthesizer",
            "author_or_method": "tools/gen_audio.py (44.1kHz RMS-mastered numpy + ffmpeg libvorbis)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m9_asset",
            "associated_entities": entities,
            "modification_history": [
                f"Generated M8.7 SFX: {desc}",
                f"Mastered M9.5 (44.1kHz -q:a 3, {rms_db:.1f} dBFS RMS, -1.5 dBFS peak ceiling)",
            ],
        })

    rng = np.random.default_rng(8701)
    t = t_arr(0.14)
    stone = (0.45 * np.sin(2 * np.pi * (120 - 55 * t / 0.14) * t) + 0.55 * bp_noise(rng, len(t), 220, 1400)) * env_ad(len(t), 0.004, 6.0)
    add("step_stone", stone, "Soft damp stone footstep", ["terrain:floor"], rms_db=-20.0)

    t = t_arr(0.18)
    water = (0.65 * bp_noise(rng, len(t), 500, 2600) + 0.35 * np.sin(2 * np.pi * (380 + 220 * np.sin(30 * t)) * t)) * env_ad(len(t), 0.01, 4.5)
    add("step_water", water, "Shallow subterranean splash", ["terrain:water"], rms_db=-19.0)

    t = t_arr(0.15)
    grate = (0.5 * np.sin(2 * np.pi * 410 * t) + 0.35 * np.sin(2 * np.pi * 645 * t) + 0.35 * bp_noise(rng, len(t), 800, 3200)) * env_ad(len(t), 0.003, 7.0)
    add("step_grate", grate, "Metallic iron grate clink", ["terrain:iron_grate"], rms_db=-19.0)

    t = t_arr(0.22)
    hit = (0.6 * np.sin(2 * np.pi * (160 * np.exp(-10 * t) + 55) * t) + 0.45 * bp_noise(rng, len(t), 180, 1900)) * env_ad(len(t), 0.002, 5.5)
    add("melee_hit", hit, "Iron blade / blunt combat impact", ["event:melee_hit"], rms_db=-14.5)

    t = t_arr(0.36)
    crit = (0.5 * np.sin(2 * np.pi * (210 * np.exp(-7 * t) + 68) * t) + 0.35 * np.sin(2 * np.pi * 520 * t) + 0.3 * bp_noise(rng, len(t), 300, 3400)) * env_ad(len(t), 0.002, 4.2)
    add("melee_crit", crit, "Resonant critical strike", ["event:melee_crit"], rms_db=-13.5)

    t = t_arr(0.16)
    miss = bp_noise(rng, len(t), 400, 1800) * np.sin(np.pi * np.arange(len(t)) / len(t))
    add("melee_miss", miss, "Dull blade/fist whoosh", ["event:melee_miss"], rms_db=-19.5)

    t = t_arr(0.20)
    ranged = (0.5 * np.sin(2 * np.pi * (420 * np.exp(-14 * t) + 130) * t) + 0.45 * bp_noise(rng, len(t), 900, 3600)) * env_ad(len(t), 0.002, 5.8)
    add("ranged_fire", ranged, "Crossbow/sling bolt release", ["event:ranged_shot"], rms_db=-15.5)

    t = t_arr(0.45)
    spell = (0.38 * np.sin(2 * np.pi * (293.66 + 140 * t) * t) + 0.30 * np.sin(2 * np.pi * 440.0 * t) + 0.25 * np.sin(2 * np.pi * 659.25 * t) + 0.2 * bp_noise(rng, len(t), 700, 2800)) * env_ad(len(t), 0.03, 3.4)
    add("spell_cast", spell, "Occult ritual invocation", ["event:spell_cast"], rms_db=-16.0)

    t = t_arr(0.42)
    heal = (0.4 * np.sin(2 * np.pi * 261.63 * t) + 0.35 * np.sin(2 * np.pi * 329.63 * t) + 0.28 * np.sin(2 * np.pi * 392.0 * t)) * env_ad(len(t), 0.04, 3.2)
    add("heal", heal, "Restorative draught / mending cadence", ["event:heal"], rms_db=-16.5)

    t = t_arr(0.32)
    door = (0.5 * np.sin(2 * np.pi * (95 + 35 * np.sin(14 * t)) * t) + 0.45 * bp_noise(rng, len(t), 140, 850)) * env_ad(len(t), 0.02, 3.8)
    add("door_open", door, "Heavy vault / iron door grating open", ["event:door_open"], rms_db=-16.0)

    t = t_arr(0.30)
    trap = (0.55 * np.sin(2 * np.pi * 880 * t) + 0.45 * np.sin(2 * np.pi * 1240 * t) + 0.45 * bp_noise(rng, len(t), 1200, 4200)) * env_ad(len(t), 0.002, 6.2)
    add("trap_trigger", trap, "Spring-iron trap snap", ["event:trap_trigger"], rms_db=-14.5)

    t = t_arr(0.38)
    chain = (0.45 * np.sin(2 * np.pi * 690 * t) + 0.4 * np.sin(2 * np.pi * 1035 * t) + 0.45 * bp_noise(rng, len(t), 1500, 4800)) * env_ad(len(t), 0.005, 4.5)
    add("chain_strike", chain, "Heavy shackle / Eight Chains strike", ["event:subjugation"], rms_db=-15.0)

    t = t_arr(0.48)
    seal = (0.65 * np.sin(2 * np.pi * (110 * np.exp(-4 * t) + 48) * t) + 0.35 * np.sin(2 * np.pi * 330 * t) + 0.35 * bp_noise(rng, len(t), 100, 1200)) * env_ad(len(t), 0.004, 3.0)
    add("seal_break", seal, "Ancient Sphere Seal fracture", ["event:seal_break"], rms_db=-14.5)

    t = t_arr(0.45)
    disc = (0.45 * np.sin(2 * np.pi * 440 * t) + 0.38 * np.sin(2 * np.pi * 659.25 * t)) * env_ad(len(t), 0.01, 3.2)
    add("discovery", disc, "Discovery / codex / level chime", ["event:discovery"], rms_db=-16.5)

    t = t_arr(0.34)
    ident = (0.4 * np.sin(2 * np.pi * 587.33 * t) + 0.35 * np.sin(2 * np.pi * 880.0 * t)) * env_ad(len(t), 0.008, 4.0)
    add("identify", ident, "Ink-and-bell identification chime", ["event:identify"], rms_db=-17.0)

    t = t_arr(0.55)
    rwork = (0.42 * np.sin(2 * np.pi * 196.0 * t) + 0.35 * np.sin(2 * np.pi * 293.66 * t) + 0.25 * np.sin(2 * np.pi * 587.33 * t)) * env_ad(len(t), 0.03, 2.8)
    add("relic_work", rwork, "Relic Work liturgical resonance", ["event:relic_work"], rms_db=-15.5)

    t = t_arr(0.50)
    rtrans = (0.45 * np.sin(2 * np.pi * (320 - 180 * t / 0.5) * t) + 0.35 * np.sin(2 * np.pi * 480 * t) + 0.3 * bp_noise(rng, len(t), 400, 2200)) * env_ad(len(t), 0.015, 3.2)
    add("relic_transmute", rtrans, "Relic sacrifice / gold transmutation", ["event:relic_transmute"], rms_db=-15.0)

    t = t_arr(0.35)
    mask = (0.45 * bp_noise(rng, len(t), 350, 1700) + 0.35 * np.sin(2 * np.pi * (260 + 90 * np.sin(10 * t)) * t)) * env_ad(len(t), 0.02, 3.6)
    add("mask_switch", mask, "Porcelain/veil Mask shift", ["event:mask_switch"], rms_db=-16.0)

    t = t_arr(0.40)
    contract = (0.55 * np.sin(2 * np.pi * (140 * np.exp(-9 * t) + 72) * t) + 0.35 * np.sin(2 * np.pi * 220 * t)) * env_ad(len(t), 0.004, 3.8)
    add("contract_sign", contract, "Wax seal & contract thud", ["event:contract_sign"], rms_db=-15.5)

    t = t_arr(0.48)
    boss_atk = (0.6 * np.sin(2 * np.pi * (145 * np.exp(-6 * t) + 52) * t) + 0.35 * np.sin(2 * np.pi * 104 * t) + 0.35 * bp_noise(rng, len(t), 120, 1800)) * env_ad(len(t), 0.003, 3.2)
    add("boss_attack", boss_atk, "Boss / Guardian heavy strike", ["event:boss_attack"], rms_db=-13.5)

    t = t_arr(0.06)
    click = (0.5 * np.sin(2 * np.pi * 780 * t) + 0.4 * bp_noise(rng, len(t), 900, 2800)) * env_ad(len(t), 0.001, 10.0)
    add("ui_click", click, "Parchment/slate UI click", ["ui:button"], rms_db=-20.5)

    t = t_arr(0.14)
    confirm = (0.45 * np.sin(2 * np.pi * 523.25 * t) + 0.35 * np.sin(2 * np.pi * 783.99 * t)) * env_ad(len(t), 0.004, 6.0)
    add("ui_confirm", confirm, "Slate confirmation tone", ["ui:confirm"], rms_db=-17.5)

    t = t_arr(1.10)
    death = (0.55 * np.sin(2 * np.pi * 98.0 * t) + 0.35 * np.sin(2 * np.pi * 116.54 * t) + 0.25 * np.sin(2 * np.pi * 146.83 * t)) * env_ad(len(t), 0.02, 2.2)
    add("death", death, "Low funerary abyssal toll", ["event:death"], rms_db=-14.5)

    t = t_arr(1.25)
    vic = (0.42 * np.sin(2 * np.pi * 196.0 * t) + 0.38 * np.sin(2 * np.pi * 293.66 * t) + 0.32 * np.sin(2 * np.pi * 392.0 * t) + 0.25 * np.sin(2 * np.pi * 587.33 * t)) * env_ad(len(t), 0.05, 2.0)
    add("victory", vic, "Solemn ascending cathedral fifth chord", ["event:victory"], rms_db=-15.0)

    return entries


def seamless_noise(rng: np.random.Generator, n: int, lo_hz: float, hi_hz: float) -> np.ndarray:
    raw = bp_noise(rng, n, lo_hz, hi_hz)
    k = n // 4
    fade = np.linspace(0.0, 1.0, k)
    out = raw.copy()
    out[:k] = raw[:k] * fade + raw[-k:] * (1.0 - fade)
    out[-k:] = out[:k]
    return out


def gen_ambience() -> list[dict]:
    entries: list[dict] = []
    dur = 8.0
    n = int(dur * SR)
    t = t_arr(dur)

    specs = [
        (1, "moon", "Moon: damp Ossuary Warrens cisterns", 55.0, 82.5, 180.0, 620.0, True),
        (2, "mercury", "Mercury: Tithe Vault brass escapement & ledger resonance", 73.5, 110.25, 420.0, 1500.0, False),
        (3, "venus", "Venus: Gilded Choir velvet cathedral hum", 65.0, 97.5, 240.0, 900.0, False),
        (4, "sun", "Sun: False Solar Court radiant crystal drone", 110.0, 165.0, 700.0, 2200.0, False),
        (5, "mars", "Mars: Iron Scriptorium furnace draft & chain ring", 49.0, 73.5, 120.0, 680.0, True),
        (6, "jupiter", "Jupiter: Chamber of Decrees imperial organ fifths", 61.75, 92.625, 150.0, 640.0, False),
        (7, "saturn", "Saturn: Sealed Stair abyssal void stillness", 41.25, 61.875, 90.0, 380.0, False),
    ]

    for num, sid, desc, f1, f2, nlo, nhi, pulses in specs:
        rng = np.random.default_rng(8800 + num)
        k1 = max(1, int(round(f1 * dur))) / dur
        k2 = max(1, int(round(f2 * dur))) / dur
        lfo = 0.76 + 0.24 * np.sin(2 * np.pi * (1.0 / dur) * t)
        drone = (0.45 * np.sin(2 * np.pi * k1 * t) + 0.30 * np.sin(2 * np.pi * k2 * t) + 0.14 * np.sin(2 * np.pi * (k2 * 2.0) * t)) * lfo
        air = 0.28 * seamless_noise(rng, n, nlo, nhi)
        sig = drone + air
        if num == 2:
            for tick_s in (0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5):
                i0 = int(tick_s * SR)
                ln = min(int(0.06 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.22 * np.sin(2 * np.pi * 1120 * tt) * np.exp(-55 * tt)
        elif pulses and num == 1:
            for drip_s, df in ((0.9, 520), (3.1, 610), (5.4, 550), (7.1, 640)):
                i0 = int(drip_s * SR)
                ln = min(int(0.14 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.20 * np.sin(2 * np.pi * (df + 320 * tt) * tt) * np.exp(-26 * tt)
        elif pulses and num == 5:
            for hit_s in (1.3, 3.8, 6.1):
                i0 = int(hit_s * SR)
                ln = min(int(0.20 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.18 * (np.sin(2 * np.pi * 680 * tt) + 0.5 * np.sin(2 * np.pi * 1020 * tt)) * np.exp(-16 * tt)

        sig = circular_reverb(sig, mix_wet=0.22)
        fname = f"sphere_{num}_{sid}.ogg"
        write_ogg(ASSETS / "audio" / "ambience" / fname, sig, loop=True, target_rms_db=-25.0, peak_db=-6.0)
        entries.append({
            "asset_id": f"ambience_{sid}",
            "path": f"res://assets/audio/ambience/{fname}",
            "source": "Abyssal Sovereign internal procedural audio synthesizer",
            "author_or_method": "tools/gen_audio.py (44.1kHz 8s seamless loop + circular reverb + ffmpeg libvorbis)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m9_asset",
            "associated_entities": [f"sphere:{sid}"],
            "modification_history": [
                f"Generated M8.7 ambience loop: {desc}",
                "Mastered M9.5 (44.1kHz -q:a 3, 8s seamless loop, -25 dBFS RMS, -6 dBFS peak ceiling)",
            ],
        })
    return entries


def gen_music_placeholders() -> list[dict]:
    """Generate 12s mastered placeholder liturgical organ/choir stems for all 16 contexts."""
    manifest = json.loads((PRES / "soundtrack_manifest.json").read_text())
    entries: list[dict] = []
    dur = 12.0
    n = int(dur * SR)
    t = t_arr(dur)

    roots = {
        "main_title": 146.83, "character_creation": 130.81, "sphere_moon": 110.0,
        "sphere_mercury": 164.81, "sphere_venus": 185.0, "sphere_sun": 146.83,
        "sphere_mars": 138.59, "sphere_jupiter": 98.0, "sphere_saturn": 123.47,
        "sanctuaries": 174.61, "boss_encounters": 146.83,
        "ending_serpents_way": 164.81, "ending_way_of_return": 130.81,
        "ending_unwritten_door": 146.83, "ending_apotheosis": 123.47,
        "death_named_losses": 110.0,
    }
    motifs = {
        "boss_encounters": [1.0, 1.059, 1.414, 1.335, 1.0, 1.189, 1.414, 1.059],
        "ending_apotheosis": [1.0, 1.25, 1.5, 1.875, 2.0, 1.5, 1.25, 1.0],
        "ending_way_of_return": [1.0, 1.189, 1.5, 1.335, 1.189, 1.0, 1.335, 1.0],
        "death_named_losses": [1.0, 1.189, 1.059, 1.0, 0.891, 0.75, 0.891, 0.75],
    }
    default_motif = [1.0, 1.059, 1.335, 1.5, 1.335, 1.189, 1.059, 1.0]

    for ctx in manifest["contexts"]:
        cid = ctx["context_id"]
        is_loop = bool(ctx.get("loop", True))
        root = roots.get(cid, 130.81)
        notes = motifs.get(cid, default_motif)
        sig = np.zeros(n)

        k_bass = max(1, int(round((root * 0.5) * dur))) / dur
        k_fifth = max(1, int(round((root * 0.75) * dur))) / dur
        k_oct = max(1, int(round(root * dur))) / dur
        swell = 0.72 + 0.28 * np.sin(2 * np.pi * (1.0 / dur) * t)
        sig += (0.34 * np.sin(2 * np.pi * k_bass * t) + 0.20 * np.sin(2 * np.pi * k_fifth * t) + 0.12 * np.sin(2 * np.pi * k_oct * t)) * swell

        step = n // len(notes)
        for ni, ratio in enumerate(notes):
            i0 = ni * step
            ln = min(step, n - i0)
            tt = np.arange(ln) / float(SR)
            freq = max(1, int(round(root * ratio * (ln / float(SR))))) / (ln / float(SR))
            atk = np.minimum(1.0, tt / 0.10)
            rel = np.exp(-1.7 * tt)
            voice = (0.34 * np.sin(2 * np.pi * freq * tt) + 0.15 * np.sin(2 * np.pi * (freq * 2.0) * tt) + 0.06 * np.sin(2 * np.pi * (freq * 3.0) * tt))
            sig[i0:i0 + ln] += voice * atk * rel

        sig = circular_reverb(sig, delays_ms=(43, 71, 109, 157), mix_wet=0.28)
        if not is_loop:
            fade_n = min(n // 4, int(1.6 * SR))
            sig[-fade_n:] *= np.linspace(1.0, 0.0, fade_n)

        fname = f"{cid}.ogg"
        write_ogg(ASSETS / "audio" / "music" / fname, sig, loop=is_loop, target_rms_db=-19.0, peak_db=-3.0)
        entries.append({
            "asset_id": f"music_{cid}",
            "path": f"res://assets/audio/music/{fname}",
            "source": "Abyssal Sovereign internal procedural placeholder liturgical stem",
            "author_or_method": "tools/gen_audio.py (44.1kHz 12s modal organ/bell placeholder + circular reverb + ffmpeg libvorbis)",
            "license_status": "project-original-placeholder",
            "approval_status": "placeholder_liturgical_temp",
            "associated_entities": [f"soundtrack:{cid}"],
            "modification_history": [
                f"Generated M8.8 placeholder liturgical stem: {ctx['title']}",
                "Mastered M9.5 (44.1kHz -q:a 3, 12s loop, -19 dBFS RMS, -3 dBFS peak ceiling; awaiting VENEFICA LUX replacement)",
            ],
        })
    return entries


def update_provenance(new_entries: list[dict]) -> None:
    prov_path = PRES / "asset_provenance.json"
    existing: list[dict] = []
    if prov_path.exists():
        data = json.loads(prov_path.read_text())
        existing = list(data.get("entries", []))
    new_ids = {e["asset_id"] for e in new_entries}
    merged = [e for e in existing if e.get("asset_id") not in new_ids] + new_entries
    prov_path.write_text(json.dumps({
        "schema": "asset_provenance",
        "version": 1,
        "entries": merged,
    }, indent=2) + "\n")


def main() -> None:
    ensure_dirs()
    entries = gen_sfx() + gen_ambience() + gen_music_placeholders()
    update_provenance(entries)
    print(f"Mastered {len(entries)} M9.5 audio assets (44.1kHz) into {ASSETS / 'audio'}")


if __name__ == "__main__":
    main()
