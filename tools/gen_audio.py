#!/usr/bin/env python3
"""Deterministic procedural dark liturgical SFX & Sphere ambience generator for Abyssal Sovereign (M8.7).

Generates compact OGG Vorbis assets using numpy + wave + ffmpeg (libvorbis -q:a 1 -ar 22050)
and registers full provenance metadata in content/presentation/asset_provenance.json
while preserving existing sprite/atlas provenance entries.
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
SR = 22050


def ensure_dirs() -> None:
    (ASSETS / "audio" / "sfx").mkdir(parents=True, exist_ok=True)
    (ASSETS / "audio" / "ambience").mkdir(parents=True, exist_ok=True)
    (ASSETS / "audio" / "music").mkdir(parents=True, exist_ok=True)


def write_ogg(out_path: Path, samples: np.ndarray, loop: bool = False) -> None:
    peak = float(np.max(np.abs(samples))) if len(samples) else 1.0
    if peak > 0.92:
        samples = samples * (0.92 / peak)
    pcm = np.clip(samples * 32767.0, -32768, 32767).astype("<i2")
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
            "-c:a", "libvorbis", "-q:a", "1", "-ar", str(SR),
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


def t_arr(dur: float) -> np.ndarray:
    return np.linspace(0.0, dur, int(dur * SR), endpoint=False)


def gen_sfx() -> list[dict]:
    entries: list[dict] = []

    def add(name: str, samples: np.ndarray, desc: str, entities: list[str]) -> None:
        out = ASSETS / "audio" / "sfx" / f"{name}.ogg"
        write_ogg(out, samples, loop=False)
        entries.append({
            "asset_id": f"sfx_{name}",
            "path": f"res://assets/audio/sfx/{name}.ogg",
            "source": "Abyssal Sovereign internal procedural audio synthesizer",
            "author_or_method": "tools/gen_audio.py (numpy + ffmpeg libvorbis)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m8_asset",
            "associated_entities": entities,
            "modification_history": [f"Generated M8.7 SFX: {desc}"],
        })

    # 1. Footsteps (stone, water, grate)
    rng = np.random.default_rng(8701)
    t = t_arr(0.14)
    stone = (0.45 * np.sin(2 * np.pi * (120 - 55 * t / 0.14) * t) + 0.55 * bp_noise(rng, len(t), 220, 1400)) * env_ad(len(t), 0.004, 6.0)
    add("step_stone", 0.45 * stone, "Soft damp stone footstep", ["terrain:floor"])

    t = t_arr(0.18)
    water = (0.65 * bp_noise(rng, len(t), 500, 2600) + 0.35 * np.sin(2 * np.pi * (380 + 220 * np.sin(30 * t)) * t)) * env_ad(len(t), 0.01, 4.5)
    add("step_water", 0.42 * water, "Shallow subterranean splash", ["terrain:water"])

    t = t_arr(0.15)
    grate = (0.5 * np.sin(2 * np.pi * 410 * t) + 0.35 * np.sin(2 * np.pi * 645 * t) + 0.35 * bp_noise(rng, len(t), 800, 3200)) * env_ad(len(t), 0.003, 7.0)
    add("step_grate", 0.42 * grate, "Metallic iron grate clink", ["terrain:iron_grate"])

    # 2. Combat impacts
    t = t_arr(0.22)
    hit = (0.6 * np.sin(2 * np.pi * (160 * np.exp(-10 * t) + 55) * t) + 0.45 * bp_noise(rng, len(t), 180, 1900)) * env_ad(len(t), 0.002, 5.5)
    add("melee_hit", 0.7 * hit, "Iron blade / blunt combat impact", ["event:melee_hit"])

    t = t_arr(0.36)
    crit = (0.5 * np.sin(2 * np.pi * (210 * np.exp(-7 * t) + 68) * t) + 0.35 * np.sin(2 * np.pi * 520 * t) + 0.3 * bp_noise(rng, len(t), 300, 3400)) * env_ad(len(t), 0.002, 4.2)
    add("melee_crit", 0.78 * crit, "Resonant critical strike", ["event:melee_crit"])

    t = t_arr(0.16)
    miss = bp_noise(rng, len(t), 400, 1800) * np.sin(np.pi * np.arange(len(t)) / len(t))
    add("melee_miss", 0.38 * miss, "Dull blade/fist whoosh", ["event:melee_miss"])

    t = t_arr(0.20)
    ranged = (0.5 * np.sin(2 * np.pi * (420 * np.exp(-14 * t) + 130) * t) + 0.45 * bp_noise(rng, len(t), 900, 3600)) * env_ad(len(t), 0.002, 5.8)
    add("ranged_fire", 0.62 * ranged, "Crossbow/sling bolt release", ["event:ranged_shot"])

    t = t_arr(0.45)
    spell = (0.38 * np.sin(2 * np.pi * (293.66 + 140 * t) * t) + 0.30 * np.sin(2 * np.pi * 440.0 * t) + 0.25 * np.sin(2 * np.pi * 659.25 * t) + 0.2 * bp_noise(rng, len(t), 700, 2800)) * env_ad(len(t), 0.03, 3.4)
    add("spell_cast", 0.65 * spell, "Occult ritual invocation", ["event:spell_cast"])

    t = t_arr(0.42)
    heal = (0.4 * np.sin(2 * np.pi * 261.63 * t) + 0.35 * np.sin(2 * np.pi * 329.63 * t) + 0.28 * np.sin(2 * np.pi * 392.0 * t)) * env_ad(len(t), 0.04, 3.2)
    add("heal", 0.58 * heal, "Restorative draught / mending cadence", ["event:heal"])

    # 3. World features & hazards
    t = t_arr(0.32)
    door = (0.5 * np.sin(2 * np.pi * (95 + 35 * np.sin(14 * t)) * t) + 0.45 * bp_noise(rng, len(t), 140, 850)) * env_ad(len(t), 0.02, 3.8)
    add("door_open", 0.6 * door, "Heavy vault / iron door grating open", ["event:door_open"])

    t = t_arr(0.30)
    trap = (0.55 * np.sin(2 * np.pi * 880 * t) + 0.45 * np.sin(2 * np.pi * 1240 * t) + 0.45 * bp_noise(rng, len(t), 1200, 4200)) * env_ad(len(t), 0.002, 6.2)
    add("trap_trigger", 0.7 * trap, "Spring-iron trap snap", ["event:trap_trigger"])

    t = t_arr(0.38)
    chain = (0.45 * np.sin(2 * np.pi * 690 * t) + 0.4 * np.sin(2 * np.pi * 1035 * t) + 0.45 * bp_noise(rng, len(t), 1500, 4800)) * env_ad(len(t), 0.005, 4.5)
    add("chain_strike", 0.68 * chain, "Heavy shackle / Eight Chains strike", ["event:subjugation"])

    t = t_arr(0.48)
    seal = (0.65 * np.sin(2 * np.pi * (110 * np.exp(-4 * t) + 48) * t) + 0.35 * np.sin(2 * np.pi * 330 * t) + 0.35 * bp_noise(rng, len(t), 100, 1200)) * env_ad(len(t), 0.004, 3.0)
    add("seal_break", 0.72 * seal, "Ancient Sphere Seal fracture", ["event:seal_break"])

    # 4. Progression, masks, relics, contracts
    t = t_arr(0.45)
    disc = (0.45 * np.sin(2 * np.pi * 440 * t) + 0.38 * np.sin(2 * np.pi * 659.25 * t)) * env_ad(len(t), 0.01, 3.2)
    add("discovery", 0.56 * disc, "Discovery / codex / level chime", ["event:discovery"])

    t = t_arr(0.34)
    ident = (0.4 * np.sin(2 * np.pi * 587.33 * t) + 0.35 * np.sin(2 * np.pi * 880.0 * t)) * env_ad(len(t), 0.008, 4.0)
    add("identify", 0.52 * ident, "Ink-and-bell identification chime", ["event:identify"])

    t = t_arr(0.55)
    rwork = (0.42 * np.sin(2 * np.pi * 196.0 * t) + 0.35 * np.sin(2 * np.pi * 293.66 * t) + 0.25 * np.sin(2 * np.pi * 587.33 * t)) * env_ad(len(t), 0.03, 2.8)
    add("relic_work", 0.65 * rwork, "Relic Work liturgical resonance", ["event:relic_work"])

    t = t_arr(0.50)
    rtrans = (0.45 * np.sin(2 * np.pi * (320 - 180 * t / 0.5) * t) + 0.35 * np.sin(2 * np.pi * 480 * t) + 0.3 * bp_noise(rng, len(t), 400, 2200)) * env_ad(len(t), 0.015, 3.2)
    add("relic_transmute", 0.68 * rtrans, "Relic sacrifice / gold transmutation", ["event:relic_transmute"])

    t = t_arr(0.35)
    mask = (0.45 * bp_noise(rng, len(t), 350, 1700) + 0.35 * np.sin(2 * np.pi * (260 + 90 * np.sin(10 * t)) * t)) * env_ad(len(t), 0.02, 3.6)
    add("mask_switch", 0.58 * mask, "Porcelain/veil Mask shift", ["event:mask_switch"])

    t = t_arr(0.40)
    contract = (0.55 * np.sin(2 * np.pi * (140 * np.exp(-9 * t) + 72) * t) + 0.35 * np.sin(2 * np.pi * 220 * t)) * env_ad(len(t), 0.004, 3.8)
    add("contract_sign", 0.64 * contract, "Wax seal & contract thud", ["event:contract_sign"])

    t = t_arr(0.48)
    boss_atk = (0.6 * np.sin(2 * np.pi * (145 * np.exp(-6 * t) + 52) * t) + 0.35 * np.sin(2 * np.pi * 104 * t) + 0.35 * bp_noise(rng, len(t), 120, 1800)) * env_ad(len(t), 0.003, 3.2)
    add("boss_attack", 0.78 * boss_atk, "Boss / Guardian heavy strike", ["event:boss_attack"])

    # 5. Interface & run resolution
    t = t_arr(0.06)
    click = (0.5 * np.sin(2 * np.pi * 780 * t) + 0.4 * bp_noise(rng, len(t), 900, 2800)) * env_ad(len(t), 0.001, 10.0)
    add("ui_click", 0.35 * click, "Parchment/slate UI click", ["ui:button"])

    t = t_arr(0.14)
    confirm = (0.45 * np.sin(2 * np.pi * 523.25 * t) + 0.35 * np.sin(2 * np.pi * 783.99 * t)) * env_ad(len(t), 0.004, 6.0)
    add("ui_confirm", 0.45 * confirm, "Slate confirmation tone", ["ui:confirm"])

    t = t_arr(1.10)
    death = (0.55 * np.sin(2 * np.pi * 98.0 * t) + 0.35 * np.sin(2 * np.pi * 116.54 * t) + 0.25 * np.sin(2 * np.pi * 146.83 * t)) * env_ad(len(t), 0.02, 2.2)
    add("death", 0.74 * death, "Low funerary abyssal toll", ["event:death"])

    t = t_arr(1.25)
    vic = (0.42 * np.sin(2 * np.pi * 196.0 * t) + 0.38 * np.sin(2 * np.pi * 293.66 * t) + 0.32 * np.sin(2 * np.pi * 392.0 * t) + 0.25 * np.sin(2 * np.pi * 587.33 * t)) * env_ad(len(t), 0.05, 2.0)
    add("victory", 0.72 * vic, "Solemn ascending cathedral fifth chord", ["event:victory"])

    return entries


def seamless_noise(rng: np.random.Generator, n: int, lo_hz: float, hi_hz: float) -> np.ndarray:
    """Periodic bandlimited noise that wraps seamlessly at boundaries."""
    raw = bp_noise(rng, n, lo_hz, hi_hz)
    half = n // 2
    fade = np.linspace(0.0, 1.0, half // 2)
    out = raw.copy()
    k = len(fade)
    out[:k] = raw[:k] * fade + raw[-k:] * (1.0 - fade)
    out[-k:] = out[:k]
    return out


def gen_ambience() -> list[dict]:
    entries: list[dict] = []
    dur = 4.0  # Integer-Hz tones wrap with zero click!
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
        # Snap frequencies to integer cycles across dur=4.0s for sample-exact seamless looping
        k1 = max(1, int(round(f1 * dur))) / dur
        k2 = max(1, int(round(f2 * dur))) / dur
        lfo = 0.78 + 0.22 * np.sin(2 * np.pi * (1.0 / dur) * t)
        drone = (0.45 * np.sin(2 * np.pi * k1 * t) + 0.30 * np.sin(2 * np.pi * k2 * t) + 0.14 * np.sin(2 * np.pi * (k2 * 2.0) * t)) * lfo
        air = 0.28 * seamless_noise(rng, n, nlo, nhi)
        sig = drone + air
        if num == 2:
            # Subtle brass clock ticks every 0.5s
            for tick_s in (0.4, 1.4, 2.4, 3.4):
                i0 = int(tick_s * SR)
                ln = min(int(0.06 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.22 * np.sin(2 * np.pi * 1120 * tt) * np.exp(-55 * tt)
        elif pulses and num == 1:
            # Soft cistern water drips
            for drip_s, df in ((0.7, 520), (2.2, 610)):
                i0 = int(drip_s * SR)
                ln = min(int(0.14 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.20 * np.sin(2 * np.pi * (df + 320 * tt) * tt) * np.exp(-26 * tt)
        elif pulses and num == 5:
            # Distant forge clink
            for hit_s in (1.1, 2.9):
                i0 = int(hit_s * SR)
                ln = min(int(0.20 * SR), n - i0)
                tt = np.arange(ln) / float(SR)
                sig[i0:i0 + ln] += 0.18 * (np.sin(2 * np.pi * 680 * tt) + 0.5 * np.sin(2 * np.pi * 1020 * tt)) * np.exp(-16 * tt)

        fname = f"sphere_{num}_{sid}.ogg"
        write_ogg(ASSETS / "audio" / "ambience" / fname, 0.42 * sig, loop=True)
        entries.append({
            "asset_id": f"ambience_{sid}",
            "path": f"res://assets/audio/ambience/{fname}",
            "source": "Abyssal Sovereign internal procedural audio synthesizer",
            "author_or_method": "tools/gen_audio.py (numpy seamless loop + ffmpeg libvorbis)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m8_asset",
            "associated_entities": [f"sphere:{sid}"],
            "modification_history": [f"Generated M8.7 ambience loop: {desc}"],
        })
    return entries


def gen_music_placeholders() -> list[dict]:
    """Generate compact liturgical organ/choir placeholder stems for all 16 M8.8 soundtrack contexts."""
    manifest = json.loads((PRES / "soundtrack_manifest.json").read_text())
    entries: list[dict] = []
    dur = 6.0  # Integer cycles for seamless liturgical motif loops
    n = int(dur * SR)
    t = t_arr(dur)

    # Modal interval motifs (ratios over root Hz)
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
        "boss_encounters": [1.0, 1.059, 1.414, 1.335, 1.0, 1.189],
        "ending_apotheosis": [1.0, 1.25, 1.5, 1.875, 2.0, 1.5],
        "ending_way_of_return": [1.0, 1.189, 1.5, 1.335, 1.189, 1.0],
        "death_named_losses": [1.0, 1.189, 1.059, 1.0, 0.891, 0.75],
    }
    default_motif = [1.0, 1.059, 1.335, 1.5, 1.335, 1.189]

    for idx, ctx in enumerate(manifest["contexts"]):
        cid = ctx["context_id"]
        is_loop = bool(ctx.get("loop", True))
        root = roots.get(cid, 130.81)
        notes = motifs.get(cid, default_motif)
        sig = np.zeros(n)

        # Slow solemn organ pedal + fifth
        k_bass = max(1, int(round((root * 0.5) * dur))) / dur
        k_fifth = max(1, int(round((root * 0.75) * dur))) / dur
        swell = 0.72 + 0.28 * np.sin(2 * np.pi * (1.0 / dur) * t)
        sig += (0.34 * np.sin(2 * np.pi * k_bass * t) + 0.22 * np.sin(2 * np.pi * k_fifth * t)) * swell

        # 6 slow liturgical chime/organ voices (1s each)
        step = n // len(notes)
        for ni, ratio in enumerate(notes):
            i0 = ni * step
            ln = min(step, n - i0)
            tt = np.arange(ln) / float(SR)
            freq = max(1, int(round(root * ratio * (ln / float(SR))))) / (ln / float(SR))
            atk = np.minimum(1.0, tt / 0.08)
            rel = np.exp(-2.1 * tt)
            voice = (0.36 * np.sin(2 * np.pi * freq * tt) + 0.16 * np.sin(2 * np.pi * (freq * 2.0) * tt) + 0.08 * np.sin(2 * np.pi * (freq * 3.0) * tt))
            sig[i0:i0 + ln] += voice * atk * rel

        if not is_loop:
            fade_n = min(n // 4, int(1.2 * SR))
            sig[-fade_n:] *= np.linspace(1.0, 0.0, fade_n)

        fname = f"{cid}.ogg"
        write_ogg(ASSETS / "audio" / "music" / fname, 0.45 * sig, loop=is_loop)
        entries.append({
            "asset_id": f"music_{cid}",
            "path": f"res://assets/audio/music/{fname}",
            "source": "Abyssal Sovereign internal procedural placeholder liturgical stem",
            "author_or_method": "tools/gen_audio.py (numpy modal organ/bell placeholder + ffmpeg libvorbis)",
            "license_status": "project-original-placeholder",
            "approval_status": "placeholder_liturgical_temp",
            "associated_entities": [f"soundtrack:{cid}"],
            "modification_history": [f"Generated M8.8 placeholder liturgical stem: {ctx['title']}"],
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
    print(f"Generated {len(entries)} M8.7/M8.8 audio assets into {ASSETS / 'audio'}")


if __name__ == "__main__":
    main()
