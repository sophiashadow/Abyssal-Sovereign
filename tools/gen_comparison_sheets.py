#!/usr/bin/env python3
"""Generates M8 vs M9.1 side-by-side visual comparison sheets from /tmp/m8_atlas_before/."""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BEFORE = Path("/tmp/m8_atlas_before")
OUT = ROOT / "docs" / "screenshots" / "m9" / "comparison"
BG = (14, 11, 18, 255)
GOLD = (210, 175, 105, 255)
IVORY = (238, 229, 211, 255)
DIM = (150, 140, 130, 255)


def make_sheet(title: str, before_path: Path, after_path: Path, out_name: str, scale: int = 2, crop_h: int | None = None) -> None:
    if not before_path.exists() or not after_path.exists():
        return
    b_im = Image.open(before_path).convert("RGBA")
    a_im = Image.open(after_path).convert("RGBA")
    if crop_h is not None:
        b_im = b_im.crop((0, 0, b_im.width, min(crop_h, b_im.height)))
        a_im = a_im.crop((0, 0, a_im.width, min(crop_h, a_im.height)))
    b_s = b_im.resize((b_im.width * scale, b_im.height * scale), Image.Resampling.NEAREST)
    a_s = a_im.resize((a_im.width * scale, a_im.height * scale), Image.Resampling.NEAREST)
    pad = 24
    hdr = 52
    w = max(b_s.width, a_s.width) * 2 + pad * 3
    h = hdr + max(b_s.height, a_s.height) + pad
    canvas = Image.new("RGBA", (w, h), BG)
    d = ImageDraw.Draw(canvas)
    d.text((pad, 10), f"ABYSSAL SOVEREIGN M9.1 — {title}", fill=IVORY)
    d.text((pad, 30), "M8 Baseline", fill=DIM)
    d.text((pad * 2 + b_s.width, 30), "M9.1 Elevated", fill=GOLD)
    d.line([(pad + b_s.width + pad // 2, 26), (pad + b_s.width + pad // 2, h - 12)], fill=DIM)
    canvas.paste(b_s, (pad, hdr), b_s)
    canvas.paste(a_s, (pad * 2 + b_s.width, hdr), a_s)
    canvas.save(OUT / out_name)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_sheet("Sphere 1 (Moon) & Sphere 4 (Sun) Tiles", BEFORE / "sphere_1_moon.png", ROOT / "assets/tiles/sphere_1_moon.png", "comparison_spheres.png", scale=2)
    make_sheet("Avatars & Recurring NPCs", BEFORE / "avatars.png", ROOT / "assets/sprites/avatars.png", "comparison_avatars_npcs.png", scale=3)
    make_sheet("Bestiary & 15 Bespoke Bosses", BEFORE / "monsters.png", ROOT / "assets/sprites/monsters.png", "comparison_bosses.png", scale=2)
    make_sheet("Woodcut Emblems (64x64)", BEFORE / "emblems.png", ROOT / "assets/portraits/emblems.png", "comparison_relics_emblems.png", scale=2)
    print("Generated comparison sheets in", OUT)


if __name__ == "__main__":
    main()
