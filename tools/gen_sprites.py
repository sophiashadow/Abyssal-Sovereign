#!/usr/bin/env python3
"""Deterministic pixel-art sprite, emblem, icon & tileset generator for Abyssal Sovereign (M9.1).

Produces crisp, shaded 32x32 tiles/sprites, 16x16 icons, 64x64 woodcut emblems,
and application/adaptive icons adhering to docs/ART_DIRECTION.md with zero external
or unauthorized assets. Tracks every file in content/presentation/asset_provenance.json
while preserving existing audio provenance entries.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
PRES = ROOT / "content" / "presentation"
CORE = ROOT / "content" / "core"

# Foundational palette (docs/ART_DIRECTION.md)
VOID = (8, 6, 9, 255)
VOID_T = (8, 6, 9, 0)
IRON = (82, 81, 92, 255)
IRON_HI = (132, 132, 150, 255)
IRON_DK = (44, 42, 52, 255)
PORPHYRY = (45, 26, 46, 255)
PORPHYRY_LT = (84, 44, 82, 255)
PORPHYRY_DK = (26, 14, 28, 255)
GOLD = (183, 149, 85, 255)
GOLD_HI = (234, 200, 122, 255)
GOLD_DK = (118, 92, 46, 255)
FALSE_SUN = (242, 195, 92, 255)
IVORY = (238, 229, 211, 255)
RECORD = (211, 190, 160, 255)
TEXT_DIM = (168, 157, 140, 255)
LUX = (224, 0, 143, 255)
LUX_DK = (128, 12, 86, 255)
SILVER = (184, 196, 208, 255)
SILVER_DK = (108, 120, 136, 255)
BLOOD = (166, 38, 57, 255)
BLOOD_DK = (102, 20, 34, 255)
ALERT = (255, 77, 109, 255)
SAGE = (120, 190, 167, 255)
SAGE_DK = (62, 112, 98, 255)
EMBER = (255, 122, 51, 255)
RIME = (110, 198, 255, 255)
MIASMA = (143, 122, 224, 255)
WATER = (52, 74, 96, 255)
WATER_HI = (98, 130, 164, 255)


def mix(a: tuple, b: tuple, t: float) -> tuple:
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def hi(c: tuple, amt: float = 0.28) -> tuple:
    return mix(c, IVORY, amt)


def sh(c: tuple, amt: float = 0.36) -> tuple:
    return mix(c, VOID, amt)


def hsh(x: int, y: int, seed: int = 0) -> int:
    v = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return (v ^ (v >> 16)) & 0xFF


def hex_rgba(h: str, fallback=SILVER) -> tuple:
    h = (h or "").strip().lstrip("#")
    if len(h) == 6:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
    return fallback


def outline_sprite(im: Image.Image, edge=VOID) -> Image.Image:
    px = im.load()
    w, h = im.size
    out = im.copy()
    opx = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 28:
                        opx[x, y] = edge
                        break
    return out


def shade_volume(im: Image.Image, strength: float = 0.22) -> Image.Image:
    """Applies subtle top-left keylight & bottom-right shadow to opaque pixels."""
    px = im.load()
    w, h = im.size
    out = im.copy()
    opx = out.load()
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] < 200 or c[:3] == VOID[:3]:
                continue
            up_open = y == 0 or px[x, y - 1][3] < 30
            left_open = x == 0 or px[x - 1, y][3] < 30
            down_open = y == h - 1 or px[x, y + 1][3] < 30
            right_open = x == w - 1 or px[x + 1, y][3] < 30
            if up_open or left_open:
                opx[x, y] = hi(c, strength)
            elif down_open or right_open:
                opx[x, y] = sh(c, strength * 1.1)
    return out


class Sheet:
    def __init__(self, cols: int, rows: int, cell: int = 32):
        self.cols = cols
        self.rows = rows
        self.cell = cell
        self.img = Image.new("RGBA", (cols * cell, rows * cell), VOID_T)
        self.cursor = 0
        self.rects: dict[str, list[int]] = {}

    def next_tile(self, key: str) -> tuple[Image.Image, ImageDraw.ImageDraw, int, int]:
        c = self.cursor % self.cols
        r = self.cursor // self.cols
        assert r < self.rows, f"Sheet overflow at {key}"
        self.cursor += 1
        tile = Image.new("RGBA", (self.cell, self.cell), VOID_T)
        draw = ImageDraw.Draw(tile)
        self.rects[key] = [c * self.cell, r * self.cell, self.cell, self.cell]
        return tile, draw, c * self.cell, r * self.cell

    def commit(self, key: str, tile: Image.Image) -> None:
        rx, ry, _, _ = self.rects[key]
        self.img.paste(tile, (rx, ry))


def draw_sphere_tile_atlas(sphere_num: int, theme: dict) -> tuple[Sheet, dict[str, list[int]], dict[str, list[int]]]:
    """Builds a 32x32 environmental atlas (8x8 = 64 cells) for one Sphere."""
    s = Sheet(8, 8, 32)
    tile_rects: dict[str, list[int]] = {}
    feat_rects: dict[str, list[int]] = {}

    fl_base = theme["floor"]
    fl_alt = theme["floor_alt"]
    wl_cap = theme["wall_cap"]
    wl_face = theme["wall_face"]
    accent = theme["accent"]
    mortar = theme["mortar"]
    st = theme.get("style", "ossuary")

    # 4 floor variants (Tiles.FLOOR = 1)
    for v in range(4):
        key = f"s{sphere_num}:1:{v}"
        t, d, _, _ = s.next_tile(key)
        d.rectangle([0, 0, 31, 31], fill=fl_base)
        px = t.load()
        for y in range(32):
            for x in range(32):
                r = hsh(x, y, sphere_num * 41 + v * 7)
                if r < 26:
                    px[x, y] = fl_alt
                elif r > 240 and ((x + y) % 2 == 0):
                    px[x, y] = mix(fl_base, mortar, 0.45)
        # Beveled flagstone grid
        for gy in (0, 16):
            d.line([(0, gy), (31, gy)], fill=mortar)
            d.line([(0, gy + 1), (31, gy + 1)], fill=mix(fl_base, IVORY, 0.08))
        off = 8 if (v % 2 == 1) else 16
        d.line([(off, 0), (off, 15)], fill=mortar)
        d.line([(off + 1, 1), (off + 1, 15)], fill=mix(fl_base, IVORY, 0.07))
        off2 = (off + 12) % 32
        d.line([(off2, 16), (off2, 31)], fill=mortar)
        d.line([((off2 + 1) % 32, 17), ((off2 + 1) % 32, 31)], fill=mix(fl_base, IVORY, 0.07))

        if v == 1:
            if st == "brass":
                d.rectangle([9, 9, 22, 22], outline=mix(fl_base, accent, 0.45))
                d.point([(10, 10), (21, 10), (10, 21), (21, 21)], fill=GOLD)
            elif st == "choir":
                d.polygon([(16, 7), (25, 16), (16, 25), (7, 16)], outline=mix(fl_base, accent, 0.42))
                d.point([(16, 16)], fill=mix(fl_base, LUX, 0.4))
            elif st == "solar":
                d.ellipse([9, 9, 22, 22], outline=mix(fl_base, accent, 0.5))
                d.line([(16, 6), (16, 25)], fill=mix(fl_base, accent, 0.3))
            elif st == "iron":
                d.point([(4, 4), (27, 4), (4, 27), (27, 27)], fill=IRON_HI)
                d.line([(9, 16), (22, 16)], fill=mix(fl_base, IRON_HI, 0.4))
            elif st == "imperial":
                d.rectangle([4, 4, 27, 27], outline=mix(fl_base, GOLD, 0.35))
                d.line([(13, 13), (18, 18)], fill=mix(fl_base, GOLD, 0.4))
            elif st == "sealed":
                d.line([(6, 25), (16, 6), (25, 25)], fill=mix(fl_base, LUX, 0.5))
                d.line([(9, 21), (22, 21)], fill=mix(fl_base, LUX, 0.35))
            else:
                # Ossuary hairline crack + bone splinter
                d.line([(5, 22), (10, 19), (14, 21), (18, 18)], fill=mix(fl_base, IVORY, 0.22))
                d.line([(21, 7), (25, 9)], fill=mix(fl_base, RECORD, 0.25))
        elif v == 2:
            d.line([(6, 7), (11, 10)], fill=mortar)
            d.point([(24, 9), (25, 10)], fill=mix(fl_base, accent, 0.45))
        elif v == 3:
            d.line([(18, 22), (25, 26)], fill=mix(fl_base, VOID, 0.4))
        s.commit(key, t)
        tile_rects[key] = s.rects[key]

    # 4 wall variants (Tiles.WALL = 0)
    for v in range(4):
        key = f"s{sphere_num}:0:{v}"
        t, d, _, _ = s.next_tile(key)
        d.rectangle([0, 0, 31, 31], fill=wl_face)
        d.rectangle([0, 0, 31, 10], fill=wl_cap)
        # Bevel top edge and cap shadow lip
        d.line([(0, 0), (31, 0)], fill=mix(wl_cap, IVORY, 0.22))
        d.line([(0, 1), (31, 1)], fill=mix(wl_cap, IVORY, 0.10))
        d.line([(0, 9), (31, 9)], fill=mix(wl_cap, VOID, 0.40))
        d.line([(0, 10), (31, 10)], fill=VOID)
        d.line([(0, 11), (31, 11)], fill=mix(wl_face, VOID, 0.55))
        # Subtle dither on wall cap
        px = t.load()
        for y in range(2, 9):
            for x in range(32):
                if hsh(x, y, sphere_num * 19 + v) < 28:
                    px[x, y] = mix(wl_cap, VOID, 0.2)
        # Courses on front face
        for by in (17, 24):
            d.line([(0, by), (31, by)], fill=mix(wl_face, VOID, 0.45))
            d.line([(0, by + 1), (31, by + 1)], fill=mix(wl_face, IVORY, 0.08))
        for bx in (7, 21):
            d.line([(bx, 11), (bx, 17)], fill=mix(wl_face, VOID, 0.45))
            d.line([((bx + 8) % 32, 18), ((bx + 8) % 32, 24)], fill=mix(wl_face, VOID, 0.45))
            d.line([((bx + 3) % 32, 25), ((bx + 3) % 32, 31)], fill=mix(wl_face, VOID, 0.45))

        if v == 1:
            if st == "brass":
                d.rectangle([9, 13, 22, 25], fill=mix(wl_face, GOLD, 0.26), outline=accent)
                d.line([(16, 14), (16, 24)], fill=VOID)
                d.point([(11, 15), (20, 15), (11, 23), (20, 23)], fill=GOLD_HI)
            elif st == "choir":
                d.arc([9, 12, 22, 26], 180, 360, fill=GOLD, width=2)
                d.rectangle([11, 17, 20, 25], fill=PORPHYRY_DK, outline=GOLD_DK)
                d.line([(16, 18), (16, 24)], fill=LUX)
            elif st == "solar":
                d.ellipse([10, 13, 21, 24], fill=mix(wl_face, FALSE_SUN, 0.35), outline=FALSE_SUN)
                d.ellipse([13, 16, 18, 21], fill=IVORY)
            elif st == "iron":
                d.rectangle([8, 12, 23, 26], fill=IRON_DK, outline=IRON_HI)
                for gx in (12, 16, 20):
                    d.line([(gx, 13), (gx, 25)], fill=IRON)
            elif st == "imperial":
                d.rectangle([10, 13, 21, 25], fill=PORPHYRY_LT, outline=GOLD)
                d.ellipse([13, 16, 18, 21], fill=BLOOD, outline=GOLD_HI)
            elif st == "sealed":
                d.polygon([(16, 12), (22, 18), (16, 25), (10, 18)], fill=VOID, outline=LUX)
                d.point([(16, 18)], fill=IVORY)
            else:
                # Ossuary skull niche
                d.rectangle([10, 13, 21, 25], fill=VOID, outline=mix(wl_cap, accent, 0.4))
                d.ellipse([12, 15, 19, 21], fill=mix(RECORD, wl_face, 0.25))
                d.point([(14, 18), (17, 18)], fill=VOID)
        elif v == 2:
            # Carved tally / iron bracket
            d.line([(9, 15), (22, 15)], fill=accent)
            for tx in (11, 15, 19):
                d.line([(tx, 17), (tx, 22)], fill=mix(accent, RECORD, 0.45))
        elif v == 3:
            d.line([(4, 3), (10, 7)], fill=mix(wl_cap, VOID, 0.55))
            d.rectangle([22, 19, 25, 22], fill=IRON_HI, outline=VOID)
        d.line([(0, 31), (31, 31)], fill=mix(wl_face, VOID, 0.6))
        s.commit(key, t)
        tile_rects[key] = s.rects[key]

    def floor_underlay() -> tuple[Image.Image, ImageDraw.ImageDraw]:
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.rectangle([0, 0, 31, 31], fill=fl_base)
        d.line([(0, 0), (31, 0)], fill=mortar)
        d.line([(0, 16), (31, 16)], fill=mortar)
        return t, d

    # Stairs down (2) & stairs up (3)
    k = f"s{sphere_num}:2"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([4, 4, 27, 27], fill=VOID, outline=GOLD)
    d.rectangle([5, 5, 26, 26], outline=GOLD_DK)
    for idx, step_y in enumerate(range(7, 24, 4)):
        col = mix(GOLD_HI, VOID, idx * 0.16)
        d.rectangle([6 + idx * 2, step_y, 25, step_y + 2], fill=col)
        d.line([(6 + idx * 2, step_y + 2), (25, step_y + 2)], fill=VOID)
    d.polygon([(16, 26), (11, 20), (21, 20)], fill=FALSE_SUN, outline=VOID)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:3"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([4, 4, 27, 27], fill=mix(fl_base, SILVER, 0.18), outline=RECORD)
    for idx, step_y in enumerate(range(22, 6, -4)):
        col = mix(IVORY, SILVER_DK, idx * 0.16)
        d.rectangle([6, step_y, 25 - idx * 2, step_y + 2], fill=col)
    d.polygon([(16, 5), (11, 11), (21, 11)], fill=IVORY, outline=VOID)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Sealed Unwritten Door (4) & Open Door (5)
    k = f"s{sphere_num}:4"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([4, 2, 27, 29], fill=IRON_DK, outline=ALERT)
    d.rectangle([6, 4, 25, 27], fill=PORPHYRY_DK, outline=IRON)
    d.line([(16, 4), (16, 27)], fill=VOID, width=2)
    d.line([(7, 9), (24, 9)], fill=IRON_HI)
    d.line([(7, 22), (24, 22)], fill=IRON_HI)
    d.ellipse([11, 11, 21, 21], fill=BLOOD, outline=ALERT)
    d.ellipse([14, 14, 18, 18], fill=FALSE_SUN)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:5"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([4, 2, 27, 29], outline=SAGE)
    d.rectangle([4, 2, 9, 29], fill=IRON, outline=IRON_HI)
    d.rectangle([22, 2, 27, 29], fill=IRON, outline=IRON_HI)
    d.line([(10, 4), (21, 4)], fill=SAGE_DK, width=2)
    d.ellipse([12, 12, 20, 20], outline=SAGE)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Branch in (10) & Branch out (11)
    for tid, up_flag in ((10, False), (11, True)):
        k = f"s{sphere_num}:{tid}"
        s.next_tile(k)
        t, d = floor_underlay()
        d.arc([4, 3, 27, 27], 180, 360, fill=SAGE, width=2)
        d.rectangle([6, 13, 25, 27], fill=VOID, outline=SAGE_DK)
        d.ellipse([9, 15, 22, 25], outline=SAGE)
        if up_flag:
            d.polygon([(16, 15), (11, 22), (21, 22)], fill=SAGE)
        else:
            d.polygon([(16, 24), (11, 17), (21, 17)], fill=SAGE)
        s.commit(k, t)
        tile_rects[k] = s.rects[k]

    # Shallow Water (12)
    k = f"s{sphere_num}:12"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=WATER)
    px = t.load()
    for y in range(32):
        for x in range(32):
            if hsh(x, y, sphere_num * 97) < 28:
                px[x, y] = mix(WATER, VOID, 0.25)
    for wy in (7, 15, 23):
        d.line([(4, wy), (12, wy - 1), (20, wy + 1), (28, wy)], fill=WATER_HI)
        d.line([(6, wy + 1), (11, wy)], fill=mix(WATER_HI, IVORY, 0.2))
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Sanctuary Floor (13)
    k = f"s{sphere_num}:13"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=mix(fl_base, SAGE_DK, 0.42))
    d.rectangle([2, 2, 29, 29], outline=SAGE_DK)
    d.rectangle([4, 4, 27, 27], outline=SAGE)
    d.line([(16, 6), (16, 25)], fill=mix(SAGE, IVORY, 0.4))
    d.line([(6, 16), (25, 16)], fill=mix(SAGE, IVORY, 0.4))
    d.ellipse([13, 13, 19, 19], outline=GOLD)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Iron Grate (14)
    k = f"s{sphere_num}:14"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=VOID)
    for g in range(3, 31, 6):
        d.line([(g, 0), (g, 31)], fill=IRON, width=2)
        d.line([(0, g), (31, g)], fill=IRON_DK, width=2)
    d.rectangle([0, 0, 31, 31], outline=IRON_HI)
    for rx, ry in ((2, 2), (28, 2), (2, 28), (28, 28)):
        d.point([(rx, ry)], fill=SILVER)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Hazards: ASH_EMBER (6), RIME_ICE (7), MIASMA (8), SOLAR_GLARE (9)
    k = f"s{sphere_num}:6"
    s.next_tile(k)
    t, d = floor_underlay()
    for x1, y1 in ((5, 9), (17, 11), (8, 22), (21, 25), (14, 16)):
        d.line([(x1, y1), (x1 + 5, y1 - 3)], fill=BLOOD, width=3)
        d.line([(x1 + 1, y1 - 1), (x1 + 4, y1 - 3)], fill=EMBER, width=1)
        d.point([(x1 + 2, y1 - 5)], fill=FALSE_SUN)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:7"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([1, 1, 30, 30], fill=mix(fl_base, RIME, 0.24), outline=mix(RIME, VOID, 0.35))
    d.line([(4, 4), (27, 27)], fill=RIME)
    d.line([(27, 4), (4, 27)], fill=RIME)
    d.line([(16, 3), (16, 28)], fill=IVORY)
    d.line([(3, 16), (28, 16)], fill=RIME)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:8"
    s.next_tile(k)
    t, d = floor_underlay()
    for cx, cy, r in ((10, 12, 6), (21, 15, 6), (15, 22, 5)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=mix(PORPHYRY, MIASMA, 0.45), outline=MIASMA)
    for px_p in ((9, 9), (22, 13), (15, 22), (12, 18)):
        d.point([px_p], fill=LUX)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:9"
    s.next_tile(k)
    t, d = floor_underlay()
    d.ellipse([7, 7, 24, 24], fill=mix(fl_base, FALSE_SUN, 0.34), outline=FALSE_SUN)
    d.line([(16, 2), (16, 29)], fill=FALSE_SUN)
    d.line([(2, 16), (29, 16)], fill=FALSE_SUN)
    d.line([(6, 6), (25, 25)], fill=GOLD)
    d.line([(25, 6), (6, 25)], fill=GOLD)
    d.ellipse([12, 12, 19, 19], fill=IVORY)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    def add_feat(fname: str, drawer) -> None:
        fk = f"s{sphere_num}:{fname}"
        s.next_tile(fk)
        ft = Image.new("RGBA", (32, 32), VOID_T)
        fd = ImageDraw.Draw(ft)
        drawer(fd, ft)
        ft = shade_volume(ft, 0.2)
        ft = outline_sprite(ft)
        s.commit(fk, ft)
        feat_rects[fk] = s.rects[fk]

    def draw_altar(fd, _ft, used: bool):
        col = IRON if used else IVORY
        fd.rectangle([5, 13, 26, 27], fill=IRON_DK, outline=col)
        fd.rectangle([4, 10, 27, 13], fill=col)
        fd.rectangle([12, 14, 19, 26], fill=PORPHYRY if not used else IRON_DK)
        if not used:
            fd.rectangle([8, 6, 9, 9], fill=IVORY)
            fd.rectangle([22, 6, 23, 9], fill=IVORY)
            fd.point([(8, 5), (22, 5)], fill=FALSE_SUN)
            fd.line([(16, 15), (16, 24)], fill=GOLD_HI)
            fd.line([(13, 18), (19, 18)], fill=GOLD_HI)

    add_feat("altar:ready", lambda fd, ft: draw_altar(fd, ft, False))
    add_feat("altar:used", lambda fd, ft: draw_altar(fd, ft, True))

    def draw_shrine(fd, _ft, used: bool):
        col = IRON if used else SAGE
        fd.rectangle([8, 24, 24, 28], fill=IRON_DK, outline=col)
        fd.polygon([(16, 3), (23, 13), (21, 24), (11, 24), (9, 13)], fill=PORPHYRY, outline=col)
        if not used:
            fd.ellipse([12, 9, 20, 16], fill=LUX, outline=IVORY)
            fd.ellipse([15, 11, 17, 14], fill=VOID)

    add_feat("shrine:ready", lambda fd, ft: draw_shrine(fd, ft, False))
    add_feat("shrine:used", lambda fd, ft: draw_shrine(fd, ft, True))

    def draw_circle(fd, _ft, used: bool):
        col = IRON if used else LUX
        fd.ellipse([3, 3, 28, 28], outline=col, width=2)
        fd.polygon([(16, 5), (26, 23), (6, 23)], outline=GOLD if not used else IRON_DK)
        fd.polygon([(16, 27), (26, 9), (6, 9)], outline=SAGE if not used else IRON_DK)
        fd.ellipse([13, 13, 19, 19], fill=PORPHYRY_DK, outline=IVORY if not used else IRON_DK)

    add_feat("ritual_circle:ready", lambda fd, ft: draw_circle(fd, ft, False))
    add_feat("ritual_circle:used", lambda fd, ft: draw_circle(fd, ft, True))

    def draw_vault(fd, _ft, used: bool):
        if not used:
            fd.rectangle([4, 4, 27, 27], fill=IRON_DK, outline=GOLD)
            for gx in (9, 16, 23):
                fd.line([(gx, 5), (gx, 26)], fill=GOLD_HI, width=2)
            fd.rectangle([12, 12, 20, 20], fill=GOLD_DK, outline=FALSE_SUN)
            fd.point([(16, 16)], fill=VOID)
        else:
            fd.rectangle([4, 4, 8, 27], fill=IRON, outline=IRON_HI)
            fd.rectangle([23, 4, 27, 27], fill=IRON, outline=IRON_HI)

    add_feat("vault_gate:ready", lambda fd, ft: draw_vault(fd, ft, False))
    add_feat("vault_gate:used", lambda fd, ft: draw_vault(fd, ft, True))

    def draw_merchant(fd, _ft):
        fd.ellipse([11, 4, 21, 13], fill=PORPHYRY_LT, outline=GOLD)
        fd.polygon([(16, 12), (25, 28), (7, 28)], fill=PORPHYRY, outline=GOLD)
        fd.line([(13, 14), (19, 14)], fill=GOLD_HI)
        fd.line([(23, 11), (23, 25)], fill=RECORD, width=2)
        fd.rectangle([21, 14, 26, 19], fill=FALSE_SUN, outline=GOLD)

    add_feat("merchant:ready", draw_merchant)
    add_feat("merchant:used", draw_merchant)

    def draw_lectern(fd, _ft, used: bool):
        c = IRON if used else LUX
        fd.rectangle([14, 13, 18, 27], fill=IRON)
        fd.rectangle([8, 25, 24, 28], fill=IRON_DK, outline=IRON)
        fd.polygon([(5, 6), (27, 6), (24, 15), (8, 15)], fill=RECORD if not used else IRON, outline=c)
        if not used:
            fd.line([(9, 9), (23, 9)], fill=LUX)
            fd.ellipse([19, 11, 22, 14], fill=BLOOD)

    add_feat("contract_lectern:ready", lambda fd, ft: draw_lectern(fd, ft, False))
    add_feat("contract_lectern:used", lambda fd, ft: draw_lectern(fd, ft, True))

    def draw_bell(fd, _ft, used: bool):
        c = IRON if used else EMBER
        fd.line([(6, 6), (26, 6)], fill=IRON_HI, width=2)
        fd.line([(6, 6), (6, 27)], fill=IRON, width=2)
        fd.line([(26, 6), (26, 27)], fill=IRON, width=2)
        fd.polygon([(16, 7), (23, 22), (9, 22)], fill=GOLD if not used else IRON_DK, outline=c)
        fd.ellipse([14, 22, 18, 26], fill=c)

    add_feat("challenge:ready", lambda fd, ft: draw_bell(fd, ft, False))
    add_feat("challenge:used", lambda fd, ft: draw_bell(fd, ft, True))

    def draw_secret(fd, _ft, used: bool):
        if not used:
            fd.rectangle([3, 3, 28, 28], fill=wl_face, outline=GOLD)
            fd.line([(16, 5), (16, 26)], fill=GOLD)
            fd.ellipse([18, 14, 22, 18], outline=FALSE_SUN)
        else:
            fd.rectangle([4, 4, 8, 27], fill=wl_face)
            fd.rectangle([23, 4, 27, 27], fill=wl_face)

    add_feat("secret_door:ready", lambda fd, ft: draw_secret(fd, ft, False))
    add_feat("secret_door:used", lambda fd, ft: draw_secret(fd, ft, True))

    def draw_trap(fd, _ft, used: bool):
        if not used:
            fd.rectangle([6, 21, 26, 24], fill=IRON_DK, outline=IRON_HI)
            fd.polygon([(7, 21), (11, 10), (15, 21)], fill=ALERT, outline=IVORY)
            fd.polygon([(17, 21), (21, 10), (25, 21)], fill=ALERT, outline=IVORY)
        else:
            fd.line([(7, 22), (14, 19)], fill=IRON, width=2)
            fd.line([(18, 19), (25, 22)], fill=IRON, width=2)

    add_feat("trap:ready", lambda fd, ft: draw_trap(fd, ft, False))
    add_feat("trap:used", lambda fd, ft: draw_trap(fd, ft, True))

    def draw_ward(fd, _ft):
        fd.polygon([(16, 4), (27, 16), (16, 28), (5, 16)], outline=LUX, width=2)
        fd.ellipse([11, 11, 21, 21], fill=MIASMA, outline=IVORY)

    add_feat("ward_sigil:ready", draw_ward)
    add_feat("ward_sigil:used", draw_ward)

    def draw_rune_puzzle(fd, _ft, used: bool):
        c = IRON if used else SAGE
        fd.rectangle([7, 5, 25, 27], fill=PORPHYRY, outline=c)
        fd.ellipse([10, 9, 22, 21], outline=c)
        fd.line([(16, 7), (16, 23)], fill=GOLD_HI if not used else IRON)

    add_feat("rune_puzzle:ready", lambda fd, ft: draw_rune_puzzle(fd, ft, False))
    add_feat("rune_puzzle:used", lambda fd, ft: draw_rune_puzzle(fd, ft, True))

    def draw_abandoned_rite(fd, _ft, used: bool):
        c = IRON if used else LUX
        fd.ellipse([5, 5, 26, 26], outline=c)
        fd.line([(8, 24), (24, 8)], fill=GOLD if not used else IRON_DK, width=2)
        fd.point([(9, 9), (23, 23)], fill=IVORY if not used else IRON)

    add_feat("abandoned_rite:ready", lambda fd, ft: draw_abandoned_rite(fd, ft, False))
    add_feat("abandoned_rite:used", lambda fd, ft: draw_abandoned_rite(fd, ft, True))

    def draw_hearth(fd, _ft, used: bool):
        fd.ellipse([5, 15, 27, 28], fill=IRON_DK, outline=IRON_HI)
        if not used:
            fd.polygon([(16, 4), (23, 19), (9, 19)], fill=EMBER)
            fd.polygon([(16, 9), (20, 19), (12, 19)], fill=FALSE_SUN)
            fd.polygon([(16, 13), (18, 19), (14, 19)], fill=IVORY)

    add_feat("sanctuary_hearth:ready", lambda fd, ft: draw_hearth(fd, ft, False))
    add_feat("sanctuary_hearth:used", lambda fd, ft: draw_hearth(fd, ft, True))

    def draw_echo_cache(fd, _ft, used: bool):
        c = IRON if used else SILVER
        fd.rectangle([7, 7, 25, 25], fill=VOID, outline=c)
        if not used:
            fd.rectangle([10, 10, 22, 22], fill=PORPHYRY_DK, outline=LUX)
            fd.line([(12, 14), (20, 14)], fill=IVORY)
            fd.line([(12, 18), (18, 18)], fill=SILVER)

    add_feat("echo_cache:ready", lambda fd, ft: draw_echo_cache(fd, ft, False))
    add_feat("echo_cache:used", lambda fd, ft: draw_echo_cache(fd, ft, True))

    return s, tile_rects, feat_rects


def draw_avatars_full() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(8, 4, 32)
    rects: dict[str, list[int]] = {}

    origin_styles = {
        "human": (RECORD, PORPHYRY, GOLD, "hood"),
        "revenant": (SILVER, IRON_DK, SILVER_DK, "shroud"),
        "cambion": (BLOOD, PORPHYRY_LT, EMBER, "horned"),
        "ashborn": (EMBER, (56, 30, 26, 255), GOLD_HI, "cowl"),
        "veilkin": (MIASMA, (32, 22, 46, 255), LUX, "veil"),
        "ironbound_ward": (IRON_HI, IRON_DK, GOLD, "sallet"),
        "unrecorded": (TEXT_DIM, (36, 36, 42, 255), SILVER_DK, "tattered"),
        "penitent": (IVORY, BLOOD_DK, GOLD, "habit"),
    }

    def make_origin(key: str, head_c, body_c, trim_c, style: str):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        # Contact shadow
        d.ellipse([8, 26, 24, 30], fill=(8, 6, 9, 150))
        # Boots
        d.rectangle([11, 25, 14, 28], fill=IRON_DK)
        d.rectangle([18, 25, 21, 28], fill=IRON_DK)
        # Cloak & torso silhouette (humanoid shoulders + tapered robe)
        d.polygon([(12, 12), (20, 12), (24, 26), (8, 26)], fill=body_c, outline=trim_c)
        d.rectangle([13, 13, 19, 22], fill=mix(body_c, trim_c, 0.18))
        d.line([(16, 13), (16, 25)], fill=trim_c)
        # Belt
        d.line([(11, 19), (21, 19)], fill=trim_c)
        # Head / helm / hood
        d.ellipse([12, 4, 20, 12], fill=head_c, outline=trim_c)
        if style == "horned":
            d.line([(12, 6), (9, 2)], fill=EMBER, width=2)
            d.line([(20, 6), (23, 2)], fill=EMBER, width=2)
        elif style == "sallet":
            d.rectangle([11, 4, 21, 9], fill=IRON_HI, outline=GOLD)
            d.line([(12, 8), (20, 8)], fill=VOID)
        elif style == "shroud":
            d.polygon([(16, 3), (22, 10), (10, 10)], outline=SILVER)
            d.line([(13, 10), (19, 10)], fill=RECORD)
        elif style == "veil":
            d.polygon([(16, 2), (22, 13), (10, 13)], outline=LUX)
            d.line([(12, 9), (20, 9)], fill=LUX)
        elif style == "habit":
            d.rectangle([11, 11, 21, 13], fill=GOLD)
        else:
            d.arc([11, 3, 21, 12], 170, 370, fill=trim_c, width=2)
        # Eyes
        if style != "sallet":
            d.point([(14, 8), (18, 8)], fill=FALSE_SUN if style == "horned" else IVORY)
        t = shade_volume(t, 0.22)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_origin("origin:default", SILVER, PORPHYRY, GOLD, "hood")
    for sp, cols in origin_styles.items():
        make_origin(f"origin:{sp}", *cols)

    calling_styles = {
        "fallen_knight": (IRON_HI, SILVER, "blade"),
        "occultist": (LUX, GOLD_HI, "rod"),
        "assassin": (IRON_DK, ALERT, "dagger"),
        "preliator_warden": (GOLD, IRON_HI, "shield"),
        "tithe_marksman": (RECORD, GOLD, "bow"),
        "rite_weaver": (LUX, IVORY, "scroll"),
        "false_light_alchemist": (FALSE_SUN, EMBER, "flask"),
        "ophite_binder": (SAGE, LUX, "coil"),
    }

    def make_calling(key: str, col, wep_col, shape):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        # Surcoat / stole accent down chest
        d.line([(16, 13), (16, 24)], fill=col, width=2)
        d.point([(13, 13), (19, 13)], fill=col)
        if shape == "blade":
            d.line([(24, 6), (24, 22)], fill=wep_col, width=2)
            d.line([(21, 19), (27, 19)], fill=GOLD_HI)
            d.point([(24, 23)], fill=GOLD)
        elif shape == "rod":
            d.line([(24, 7), (24, 26)], fill=GOLD, width=2)
            d.ellipse([21, 3, 27, 9], fill=PORPHYRY_DK, outline=LUX)
            d.point([(24, 6)], fill=IVORY)
        elif shape == "dagger":
            d.line([(22, 14), (27, 21)], fill=wep_col, width=2)
            d.line([(6, 15), (10, 21)], fill=SILVER, width=2)
        elif shape == "shield":
            d.polygon([(4, 12), (11, 12), (11, 21), (7, 25), (4, 21)], fill=IRON_DK, outline=col)
            d.line([(7, 14), (7, 22)], fill=col)
            d.line([(24, 9), (24, 25)], fill=wep_col, width=2)
        elif shape == "bow":
            d.arc([20, 7, 28, 24], 270, 90, fill=wep_col, width=2)
            d.line([(24, 8), (24, 23)], fill=RECORD)
        elif shape == "scroll":
            d.rectangle([4, 13, 10, 22], fill=RECORD, outline=col)
            d.line([(24, 11), (24, 20)], fill=GOLD)
            d.ellipse([22, 19, 26, 24], fill=FALSE_SUN, outline=GOLD)
        elif shape == "flask":
            d.ellipse([21, 16, 28, 23], fill=FALSE_SUN, outline=IVORY)
            d.rectangle([23, 13, 26, 16], fill=RECORD)
        elif shape == "coil":
            d.arc([20, 11, 28, 22], 0, 300, fill=SAGE, width=2)
            d.point([(24, 11)], fill=LUX)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_calling("calling:default", GOLD, SILVER, "blade")
    for cl, (col, wep_col, shape) in calling_styles.items():
        make_calling(f"calling:{cl}", col, wep_col, shape)

    for mk, mcol in (
        ("bare_face", VOID_T),
        ("nyx", SILVER),
        ("eris", BLOOD),
        ("lilith", LUX),
        ("lux_venefica", GOLD_HI),
    ):
        k = f"mask:{mk}"
        s.next_tile(k)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if mk == "nyx":
            d.arc([11, 5, 21, 12], 180, 360, fill=SILVER, width=2)
            d.line([(12, 8), (20, 8)], fill=SILVER)
        elif mk == "eris":
            d.polygon([(12, 6), (20, 6), (16, 12)], fill=BLOOD, outline=ALERT)
            d.line([(12, 6), (10, 3)], fill=ALERT)
            d.line([(20, 6), (22, 3)], fill=ALERT)
        elif mk == "lilith":
            d.ellipse([11, 5, 21, 12], outline=LUX)
            d.ellipse([14, 5, 18, 9], fill=LUX, outline=IVORY)
        elif mk == "lux_venefica":
            d.arc([7, 1, 25, 16], 170, 370, fill=GOLD_HI, width=2)
            d.arc([9, 3, 23, 14], 180, 360, fill=LUX, width=1)
            d.ellipse([14, 3, 18, 7], fill=FALSE_SUN)
        s.commit(k, t)
        rects[k] = s.rects[key if False else k]

    return s, rects


def _draw_boss_bespoke(d: ImageDraw.ImageDraw, mid: str, col: tuple) -> None:
    """Bespoke 26-30px silhouettes grounded on octagonal boss seal pedestals."""
    d.ellipse([4, 24, 28, 30], fill=PORPHYRY_DK, outline=GOLD_HI)
    d.line([(6, 27), (26, 27)], fill=GOLD_DK)
    if mid == "alley_rat_matriarch":
        d.ellipse([5, 14, 23, 26], fill=sh(col, 0.25), outline=col)
        d.ellipse([18, 10, 27, 18], fill=col, outline=ALERT)
        d.polygon([(20, 9), (22, 5), (24, 10)], fill=BLOOD)
        d.line([(3, 20), (8, 17)], fill=ALERT, width=2)
        d.point([(24, 13)], fill=FALSE_SUN)
    elif mid == "chapel_penitent_warden":
        d.polygon([(16, 8), (25, 27), (7, 27)], fill=PORPHYRY, outline=col)
        d.ellipse([12, 3, 20, 11], fill=IRON_HI, outline=GOLD)
        d.line([(6, 8), (6, 26)], fill=GOLD_HI, width=2)
        d.line([(25, 12), (28, 22)], fill=BLOOD, width=2)
    elif mid == "vault_enumerator":
        d.rectangle([9, 10, 23, 26], fill=IRON_DK, outline=GOLD_HI)
        d.polygon([(12, 3), (20, 3), (21, 10), (11, 10)], fill=GOLD, outline=IVORY)
        d.line([(6, 9), (26, 9)], fill=FALSE_SUN, width=2)
        d.ellipse([4, 11, 9, 16], outline=GOLD_HI)
        d.ellipse([23, 11, 28, 16], outline=GOLD_HI)
    elif mid == "archivist_severin":
        d.polygon([(16, 7), (24, 27), (8, 27)], fill=PORPHYRY_LT, outline=SILVER)
        d.rectangle([12, 3, 20, 9], fill=RECORD, outline=LUX)
        d.rectangle([5, 12, 11, 20], fill=IVORY, outline=GOLD)
        d.line([(24, 7), (24, 26)], fill=LUX, width=2)
    elif mid == "choir_cantor_prime":
        d.polygon([(16, 9), (25, 27), (7, 27)], fill=PORPHYRY, outline=GOLD_HI)
        d.polygon([(16, 1), (21, 10), (11, 10)], fill=GOLD, outline=IVORY)
        d.line([(6, 6), (6, 25)], fill=FALSE_SUN, width=2)
        d.ellipse([23, 13, 28, 19], fill=FALSE_SUN, outline=GOLD)
    elif mid == "master_smelter_prosay":
        d.rectangle([8, 10, 24, 26], fill=BLOOD_DK, outline=EMBER)
        d.ellipse([11, 3, 21, 11], fill=EMBER, outline=FALSE_SUN)
        d.line([(25, 4), (25, 26)], fill=FALSE_SUN, width=2)
        d.ellipse([22, 3, 28, 9], fill=EMBER, outline=IVORY)
    elif mid == "cantor_helios_prime":
        d.polygon([(16, 8), (24, 27), (8, 27)], fill=GOLD_DK, outline=FALSE_SUN)
        d.ellipse([11, 2, 21, 12], fill=FALSE_SUN, outline=IVORY)
        d.line([(5, 14), (27, 14)], fill=FALSE_SUN)
    elif mid == "marshal_krell":
        d.rectangle([9, 10, 23, 26], fill=IRON, outline=ALERT)
        d.rectangle([11, 3, 21, 10], fill=IRON_HI, outline=GOLD)
        d.line([(5, 4), (5, 26)], fill=SILVER, width=2)
        d.polygon([(3, 4), (9, 7), (5, 12)], fill=BLOOD)
    elif mid == "iron_auditor":
        d.rectangle([8, 8, 24, 26], fill=IRON_DK, outline=IRON_HI)
        d.rectangle([11, 4, 21, 10], fill=IRON_HI, outline=GOLD_HI)
        d.line([(12, 16), (20, 16)], fill=GOLD_HI, width=2)
        d.line([(26, 6), (26, 26)], fill=SILVER, width=2)
    elif mid == "binder_malakor":
        d.polygon([(16, 3), (27, 16), (16, 28), (5, 16)], fill=VOID, outline=LUX)
        d.ellipse([11, 10, 21, 20], fill=LUX, outline=IVORY)
        d.line([(6, 8), (26, 24)], fill=SILVER)
        d.line([(26, 8), (6, 24)], fill=SILVER)
    elif mid == "commander_voss":
        d.rectangle([9, 10, 23, 26], fill=PORPHYRY, outline=GOLD_HI)
        d.polygon([(11, 3), (21, 3), (22, 10), (10, 10)], fill=GOLD, outline=IVORY)
        d.polygon([(3, 12), (9, 12), (9, 23), (3, 23)], fill=IRON_DK, outline=GOLD_HI)
        d.line([(25, 5), (25, 25)], fill=SILVER, width=2)
    elif mid == "decreer_octavius":
        d.polygon([(16, 8), (25, 27), (7, 27)], fill=PORPHYRY_LT, outline=GOLD_HI)
        d.polygon([(10, 8), (12, 2), (16, 6), (20, 2), (22, 8)], fill=FALSE_SUN, outline=IVORY)
        d.line([(6, 6), (6, 26)], fill=GOLD_HI, width=2)
    elif mid == "forge_warden_cyrus":
        d.rectangle([7, 9, 25, 26], fill=IRON_DK, outline=EMBER)
        d.rectangle([11, 3, 21, 9], fill=EMBER, outline=GOLD_HI)
        d.line([(26, 5), (26, 25)], fill=IRON_HI, width=3)
        d.rectangle([22, 5, 29, 10], fill=EMBER, outline=GOLD)
    elif mid == "jailer_of_the_seventh":
        d.polygon([(16, 8), (24, 27), (8, 27)], fill=IRON_DK, outline=SILVER)
        d.ellipse([11, 2, 21, 10], fill=RECORD, outline=ALERT)
        d.line([(6, 10), (10, 25)], fill=IRON_HI, width=2)
        d.ellipse([22, 12, 27, 17], outline=GOLD_HI, width=2)
    elif mid == "preliator_sentinel":
        d.polygon([(16, 6), (26, 26), (6, 26)], fill=PORPHYRY_DK, outline=FALSE_SUN)
        d.rectangle([10, 10, 22, 24], fill=IRON_DK, outline=GOLD_HI)
        d.polygon([(11, 3), (16, 0), (21, 3), (20, 10), (12, 10)], fill=FALSE_SUN, outline=IVORY)
        d.line([(4, 4), (4, 27)], fill=LUX, width=2)
        d.line([(27, 4), (27, 27)], fill=GOLD_HI, width=2)
        d.ellipse([13, 13, 19, 19], fill=LUX, outline=IVORY)


def draw_monsters_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "monsters.json").read_text())["entries"]
    s = Sheet(12, 10, 32)
    rects: dict[str, list[int]] = {}

    def render_mon(key: str, shape: str, fill_c, accent_c, boss: bool = False, mid: str = "", glyph: str = ""):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if boss and mid:
            _draw_boss_bespoke(d, mid, accent_c)
        else:
            d.ellipse([9, 26, 23, 29], fill=(8, 6, 9, 140))
            if shape == "beast":
                d.ellipse([7, 15, 22, 25], fill=fill_c, outline=accent_c)
                d.ellipse([18, 11, 26, 19], fill=fill_c, outline=accent_c)
                d.line([(4, 20), (8, 17)], fill=accent_c, width=2)
                d.line([(10, 24), (10, 27)], fill=accent_c, width=2)
                d.line([(19, 24), (19, 27)], fill=accent_c, width=2)
                d.point([(23, 14)], fill=ALERT)
            elif shape == "undead":
                d.polygon([(13, 11), (19, 11), (23, 27), (9, 27)], fill=fill_c, outline=accent_c)
                d.line([(13, 14), (19, 14)], fill=RECORD)
                d.line([(13, 17), (19, 17)], fill=RECORD)
                d.ellipse([12, 4, 20, 11], fill=RECORD, outline=accent_c)
                d.point([(14, 7), (18, 7)], fill=VOID)
                if glyph == "a":
                    d.arc([20, 10, 27, 22], 270, 90, fill=GOLD, width=2)
            elif shape == "soldier":
                d.rectangle([10, 11, 22, 26], fill=fill_c, outline=accent_c)
                d.polygon([(12, 4), (20, 4), (21, 11), (11, 11)], fill=IRON_HI, outline=accent_c)
                d.line([(12, 8), (20, 8)], fill=VOID)
                d.line([(25, 5), (25, 26)], fill=SILVER, width=2)
                d.polygon([(23, 5), (27, 5), (25, 2)], fill=SILVER)
            elif shape == "inquisition":
                d.polygon([(16, 9), (25, 27), (7, 27)], fill=fill_c, outline=accent_c)
                d.polygon([(16, 2), (21, 10), (11, 10)], fill=accent_c, outline=GOLD)
                d.line([(6, 10), (6, 26)], fill=FALSE_SUN, width=2)
                d.point([(14, 8), (18, 8)], fill=IVORY)
            elif shape == "radiant":
                d.polygon([(16, 3), (24, 15), (16, 27), (8, 15)], fill=fill_c, outline=FALSE_SUN)
                d.line([(5, 15), (27, 15)], fill=FALSE_SUN)
                d.ellipse([13, 12, 19, 18], fill=IVORY, outline=GOLD)
            elif shape == "construct":
                d.rectangle([8, 8, 24, 27], fill=fill_c, outline=accent_c)
                d.rectangle([11, 11, 21, 15], fill=accent_c)
                d.line([(8, 20), (24, 20)], fill=GOLD)
                d.rectangle([10, 5, 22, 8], fill=IRON_HI, outline=accent_c)
            elif shape == "geometry":
                d.polygon([(16, 3), (27, 16), (16, 28), (5, 16)], fill=VOID, outline=accent_c)
                d.polygon([(16, 7), (23, 16), (16, 24), (9, 16)], outline=GOLD)
                d.ellipse([12, 12, 20, 20], fill=LUX, outline=IVORY)
            elif shape == "serpent":
                d.arc([6, 8, 25, 26], 10, 290, fill=fill_c, width=4)
                d.ellipse([18, 6, 25, 13], fill=accent_c, outline=IVORY)
                d.point([(22, 8)], fill=ALERT)
            else:
                d.polygon([(16, 5), (25, 17), (22, 27), (10, 27), (7, 17)], fill=fill_c, outline=accent_c)
                d.point([(14, 13), (18, 13)], fill=FALSE_SUN)
        t = shade_volume(t, 0.2)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    render_mon("default", "undead", IRON, RECORD)
    tag_shapes = {
        "vermin": ("beast", TEXT_DIM, BLOOD),
        "undead": ("undead", IRON_DK, RECORD),
        "dominion": ("soldier", IRON, GOLD),
        "inquisition": ("inquisition", PORPHYRY_LT, FALSE_SUN),
        "false_sun": ("radiant", GOLD, FALSE_SUN),
        "contract_bound": ("inquisition", BLOOD, GOLD),
        "geometry": ("geometry", PORPHYRY, LUX),
        "unrecorded": ("beast", IRON, SILVER),
        "predator": ("serpent", SAGE_DK, ALERT),
        "construct": ("construct", IRON_HI, FALSE_SUN),
    }
    for tg, (sh_name, fc, ac) in tag_shapes.items():
        render_mon(f"tag:{tg}", sh_name, fc, ac)

    for e in data:
        mid = e["id"]
        tags = set(e.get("tags", []))
        is_boss = "boss" in tags or bool(e.get("unique", False))
        col = hex_rgba(e.get("color", ""), SILVER)
        glyph = str(e.get("glyph", ""))
        shape = "construct"
        if is_boss:
            shape = "boss"
        elif "vermin" in tags or glyph in ("r", "R", "f", "m", "x"):
            shape = "beast"
        elif "undead" in tags:
            shape = "undead"
        elif "inquisition" in tags:
            shape = "inquisition"
        elif "dominion" in tags:
            shape = "soldier"
        elif "false_sun" in tags:
            shape = "radiant"
        elif "geometry" in tags or "rogue_geometry" in tags:
            shape = "geometry"
        elif "predator" in tags or glyph in ("w", "s", "S"):
            shape = "serpent"
        render_mon(mid, shape, mix(col, VOID, 0.34), col, boss=is_boss, mid=mid, glyph=glyph)

    return s, rects


def draw_npcs_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "npcs.json").read_text())["entries"]
    s = Sheet(6, 4, 32)
    rects: dict[str, list[int]] = {}

    faction_colors = {
        "inquisition_two_minds": PORPHYRY_LT,
        "office_of_seals": GOLD,
        "readers_circles": LUX,
        "guild_and_ring": EMBER,
        "cellar_and_street": SILVER,
        "day_house_almoners": SAGE,
        "choir_disaffected": RECORD,
        "ophite_witnesses": MIASMA,
    }

    def make_npc(key: str, cloak_c, accent_c, idx: int):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.ellipse([9, 26, 23, 29], fill=(8, 6, 9, 140))
        d.polygon([(12, 12), (20, 12), (24, 27), (8, 27)], fill=cloak_c, outline=accent_c)
        d.line([(16, 13), (16, 26)], fill=accent_c)
        d.ellipse([12, 4, 20, 11], fill=IVORY, outline=accent_c)
        d.point([(14, 7), (18, 7)], fill=VOID)
        # Hat / hood variation
        if idx % 3 == 0:
            d.arc([11, 3, 21, 11], 170, 370, fill=accent_c, width=2)
        elif idx % 3 == 1:
            d.line([(10, 5), (22, 5)], fill=accent_c, width=2)
        # Signature prop
        prop = idx % 5
        if prop == 0:
            d.line([(24, 10), (24, 26)], fill=GOLD, width=2)
        elif prop == 1:
            d.rectangle([4, 13, 10, 21], fill=RECORD, outline=LUX)
        elif prop == 2:
            d.ellipse([22, 14, 28, 20], fill=FALSE_SUN, outline=GOLD)
        elif prop == 3:
            d.line([(5, 14), (10, 23)], fill=SILVER, width=2)
        else:
            d.ellipse([4, 15, 10, 21], outline=GOLD_HI, width=2)
        t = shade_volume(t, 0.2)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_npc("default", SAGE_DK, SAGE, 0)
    for idx, e in enumerate(data):
        nid = e["id"]
        fc = faction_colors.get(e.get("faction", ""), SAGE)
        c = hex_rgba(e.get("color", ""), fc)
        make_npc(nid, mix(c, PORPHYRY, 0.48), fc, idx)
    return s, rects


def draw_items_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "items.json").read_text())["entries"]
    s = Sheet(16, 12, 32)
    rects: dict[str, list[int]] = {}

    def draw_it(key: str, kind: str, eff: str, col, iid: str = "", is_art: bool = False):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if kind == "weapon":
            if "mace" in iid or "flail" in iid or "hammer" in iid or "cudgel" in iid or "bell" in iid:
                d.line([(8, 24), (20, 12)], fill=RECORD, width=2)
                d.ellipse([17, 6, 26, 15], fill=col, outline=IVORY)
                d.point([(20, 9)], fill=GOLD_HI)
            elif "halberd" in iid or "spear" in iid or "axe" in iid or "glaive" in iid or "scythe" in iid:
                d.line([(7, 25), (23, 7)], fill=GOLD, width=2)
                d.polygon([(18, 5), (27, 9), (22, 16)], fill=col, outline=IVORY)
            elif "awl" in iid or "knife" in iid or "stiletto" in iid:
                d.line([(10, 22), (22, 10)], fill=col, width=2)
                d.line([(11, 18), (14, 21)], fill=GOLD)
            else:
                d.line([(8, 24), (24, 8)], fill=col, width=3)
                d.line([(9, 23), (23, 9)], fill=hi(col, 0.4), width=1)
                d.line([(9, 17), (15, 23)], fill=GOLD_HI, width=2)
        elif kind == "ranged":
            if "rod" in iid or "focus" in iid or "staff" in iid or "prism" in iid or "pointer" in iid or "spindle" in iid:
                d.line([(9, 24), (22, 9)], fill=GOLD, width=2)
                d.ellipse([18, 5, 26, 13], fill=col, outline=LUX)
                d.point([(21, 8)], fill=IVORY)
            else:
                d.arc([8, 6, 22, 26], 270, 90, fill=col, width=2)
                d.line([(15, 7), (15, 25)], fill=RECORD)
                d.line([(12, 16), (23, 16)], fill=SILVER)
        elif kind == "armor":
            d.polygon([(9, 8), (23, 8), (25, 14), (21, 25), (11, 25), (7, 14)], fill=col, outline=SILVER)
            d.line([(16, 9), (16, 24)], fill=GOLD)
            d.line([(10, 14), (22, 14)], fill=sh(col, 0.35))
        elif kind == "amulet":
            d.ellipse([11, 6, 21, 16], outline=GOLD_HI, width=2)
            d.ellipse([12, 15, 20, 24], fill=col, outline=IVORY)
            d.point([(15, 18)], fill=IVORY)
        elif kind == "key":
            d.ellipse([8, 11, 15, 18], outline=col, width=2)
            d.line([(15, 15), (25, 15)], fill=col, width=2)
            d.line([(20, 15), (20, 20)], fill=col, width=2)
            d.line([(23, 15), (23, 19)], fill=col, width=2)
        elif kind == "relic":
            if "crown" in iid:
                d.polygon([(7, 22), (9, 10), (13, 16), (16, 7), (19, 16), (23, 10), (25, 22)], fill=col, outline=GOLD_HI)
                d.line([(8, 20), (24, 20)], fill=BLOOD)
            elif "halo" in iid:
                d.arc([6, 6, 26, 26], 25, 295, fill=FALSE_SUN, width=3)
                d.point([(10, 10), (22, 22)], fill=IVORY)
            elif "key" in iid:
                d.ellipse([7, 10, 15, 18], outline=LUX, width=2)
                d.line([(15, 14), (25, 14)], fill=GOLD_HI, width=2)
                d.line([(22, 14), (22, 19)], fill=LUX, width=2)
            elif "lamp" in iid:
                d.rectangle([11, 10, 21, 22], fill=FALSE_SUN, outline=GOLD_HI)
                d.line([(16, 6), (16, 10)], fill=IRON_HI, width=2)
                d.rectangle([10, 22, 22, 24], fill=GOLD)
            elif "bell" in iid:
                d.polygon([(16, 7), (23, 21), (9, 21)], fill=col, outline=RIME)
                d.ellipse([14, 21, 18, 24], fill=IVORY)
            elif "mirror" in iid or "glass" in iid or "lens" in iid:
                d.ellipse([8, 7, 24, 23], fill=SILVER, outline=LUX)
                d.line([(12, 11), (19, 18)], fill=IVORY, width=2)
            elif "coin" in iid:
                d.ellipse([8, 8, 24, 24], fill=FALSE_SUN, outline=BLOOD)
                d.ellipse([12, 12, 20, 20], outline=GOLD_DK)
            elif "scourge" in iid:
                d.line([(9, 23), (17, 13)], fill=GOLD_HI, width=2)
                d.line([(17, 13), (24, 9)], fill=BLOOD, width=2)
                d.line([(17, 13), (24, 15)], fill=EMBER, width=2)
            elif "fork" in iid:
                d.line([(16, 16), (16, 26)], fill=GOLD_HI, width=2)
                d.line([(12, 7), (12, 16)], fill=GOLD_HI, width=2)
                d.line([(20, 7), (20, 16)], fill=GOLD_HI, width=2)
                d.line([(12, 16), (20, 16)], fill=GOLD_HI, width=2)
            elif "hourglass" in iid:
                d.polygon([(10, 7), (22, 7), (16, 16)], fill=RECORD, outline=SILVER)
                d.polygon([(10, 25), (22, 25), (16, 16)], fill=IVORY, outline=SILVER)
            elif "purse" in iid:
                d.ellipse([9, 12, 23, 25], fill=SAGE_DK, outline=GOLD)
                d.line([(12, 10), (20, 10)], fill=GOLD_HI, width=2)
            else:
                d.polygon([(16, 6), (24, 16), (16, 26), (8, 16)], fill=col, outline=LUX)
                d.ellipse([13, 13, 19, 19], fill=IVORY)
        elif eff == "scroll":
            d.rectangle([9, 8, 23, 24], fill=RECORD, outline=GOLD)
            d.line([(11, 12), (21, 12)], fill=col)
            d.line([(11, 16), (19, 16)], fill=VOID)
            d.ellipse([18, 18, 22, 22], fill=BLOOD)
        elif eff == "projectile":
            d.line([(8, 23), (22, 9)], fill=SILVER, width=2)
            d.polygon([(24, 7), (18, 8), (23, 13)], fill=col)
            d.line([(7, 21), (10, 24)], fill=BLOOD)
        else:
            d.rectangle([13, 7, 19, 11], fill=RECORD)
            d.ellipse([9, 11, 23, 25], fill=col, outline=IVORY)
            d.point([(13, 15), (14, 14)], fill=IVORY)
        if is_art:
            for pt in ((6, 6), (25, 6), (6, 25), (25, 25)):
                d.point([pt], fill=LUX)
        t = shade_volume(t, 0.2)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    draw_it("default", "amulet", "", GOLD)
    draw_it("kind:weapon", "weapon", "", SILVER)
    draw_it("kind:ranged", "ranged", "", GOLD)
    draw_it("kind:armor", "armor", "", IRON_HI)
    draw_it("kind:amulet", "amulet", "", LUX)
    draw_it("kind:consumable", "consumable", "", BLOOD)
    draw_it("kind:consumable:scroll", "consumable", "scroll", LUX)
    draw_it("kind:consumable:projectile", "consumable", "projectile", ALERT)
    draw_it("kind:relic", "relic", "", FALSE_SUN)
    draw_it("kind:key", "key", "", GOLD_HI)

    for e in data:
        iid = e["id"]
        kind = e.get("kind", "consumable")
        eff = e.get("effect", "")
        col = hex_rgba(e.get("color", ""), GOLD)
        is_art = e.get("rarity", "") == "artifact"
        draw_it(iid, kind, eff, col, iid=iid, is_art=is_art)

    return s, rects


def draw_icons_16() -> tuple[Sheet, dict[str, list[int]], dict[str, list[int]]]:
    statuses = json.loads((CORE / "statuses.json").read_text())["entries"]
    talents = json.loads((CORE / "talents.json").read_text())["entries"]
    contracts = json.loads((CORE / "contracts.json").read_text())["entries"]
    trees = sorted(set(t["tree"] for t in talents))
    elites = ["ashen", "rime-bound", "apostate", "ironbound", "radiant", "swift", "vampiric", "warded", "default"]
    chains = ["chain_isolation", "chain_fog", "chain_debility", "chain_threat", "chain_indulgence", "chain_omnipotence", "chain_degradation", "chain_trivial"]

    s = Sheet(16, 8, 16)
    status_rects: dict[str, list[int]] = {}
    icon_rects: dict[str, list[int]] = {}

    def make_ic(key: str, col, mode: str, store: dict):
        s.next_tile(key)
        t = Image.new("RGBA", (16, 16), VOID_T)
        d = ImageDraw.Draw(t)
        d.rectangle([1, 1, 14, 14], fill=PORPHYRY_DK, outline=col)
        d.rectangle([2, 2, 13, 13], outline=sh(col, 0.5))
        if mode == "diamond":
            d.polygon([(8, 3), (12, 8), (8, 13), (4, 8)], fill=col, outline=IVORY)
        elif mode == "cross":
            d.line([(8, 3), (8, 12)], fill=col, width=2)
            d.line([(4, 7), (12, 7)], fill=col, width=2)
        elif mode == "ring":
            d.ellipse([4, 4, 11, 11], outline=col, width=2)
            d.point([(8, 8)], fill=IVORY)
        else:
            d.polygon([(8, 3), (12, 12), (4, 12)], fill=col, outline=IVORY)
        s.commit(key, t)
        store[key] = s.rects[key]

    make_ic("default", SILVER, "ring", status_rects)
    for idx, st in enumerate(statuses):
        sid = st["id"]
        col = hex_rgba(st.get("color", ""), FALSE_SUN)
        mode = ["diamond", "cross", "ring", "tri"][idx % 4]
        make_ic(sid, col, mode, status_rects)

    make_ic("default", GOLD, "diamond", icon_rects)
    for idx, tr in enumerate(trees):
        col = [GOLD_HI, LUX, SAGE, SILVER, EMBER, RIME][idx % 6]
        make_ic(f"tree:{tr}", col, ["diamond", "cross", "ring", "tri"][idx % 4], icon_rects)
    for idx, el in enumerate(elites):
        make_ic(f"elite:{el}", [EMBER, RIME, LUX, IRON_HI, FALSE_SUN, SAGE, BLOOD, SILVER, GOLD][idx % 9], "tri", icon_rects)
    for idx, ch in enumerate(chains):
        make_ic(f"chain:{ch}", LUX if idx % 2 == 0 else ALERT, "cross", icon_rects)
    for ct in contracts:
        make_ic(f"contract:{ct['id']}", GOLD_HI, "diamond", icon_rects)

    return s, status_rects, icon_rects


def _draw_emblem_art(d: ImageDraw.ImageDraw, key: str, bg, ring, inner) -> None:
    """Draws 24 distinct liturgical woodcut emblems (64x64)."""
    d.ellipse([2, 2, 61, 61], fill=bg, outline=ring, width=3)
    d.ellipse([7, 7, 56, 56], outline=mix(ring, VOID, 0.45), width=1)
    # Woodcut radial ticks
    for deg in range(0, 360, 30):
        rad = math.radians(deg)
        x1 = int(32 + math.cos(rad) * 24)
        y1 = int(32 + math.sin(rad) * 24)
        x2 = int(32 + math.cos(rad) * 27)
        y2 = int(32 + math.sin(rad) * 27)
        d.line([(x1, y1), (x2, y2)], fill=mix(ring, VOID, 0.35), width=1)

    if key == "title_crest":
        # Crowned Eye over octagonal seal & crossed keys
        d.polygon([(32, 9), (53, 32), (32, 55), (11, 32)], outline=GOLD_HI, width=2)
        d.line([(16, 48), (48, 16)], fill=IRON_HI, width=2)
        d.line([(16, 16), (48, 48)], fill=IRON_HI, width=2)
        d.arc([13, 21, 51, 43], 190, 350, fill=IVORY, width=2)
        d.arc([13, 21, 51, 43], 10, 170, fill=IVORY, width=2)
        d.ellipse([25, 25, 39, 39], fill=LUX, outline=IVORY)
        d.ellipse([30, 30, 34, 34], fill=VOID)
        d.polygon([(22, 18), (26, 11), (32, 15), (38, 11), (42, 18)], fill=FALSE_SUN, outline=GOLD)
    elif key == "sphere_1":  # Moon: crescent over ossuary skull/ledger
        d.arc([15, 13, 45, 43], 40, 260, fill=SILVER, width=4)
        d.rectangle([24, 36, 40, 48], fill=IRON_DK, outline=IVORY)
        d.line([(27, 40), (37, 40)], fill=SILVER)
        d.line([(27, 44), (35, 44)], fill=SILVER)
    elif key == "sphere_2":  # Mercury: brass balance scales
        d.line([(32, 14), (32, 48)], fill=GOLD_HI, width=2)
        d.line([(16, 22), (48, 22)], fill=GOLD_HI, width=2)
        d.polygon([(16, 22), (11, 35), (21, 35)], outline=IVORY, width=2)
        d.polygon([(48, 22), (43, 35), (53, 35)], outline=IVORY, width=2)
        d.line([(24, 48), (40, 48)], fill=GOLD, width=2)
    elif key == "sphere_3":  # Venus: gilded chalice & choir veil
        d.polygon([(20, 18), (44, 18), (36, 34), (28, 34)], fill=PORPHYRY_LT, outline=GOLD_HI)
        d.line([(32, 34), (32, 47)], fill=GOLD_HI, width=3)
        d.line([(23, 47), (41, 47)], fill=GOLD_HI, width=2)
        d.ellipse([28, 12, 36, 20], outline=LUX, width=2)
    elif key == "sphere_4":  # Sun: eclipsed counterfeit sun with rays
        for deg in range(0, 360, 45):
            rad = math.radians(deg)
            d.line([(32, 32), (int(32 + math.cos(rad) * 20), int(32 + math.sin(rad) * 20))], fill=FALSE_SUN, width=2)
        d.ellipse([21, 21, 43, 43], fill=FALSE_SUN, outline=IVORY)
        d.ellipse([25, 25, 39, 39], fill=VOID, outline=BLOOD)
    elif key == "sphere_5":  # Mars: iron anvil & broken chain
        d.polygon([(15, 26), (49, 26), (42, 36), (22, 36)], fill=IRON_HI, outline=EMBER)
        d.rectangle([25, 36, 39, 47], fill=IRON_DK, outline=EMBER)
        d.ellipse([21, 14, 31, 23], outline=ALERT, width=2)
        d.ellipse([33, 14, 43, 23], outline=ALERT, width=2)
    elif key == "sphere_6":  # Jupiter: porphyry decree seal & crown
        d.polygon([(18, 38), (21, 20), (27, 29), (32, 15), (37, 29), (43, 20), (46, 38)], fill=GOLD, outline=IVORY)
        d.rectangle([21, 41, 43, 48], fill=BLOOD, outline=GOLD_HI)
    elif key == "sphere_7":  # Saturn: sealed black stair & hourglass
        d.polygon([(19, 15), (45, 15), (32, 32)], fill=VOID, outline=LUX)
        d.polygon([(19, 49), (45, 49), (32, 32)], fill=VOID, outline=LUX)
        d.line([(16, 32), (48, 32)], fill=IVORY, width=1)
    elif key == "boss_seal":
        d.polygon([(32, 10), (52, 22), (52, 42), (32, 54), (12, 42), (12, 22)], fill=BLOOD_DK, outline=FALSE_SUN, width=2)
        d.polygon([(20, 40), (24, 22), (32, 28), (40, 22), (44, 40)], fill=FALSE_SUN, outline=ALERT)
    elif key == "way_serpent":
        d.arc([14, 14, 50, 50], 20, 310, fill=SAGE, width=4)
        d.polygon([(46, 25), (54, 21), (50, 32)], fill=LUX, outline=IVORY)
        d.ellipse([26, 26, 38, 38], outline=LUX, width=2)
    elif key == "way_return":
        d.arc([18, 14, 46, 42], 180, 360, fill=SAGE, width=3)
        d.rectangle([18, 28, 46, 50], outline=SAGE, width=2)
        d.line([(32, 22), (32, 46)], fill=IVORY, width=2)
        d.polygon([(32, 18), (27, 25), (37, 25)], fill=IVORY)
    elif key == "unwritten_door":
        d.rectangle([20, 14, 44, 50], fill=VOID, outline=IVORY, width=2)
        d.line([(32, 16), (32, 48)], fill=SAGE)
        d.ellipse([28, 28, 36, 36], fill=SAGE, outline=IVORY)
    elif key == "by_decree":
        d.polygon([(16, 44), (19, 20), (26, 30), (32, 14), (38, 30), (45, 20), (48, 44)], fill=GOLD_HI, outline=FALSE_SUN)
        d.rectangle([22, 45, 42, 50], fill=IRON_HI, outline=IVORY)
    elif key == "loss_catalogued":
        d.rectangle([19, 15, 45, 49], fill=RECORD, outline=IRON_HI)
        d.line([(23, 23), (41, 23)], fill=VOID, width=2)
        d.line([(23, 30), (41, 30)], fill=VOID, width=2)
        d.line([(22, 18), (42, 46)], fill=BLOOD, width=3)
    elif key == "loss_fluent":
        d.ellipse([18, 16, 46, 46], fill=PORPHYRY_DK, outline=LUX, width=2)
        d.line([(26, 17), (35, 45)], fill=ALERT, width=2)
        d.ellipse([27, 27, 37, 37], fill=LUX, outline=IVORY)
    elif key == "loss_gilded":
        d.ellipse([16, 16, 48, 48], fill=FALSE_SUN, outline=BLOOD, width=3)
        d.line([(22, 22), (42, 42)], fill=BLOOD, width=3)
        d.line([(42, 22), (22, 42)], fill=BLOOD, width=3)
    else:
        # 8 distinct faction seals (two-pole heraldry)
        fmap = {
            "faction:inquisition_two_minds": "split_eye",
            "faction:office_of_seals": "wax_stamp",
            "faction:readers_circles": "open_folio",
            "faction:guild_and_ring": "ring_hammer",
            "faction:cellar_and_street": "key_ladder",
            "faction:day_house_almoners": "bowl_hearth",
            "faction:choir_disaffected": "split_bell",
            "faction:ophite_witnesses": "serpent_eye",
        }
        kind = fmap.get(key, "split_eye")
        if kind == "split_eye":
            d.line([(32, 13), (32, 51)], fill=ring, width=2)
            d.ellipse([19, 22, 45, 42], outline=inner, width=2)
            d.ellipse([28, 28, 36, 36], fill=LUX)
        elif kind == "wax_stamp":
            d.polygon([(32, 13), (48, 32), (32, 51), (16, 32)], fill=BLOOD_DK, outline=GOLD_HI)
            d.ellipse([25, 25, 39, 39], outline=GOLD_HI, width=2)
        elif kind == "open_folio":
            d.rectangle([16, 20, 31, 44], fill=RECORD, outline=LUX)
            d.rectangle([33, 20, 48, 44], fill=RECORD, outline=SILVER)
        elif kind == "ring_hammer":
            d.ellipse([20, 20, 44, 44], outline=GOLD_HI, width=3)
            d.line([(18, 46), (46, 18)], fill=EMBER, width=3)
        elif kind == "key_ladder":
            d.ellipse([18, 24, 28, 34], outline=SILVER, width=2)
            d.line([(28, 29), (46, 29)], fill=SILVER, width=3)
            d.line([(40, 29), (40, 36)], fill=SILVER, width=2)
        elif kind == "bowl_hearth":
            d.chord([18, 24, 46, 48], 0, 180, fill=SAGE, outline=IVORY)
            d.polygon([(32, 14), (37, 24), (27, 24)], fill=EMBER)
        elif kind == "split_bell":
            d.polygon([(32, 14), (44, 40), (20, 40)], fill=GOLD_DK, outline=IVORY)
            d.line([(32, 14), (32, 42)], fill=VOID, width=2)
        else:
            d.arc([16, 16, 48, 48], 30, 320, fill=MIASMA, width=3)
            d.ellipse([26, 26, 38, 38], fill=LUX, outline=IVORY)


def draw_emblems_64() -> tuple[Sheet, dict[str, list[int]]]:
    factions = json.loads((CORE / "factions.json").read_text())["entries"]
    s = Sheet(6, 4, 64)
    rects: dict[str, list[int]] = {}

    def make_emb(key: str, bg, ring, inner):
        s.next_tile(key)
        t = Image.new("RGBA", (64, 64), VOID_T)
        d = ImageDraw.Draw(t)
        _draw_emblem_art(d, key, bg, ring, inner)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_emb("title_crest", PORPHYRY, GOLD_HI, IVORY)
    for sn in range(1, 8):
        col = [SILVER, GOLD, PORPHYRY_LT, FALSE_SUN, EMBER, MIASMA, LUX][sn - 1]
        make_emb(f"sphere_{sn}", VOID, col, IVORY)
    for idx, f in enumerate(factions):
        make_emb(f"faction:{f['id']}", PORPHYRY, [GOLD, SILVER, LUX, SAGE][idx % 4], IVORY)
    make_emb("boss_seal", BLOOD, ALERT, FALSE_SUN)
    make_emb("way_serpent", PORPHYRY, LUX, SAGE)
    make_emb("way_return", IRON_DK, SAGE, IVORY)
    make_emb("unwritten_door", VOID, SAGE, IVORY)
    make_emb("by_decree", PORPHYRY_LT, FALSE_SUN, GOLD_HI)
    make_emb("loss_catalogued", IRON_DK, RECORD, SILVER)
    make_emb("loss_fluent", PORPHYRY, LUX, ALERT)
    make_emb("loss_gilded", PORPHYRY, FALSE_SUN, BLOOD)

    return s, rects


def draw_app_icons() -> list[dict]:
    """Generates crisp launcher & Android adaptive icon PNGs from Title Crest motif."""
    icons_dir = ASSETS / "icons"
    icons_dir.mkdir(parents=True, exist_ok=True)
    prov: list[dict] = []

    def render_crest_canvas(size: int, bg_fill: tuple, pad_ratio: float = 0.08, draw_bg: bool = True) -> Image.Image:
        base = Image.new("RGBA", (64, 64), bg_fill if draw_bg else VOID_T)
        d = ImageDraw.Draw(base)
        if draw_bg:
            d.rectangle([0, 0, 63, 63], fill=bg_fill)
            d.rectangle([2, 2, 61, 61], outline=GOLD_DK)
        _draw_emblem_art(d, "title_crest", PORPHYRY if draw_bg else PORPHYRY_DK, GOLD_HI, IVORY)
        # Scale crisp nearest/lanczos depending on target
        inner_sz = max(32, int(round(size * (1.0 - pad_ratio * 2.0))))
        scaled = base.resize((inner_sz, inner_sz), Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (size, size), bg_fill if draw_bg else VOID_T)
        off = (size - inner_sz) // 2
        canvas.paste(scaled, (off, off), scaled if not draw_bg else None)
        return canvas

    sizes = [
        ("icon_512.png", 512, 0.04),
        ("icon_192.png", 192, 0.04),
        ("icon_180.png", 180, 0.04),
        ("icon_144.png", 144, 0.04),
        ("icon_128.png", 128, 0.04),
    ]
    for fname, sz, pad in sizes:
        im = render_crest_canvas(sz, VOID, pad_ratio=pad, draw_bg=True)
        out = icons_dir / fname
        im.save(out)
        prov.append({
            "asset_id": fname.replace(".png", ""),
            "path": f"res://assets/icons/{fname}",
            "source": "Abyssal Sovereign internal procedural generator",
            "author_or_method": "tools/gen_sprites.py (Title Crest icon renderer)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m9_asset",
            "associated_entities": ["application:icon"],
            "modification_history": [f"Generated M9.1 {sz}x{sz} application icon"],
        })

    # Android adaptive icon foreground & background (432x432 with safe-zone padding)
    fg = render_crest_canvas(432, VOID_T, pad_ratio=0.18, draw_bg=False)
    fg.save(icons_dir / "adaptive_fg.png")
    bg = Image.new("RGBA", (432, 432), VOID)
    bd = ImageDraw.Draw(bg)
    for r in range(48, 216, 32):
        bd.ellipse([216 - r, 216 - r, 216 + r, 216 + r], outline=PORPHYRY, width=3)
    bd.rectangle([16, 16, 416, 416], outline=PORPHYRY_LT, width=4)
    bg.save(icons_dir / "adaptive_bg.png")

    for fname, desc in (("adaptive_fg.png", "Android adaptive foreground 432x432"), ("adaptive_bg.png", "Android adaptive background 432x432")):
        prov.append({
            "asset_id": fname.replace(".png", ""),
            "path": f"res://assets/icons/{fname}",
            "source": "Abyssal Sovereign internal procedural generator",
            "author_or_method": "tools/gen_sprites.py (Adaptive icon renderer)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m9_asset",
            "associated_entities": ["application:android_adaptive_icon"],
            "modification_history": [f"Generated M9.1 {desc}"],
        })
    return prov


SPHERE_THEMES = {
    1: {
        "name": "moon", "style": "ossuary",
        "floor": (28, 24, 32, 255), "floor_alt": (38, 32, 44, 255),
        "wall_cap": (78, 72, 86, 255), "wall_face": (52, 46, 58, 255),
        "mortar": (19, 16, 23, 255), "accent": SILVER,
    },
    2: {
        "name": "mercury", "style": "brass",
        "floor": (30, 34, 32, 255), "floor_alt": (40, 48, 44, 255),
        "wall_cap": (96, 82, 54, 255), "wall_face": (62, 54, 38, 255),
        "mortar": (22, 26, 24, 255), "accent": GOLD,
    },
    3: {
        "name": "venus", "style": "choir",
        "floor": (38, 22, 36, 255), "floor_alt": (52, 28, 48, 255),
        "wall_cap": (94, 52, 76, 255), "wall_face": (62, 32, 52, 255),
        "mortar": (26, 14, 24, 255), "accent": GOLD_HI,
    },
    4: {
        "name": "sun", "style": "solar",
        "floor": (44, 39, 28, 255), "floor_alt": (58, 50, 34, 255),
        "wall_cap": (132, 108, 62, 255), "wall_face": (86, 70, 42, 255),
        "mortar": (30, 26, 18, 255), "accent": FALSE_SUN,
    },
    5: {
        "name": "mars", "style": "iron",
        "floor": (26, 26, 30, 255), "floor_alt": (36, 32, 36, 255),
        "wall_cap": (72, 68, 76, 255), "wall_face": (46, 44, 52, 255),
        "mortar": (18, 16, 20, 255), "accent": EMBER,
    },
    6: {
        "name": "jupiter", "style": "imperial",
        "floor": (34, 26, 46, 255), "floor_alt": (46, 34, 62, 255),
        "wall_cap": (88, 64, 112, 255), "wall_face": (58, 42, 76, 255),
        "mortar": (22, 16, 30, 255), "accent": GOLD_HI,
    },
    7: {
        "name": "saturn", "style": "sealed",
        "floor": (18, 16, 22, 255), "floor_alt": (26, 22, 32, 255),
        "wall_cap": (52, 46, 62, 255), "wall_face": (30, 26, 38, 255),
        "mortar": (10, 8, 14, 255), "accent": LUX,
    },
}


def save_sheet(rel_path: str, sheet: Sheet) -> str:
    full = ROOT / rel_path
    full.parent.mkdir(parents=True, exist_ok=True)
    sheet.img.save(full)
    return "res://" + rel_path


def main() -> None:
    PRES.mkdir(parents=True, exist_ok=True)
    registry: dict = {
        "schema": "asset_registry",
        "version": 1,
        "atlases": {},
        "tiles": {},
        "features": {},
        "avatars": {},
        "monsters": {},
        "npcs": {},
        "items": {},
        "statuses": {},
        "icons": {},
        "emblems": {},
    }
    prov_entries: list[dict] = []

    def reg_atlas(aid: str, rel: str, sheet: Sheet, desc: str, entities: list[str]) -> None:
        res_path = save_sheet(rel, sheet)
        registry["atlases"][aid] = {"path": res_path, "cell": sheet.cell, "size": [sheet.img.width, sheet.img.height]}
        prov_entries.append({
            "asset_id": aid,
            "path": res_path,
            "source": "Abyssal Sovereign internal procedural generator",
            "author_or_method": "tools/gen_sprites.py (PIL/Pillow deterministic pixel renderer)",
            "license_status": "project-original-cc0-equivalent",
            "approval_status": "provisional_m9_asset",
            "associated_entities": entities,
            "modification_history": [
                f"Generated M8.4 atlas: {desc}",
                f"Elevated M9.1 shading, silhouettes & woodcut detail: {desc}",
            ],
        })

    for snum, theme in SPHERE_THEMES.items():
        sh_obj, tr, fr = draw_sphere_tile_atlas(snum, theme)
        aid = f"sphere_{snum}_{theme['name']}"
        rel = f"assets/tiles/{aid}.png"
        reg_atlas(aid, rel, sh_obj, f"Sphere {snum} ({theme['name']}) 32x32 tiles & features", [f"sphere:{theme['name']}"])
        for k, rect in tr.items():
            registry["tiles"][k] = {"atlas": aid, "rect": rect}
        for k, rect in fr.items():
            registry["features"][k] = {"atlas": aid, "rect": rect}

    av_s, av_r = draw_avatars_full()
    reg_atlas("avatars", "assets/sprites/avatars.png", av_s, "8 origins, 8 callings, 5 Masks", ["species", "classes", "masks"])
    for k, rect in av_r.items():
        registry["avatars"][k] = {"atlas": "avatars", "rect": rect}

    mo_s, mo_r = draw_monsters_full()
    reg_atlas("monsters", "assets/sprites/monsters.png", mo_s, "10 families, 15 bespoke bosses, 86 monster entries", ["monsters"])
    for k, rect in mo_r.items():
        registry["monsters"][k] = {"atlas": "monsters", "rect": rect}

    np_s, np_r = draw_npcs_full()
    reg_atlas("npcs", "assets/sprites/npcs.png", np_s, "18 recurring NPCs", ["npcs"])
    for k, rect in np_r.items():
        registry["npcs"][k] = {"atlas": "npcs", "rect": rect}

    it_s, it_r = draw_items_full()
    reg_atlas("items", "assets/sprites/items.png", it_s, "165 items, 16 bespoke relics, 26 unique artifacts", ["items", "relics", "artifacts"])
    for k, rect in it_r.items():
        registry["items"][k] = {"atlas": "items", "rect": rect}

    ic_s, st_r, ic_r = draw_icons_16()
    reg_atlas("icons", "assets/sprites/icons.png", ic_s, "51 statuses, 24 talent trees, 8 elites, Eight Chains, contracts", ["statuses", "talents", "contracts"])
    for k, rect in st_r.items():
        registry["statuses"][k] = {"atlas": "icons", "rect": rect}
    for k, rect in ic_r.items():
        registry["icons"][k] = {"atlas": "icons", "rect": rect}

    em_s, em_r = draw_emblems_64()
    reg_atlas("emblems", "assets/portraits/emblems.png", em_s, "24 unique 64x64 woodcut emblems", ["factions", "spheres", "endings"])
    for k, rect in em_r.items():
        registry["emblems"][k] = {"atlas": "emblems", "rect": rect}

    icon_prov = draw_app_icons()
    all_visual = prov_entries + icon_prov
    visual_ids = {e["asset_id"] for e in all_visual}

    prov_path = PRES / "asset_provenance.json"
    preserved_audio: list[dict] = []
    if prov_path.exists():
        old_data = json.loads(prov_path.read_text())
        for e in old_data.get("entries", []):
            aid = e.get("asset_id", "")
            if aid not in visual_ids and (aid.startswith("sfx_") or aid.startswith("ambience_") or aid.startswith("music_")):
                preserved_audio.append(e)

    (PRES / "asset_registry.json").write_text(json.dumps(registry, indent=2) + "\n")
    (PRES / "asset_provenance.json").write_text(json.dumps({
        "schema": "asset_provenance",
        "version": 1,
        "entries": all_visual + preserved_audio,
    }, indent=2) + "\n")
    print(f"Generated {len(prov_entries)} atlases and {len(icon_prov)} icons into {ASSETS}")


if __name__ == "__main__":
    main()
