#!/usr/bin/env python3
"""Deterministic pixel-art sprite & tileset generator for Abyssal Sovereign (M8).

Produces crisp 32x32 tiles/sprites, 16x16 icons, and 64x64 woodcut emblems
with strict adherence to docs/ART_DIRECTION.md and zero external/unauthorized
assets. Every generated file is tracked in content/presentation/asset_provenance.json.
"""

from __future__ import annotations

import json
import os
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
IRON_HI = (118, 118, 134, 255)
IRON_DK = (48, 46, 56, 255)
PORPHYRY = (45, 26, 46, 255)
PORPHYRY_LT = (75, 39, 73, 255)
GOLD = (183, 149, 85, 255)
GOLD_HI = (232, 198, 120, 255)
FALSE_SUN = (242, 195, 92, 255)
IVORY = (238, 229, 211, 255)
RECORD = (211, 190, 160, 255)
TEXT_DIM = (168, 157, 140, 255)
LUX = (224, 0, 143, 255)
LUX_DK = (128, 12, 86, 255)
SILVER = (184, 196, 208, 255)
SILVER_DK = (116, 128, 144, 255)
BLOOD = (166, 38, 57, 255)
ALERT = (255, 77, 109, 255)
SAGE = (120, 190, 167, 255)
SAGE_DK = (68, 118, 104, 255)
EMBER = (255, 122, 51, 255)
RIME = (110, 198, 255, 255)
MIASMA = (143, 122, 224, 255)
WATER = (56, 76, 97, 255)
WATER_HI = (94, 122, 153, 255)


def mix(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def hsh(x: int, y: int, seed: int = 0) -> int:
    v = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return (v ^ (v >> 16)) & 0xFF


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
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 20:
                        opx[x, y] = edge
                        break
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

    # 4 floor variants (Tiles.FLOOR = 1)
    for v in range(4):
        key = f"s{sphere_num}:1:{v}"
        t, d, _, _ = s.next_tile(key)
        d.rectangle([0, 0, 31, 31], fill=fl_base)
        # Flagstone grid
        for y in range(0, 32, 16):
            d.line([(0, y), (31, y)], fill=mortar)
        off = 8 if (v % 2 == 1) else 16
        d.line([(off, 0), (off, 15)], fill=mortar)
        d.line([((off + 12) % 32, 16), ((off + 12) % 32, 31)], fill=mortar)
        px = t.load()
        for y in range(32):
            for x in range(32):
                r = hsh(x, y, sphere_num * 31 + v)
                if r < 18:
                    px[x, y] = fl_alt
                elif r > 246 and v == 3:
                    px[x, y] = mix(fl_base, accent, 0.35)
        if v == 1:
            # Bone-dust or Sphere-specific geometric floor detail
            st = theme.get("style", "ossuary")
            if st == "brass":
                d.rectangle([10, 10, 21, 21], outline=mix(fl_base, accent, 0.45))
            elif st == "choir":
                d.polygon([(16, 8), (24, 16), (16, 24), (8, 16)], outline=mix(fl_base, accent, 0.4))
            elif st == "solar":
                d.ellipse([9, 9, 22, 22], outline=mix(fl_base, accent, 0.5))
            elif st == "iron":
                d.point([(4, 4), (27, 4), (4, 27), (27, 27)], fill=IRON_HI)
            elif st == "imperial":
                d.rectangle([4, 4, 27, 27], outline=mix(fl_base, GOLD, 0.35))
            elif st == "sealed":
                d.line([(6, 25), (16, 6), (25, 25)], fill=mix(fl_base, LUX, 0.55))
            else:
                d.line([(5, 22), (10, 19), (14, 21)], fill=mix(fl_base, IVORY, 0.25))
        elif v == 2:
            d.point([(24, 9), (25, 10)], fill=mix(fl_base, accent, 0.45))
        s.commit(key, t)
        tile_rects[key] = s.rects[key]

    # 4 wall variants (Tiles.WALL = 0)
    for v in range(4):
        key = f"s{sphere_num}:0:{v}"
        t, d, _, _ = s.next_tile(key)
        d.rectangle([0, 0, 31, 31], fill=wl_face)
        d.rectangle([0, 0, 31, 10], fill=wl_cap)
        d.line([(0, 10), (31, 10)], fill=mix(wl_cap, VOID, 0.55))
        d.line([(0, 0), (31, 0)], fill=mix(wl_cap, IVORY, 0.16))
        # Masonry blocks on front face
        for by in (16, 24):
            d.line([(0, by), (31, by)], fill=mix(wl_face, VOID, 0.4))
        for bx in (7, 21):
            d.line([(bx, 11), (bx, 16)], fill=mix(wl_face, VOID, 0.4))
            d.line([((bx + 8) % 32, 17), ((bx + 8) % 32, 24)], fill=mix(wl_face, VOID, 0.4))
        st = theme.get("style", "ossuary")
        if v == 1:
            # Sphere architectural wall relief
            if st == "brass":
                d.rectangle([9, 13, 22, 24], fill=mix(wl_face, GOLD, 0.25), outline=accent)
                d.line([(16, 14), (16, 23)], fill=VOID)
            elif st == "choir":
                d.arc([9, 12, 22, 26], 180, 360, fill=GOLD, width=2)
                d.rectangle([11, 17, 20, 25], fill=PORPHYRY)
            elif st == "solar":
                d.ellipse([10, 13, 21, 24], fill=mix(wl_face, FALSE_SUN, 0.35), outline=FALSE_SUN)
            elif st == "iron":
                d.rectangle([8, 12, 23, 25], fill=IRON_DK, outline=IRON_HI)
                d.line([(12, 12), (12, 25)], fill=IRON)
                d.line([(19, 12), (19, 25)], fill=IRON)
            elif st == "imperial":
                d.rectangle([10, 13, 21, 24], fill=PORPHYRY_LT, outline=GOLD)
                d.ellipse([13, 16, 18, 21], fill=BLOOD)
            elif st == "sealed":
                d.polygon([(16, 12), (22, 18), (16, 25), (10, 18)], fill=VOID, outline=LUX)
            else:
                d.rectangle([11, 13, 20, 23], fill=VOID, outline=mix(wl_cap, accent, 0.35))
                d.ellipse([13, 15, 18, 20], fill=mix(RECORD, wl_face, 0.45))
        elif v == 2:
            # Carved tally / seal line
            d.line([(10, 15), (21, 15)], fill=accent)
            for tx in (12, 15, 18):
                d.line([(tx, 17), (tx, 21)], fill=mix(accent, RECORD, 0.4))
        elif v == 3:
            # Subtle iron rivet / crack
            d.line([(4, 4), (9, 8)], fill=mix(wl_cap, VOID, 0.5))
            d.rectangle([23, 19, 25, 21], fill=IRON_HI)
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
    d.rectangle([5, 5, 26, 26], fill=VOID, outline=GOLD)
    for idx, step_y in enumerate(range(8, 25, 4)):
        col = mix(GOLD, VOID, idx * 0.14)
        d.rectangle([7 + idx * 2, step_y, 24, step_y + 2], fill=col)
    d.polygon([(16, 25), (12, 20), (20, 20)], fill=FALSE_SUN)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:3"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([5, 5, 26, 26], fill=mix(fl_base, SILVER, 0.15), outline=RECORD)
    for idx, step_y in enumerate(range(22, 6, -4)):
        col = mix(RECORD, SILVER_DK, idx * 0.15)
        d.rectangle([8, step_y, 23 - idx * 2, step_y + 2], fill=col)
    d.polygon([(16, 6), (12, 11), (20, 11)], fill=IVORY)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Sealed Unwritten Door (4) & Open Door (5)
    k = f"s{sphere_num}:4"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([5, 2, 26, 29], fill=IRON_DK, outline=ALERT)
    d.line([(16, 3), (16, 28)], fill=VOID)
    d.ellipse([11, 11, 21, 21], fill=BLOOD, outline=ALERT)
    d.ellipse([14, 14, 18, 18], fill=VOID)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    k = f"s{sphere_num}:5"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([5, 2, 26, 29], fill=VOID, outline=SAGE)
    d.rectangle([5, 2, 9, 29], fill=IRON)
    d.rectangle([22, 2, 26, 29], fill=IRON)
    d.ellipse([12, 12, 20, 20], outline=SAGE)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Branch in (10) & Branch out (11)
    for tid, up_flag in ((10, False), (11, True)):
        k = f"s{sphere_num}:{tid}"
        s.next_tile(k)
        t, d = floor_underlay()
        d.arc([4, 4, 27, 27], 180, 360, fill=SAGE, width=2)
        d.rectangle([6, 14, 25, 27], fill=VOID, outline=SAGE_DK)
        if up_flag:
            d.polygon([(16, 16), (11, 23), (21, 23)], fill=SAGE)
        else:
            d.polygon([(16, 24), (11, 17), (21, 17)], fill=SAGE)
        s.commit(k, t)
        tile_rects[k] = s.rects[k]

    # Shallow Water (12)
    k = f"s{sphere_num}:12"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=WATER)
    for wy in (7, 15, 23):
        d.line([(4, wy), (13, wy - 1), (20, wy + 1), (28, wy)], fill=WATER_HI)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Sanctuary Floor (13)
    k = f"s{sphere_num}:13"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=mix(fl_base, SAGE_DK, 0.38))
    d.rectangle([3, 3, 28, 28], outline=SAGE)
    d.line([(16, 6), (16, 25)], fill=mix(SAGE, IVORY, 0.35))
    d.line([(6, 16), (25, 16)], fill=mix(SAGE, IVORY, 0.35))
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Iron Grate (14)
    k = f"s{sphere_num}:14"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([0, 0, 31, 31], fill=VOID)
    for g in range(2, 32, 6):
        d.line([(g, 0), (g, 31)], fill=IRON, width=2)
        d.line([(0, g), (31, g)], fill=IRON_DK, width=2)
    d.rectangle([0, 0, 31, 31], outline=IRON_HI)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Hazards: ASH_EMBER (6), RIME_ICE (7), MIASMA (8), SOLAR_GLARE (9)
    # 6: Embers
    k = f"s{sphere_num}:6"
    s.next_tile(k)
    t, d = floor_underlay()
    for x1, y1 in ((5, 6), (18, 9), (9, 20), (22, 23), (14, 14)):
        d.line([(x1, y1), (x1 + 4, y1 - 3)], fill=EMBER, width=2)
        d.point([(x1 + 2, y1 - 5)], fill=FALSE_SUN)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # 7: Rime Ice
    k = f"s{sphere_num}:7"
    s.next_tile(k)
    t, d = floor_underlay()
    d.rectangle([1, 1, 30, 30], fill=mix(fl_base, RIME, 0.22))
    d.line([(4, 4), (27, 27)], fill=RIME)
    d.line([(27, 4), (4, 27)], fill=RIME)
    d.line([(16, 3), (16, 28)], fill=IVORY)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # 8: Miasma
    k = f"s{sphere_num}:8"
    s.next_tile(k)
    t, d = floor_underlay()
    for cx, cy, r in ((10, 11, 5), (21, 14, 6), (14, 22, 5)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=mix(PORPHYRY, MIASMA, 0.5), outline=MIASMA)
    d.point([(9, 9), (22, 12), (16, 22)], fill=LUX)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # 9: Solar Glare
    k = f"s{sphere_num}:9"
    s.next_tile(k)
    t, d = floor_underlay()
    d.ellipse([8, 8, 23, 23], fill=mix(fl_base, FALSE_SUN, 0.35), outline=FALSE_SUN)
    d.line([(16, 2), (16, 29)], fill=FALSE_SUN)
    d.line([(2, 16), (29, 16)], fill=FALSE_SUN)
    d.ellipse([13, 13, 19, 19], fill=IVORY)
    s.commit(k, t)
    tile_rects[k] = s.rects[k]

    # Features (drawn over floor in MapView; transparent background!)
    def add_feat(fname: str, drawer) -> None:
        fk = f"s{sphere_num}:{fname}"
        s.next_tile(fk)
        ft = Image.new("RGBA", (32, 32), VOID_T)
        fd = ImageDraw.Draw(ft)
        drawer(fd, ft)
        ft = outline_sprite(ft)
        s.commit(fk, ft)
        feat_rects[fk] = s.rects[fk]

    def draw_altar(fd, _ft, used: bool):
        col = IRON if used else IVORY
        fd.rectangle([6, 13, 25, 25], fill=IRON_DK, outline=col)
        fd.rectangle([5, 10, 26, 13], fill=col)
        if not used:
            fd.line([(16, 6), (16, 20)], fill=GOLD_HI)
            fd.line([(11, 12), (21, 12)], fill=GOLD_HI)

    add_feat("altar:ready", lambda fd, ft: draw_altar(fd, ft, False))
    add_feat("altar:used", lambda fd, ft: draw_altar(fd, ft, True))

    def draw_shrine(fd, _ft, used: bool):
        col = IRON if used else SAGE
        fd.polygon([(16, 4), (24, 15), (22, 27), (10, 27), (8, 15)], fill=PORPHYRY, outline=col)
        if not used:
            fd.ellipse([12, 10, 20, 17], fill=LUX, outline=IVORY)
            fd.ellipse([15, 12, 17, 15], fill=VOID)

    add_feat("shrine:ready", lambda fd, ft: draw_shrine(fd, ft, False))
    add_feat("shrine:used", lambda fd, ft: draw_shrine(fd, ft, True))

    def draw_circle(fd, _ft, used: bool):
        col = IRON if used else LUX
        fd.ellipse([3, 3, 28, 28], outline=col, width=2)
        fd.polygon([(16, 5), (26, 23), (6, 23)], outline=GOLD if not used else IRON_DK)
        fd.ellipse([13, 13, 19, 19], outline=IVORY if not used else IRON_DK)

    add_feat("ritual_circle:ready", lambda fd, ft: draw_circle(fd, ft, False))
    add_feat("ritual_circle:used", lambda fd, ft: draw_circle(fd, ft, True))

    def draw_vault(fd, _ft, used: bool):
        if not used:
            fd.rectangle([4, 4, 27, 27], fill=IRON_DK, outline=GOLD)
            for gx in (9, 16, 23):
                fd.line([(gx, 5), (gx, 26)], fill=GOLD_HI, width=2)
            fd.ellipse([13, 13, 19, 19], fill=FALSE_SUN)
        else:
            fd.rectangle([4, 4, 8, 27], fill=IRON)
            fd.rectangle([23, 4, 27, 27], fill=IRON)

    add_feat("vault_gate:ready", lambda fd, ft: draw_vault(fd, ft, False))
    add_feat("vault_gate:used", lambda fd, ft: draw_vault(fd, ft, True))

    def draw_merchant(fd, _ft):
        fd.ellipse([11, 5, 21, 14], fill=PORPHYRY_LT, outline=GOLD)
        fd.polygon([(16, 13), (25, 28), (7, 28)], fill=PORPHYRY, outline=GOLD)
        fd.line([(16, 15), (22, 15)], fill=FALSE_SUN)
        fd.rectangle([20, 17, 24, 21], fill=GOLD_HI)

    add_feat("merchant:ready", draw_merchant)
    add_feat("merchant:used", draw_merchant)

    def draw_lectern(fd, _ft, used: bool):
        c = IRON if used else LUX
        fd.rectangle([14, 13, 18, 27], fill=IRON)
        fd.rectangle([9, 25, 23, 28], fill=IRON_DK)
        fd.polygon([(6, 7), (26, 7), (23, 14), (9, 14)], fill=RECORD if not used else IRON, outline=c)
        if not used:
            fd.line([(10, 10), (22, 10)], fill=LUX)

    add_feat("contract_lectern:ready", lambda fd, ft: draw_lectern(fd, ft, False))
    add_feat("contract_lectern:used", lambda fd, ft: draw_lectern(fd, ft, True))

    def draw_bell(fd, _ft, used: bool):
        c = IRON if used else EMBER
        fd.polygon([(16, 5), (23, 21), (9, 21)], fill=GOLD if not used else IRON_DK, outline=c)
        fd.rectangle([14, 21, 18, 25], fill=c)
        fd.line([(7, 26), (25, 26)], fill=IRON_HI)

    add_feat("challenge:ready", lambda fd, ft: draw_bell(fd, ft, False))
    add_feat("challenge:used", lambda fd, ft: draw_bell(fd, ft, True))

    def draw_secret(fd, _ft, used: bool):
        if not used:
            fd.rectangle([3, 3, 28, 28], fill=wl_face, outline=GOLD)
            fd.line([(16, 6), (16, 25)], fill=GOLD)
        else:
            fd.rectangle([4, 4, 8, 27], fill=wl_face)
            fd.rectangle([23, 4, 27, 27], fill=wl_face)

    add_feat("secret_door:ready", lambda fd, ft: draw_secret(fd, ft, False))
    add_feat("secret_door:used", lambda fd, ft: draw_secret(fd, ft, True))

    def draw_trap(fd, _ft, used: bool):
        if not used:
            fd.polygon([(8, 22), (12, 11), (16, 22)], fill=ALERT)
            fd.polygon([(16, 22), (20, 11), (24, 22)], fill=ALERT)
            fd.line([(7, 23), (25, 23)], fill=IRON_HI, width=2)
        else:
            fd.line([(8, 22), (14, 20)], fill=IRON)
            fd.line([(18, 20), (24, 22)], fill=IRON)

    add_feat("trap:ready", lambda fd, ft: draw_trap(fd, ft, False))
    add_feat("trap:used", lambda fd, ft: draw_trap(fd, ft, True))

    def draw_ward(fd, _ft):
        fd.polygon([(16, 4), (27, 16), (16, 28), (5, 16)], outline=LUX, width=2)
        fd.ellipse([12, 12, 20, 20], fill=MIASMA)

    add_feat("ward_sigil:ready", draw_ward)
    add_feat("ward_sigil:used", draw_ward)

    def draw_rune_puzzle(fd, _ft, used: bool):
        c = IRON if used else SAGE
        fd.rectangle([7, 6, 25, 26], fill=PORPHYRY, outline=c)
        fd.line([(11, 12), (21, 12)], fill=c)
        fd.line([(16, 9), (16, 22)], fill=c)

    add_feat("rune_puzzle:ready", lambda fd, ft: draw_rune_puzzle(fd, ft, False))
    add_feat("rune_puzzle:used", lambda fd, ft: draw_rune_puzzle(fd, ft, True))

    def draw_abandoned_rite(fd, _ft, used: bool):
        c = IRON if used else LUX
        fd.ellipse([6, 6, 26, 26], outline=c)
        fd.line([(8, 24), (24, 8)], fill=GOLD if not used else IRON_DK)

    add_feat("abandoned_rite:ready", lambda fd, ft: draw_abandoned_rite(fd, ft, False))
    add_feat("abandoned_rite:used", lambda fd, ft: draw_abandoned_rite(fd, ft, True))

    def draw_hearth(fd, _ft, used: bool):
        fd.ellipse([6, 14, 26, 27], fill=IRON_DK, outline=IRON_HI)
        if not used:
            fd.polygon([(16, 6), (22, 18), (10, 18)], fill=EMBER)
            fd.polygon([(16, 10), (19, 18), (13, 18)], fill=FALSE_SUN)

    add_feat("sanctuary_hearth:ready", lambda fd, ft: draw_hearth(fd, ft, False))
    add_feat("sanctuary_hearth:used", lambda fd, ft: draw_hearth(fd, ft, True))

    def draw_echo_cache(fd, _ft, used: bool):
        c = IRON if used else SILVER
        fd.rectangle([8, 8, 24, 24], fill=VOID, outline=c)
        if not used:
            fd.line([(11, 14), (21, 14)], fill=LUX)
            fd.line([(11, 18), (19, 18)], fill=SILVER)

    add_feat("echo_cache:ready", lambda fd, ft: draw_echo_cache(fd, ft, False))
    add_feat("echo_cache:used", lambda fd, ft: draw_echo_cache(fd, ft, True))

    return s, tile_rects, feat_rects


def hex_rgba(h: str, fallback=SILVER) -> tuple:
    h = (h or "").strip().lstrip("#")
    if len(h) == 6:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
    return fallback


def draw_avatars_full() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(8, 4, 32)
    rects: dict[str, list[int]] = {}

    origin_styles = {
        "human": (RECORD, PORPHYRY, GOLD),
        "revenant": (SILVER_DK, IRON_DK, SILVER),
        "cambion": (BLOOD, PORPHYRY_LT, EMBER),
        "ashborn": (EMBER, (56, 30, 26, 255), GOLD_HI),
        "veilkin": (MIASMA, (32, 22, 46, 255), LUX),
        "ironbound_ward": (IRON_HI, IRON_DK, GOLD),
        "unrecorded": (TEXT_DIM, (36, 36, 42, 255), SILVER_DK),
        "penitent": (IVORY, BLOOD, GOLD),
    }

    def make_origin(key: str, head_c, body_c, trim_c):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.ellipse([9, 26, 23, 30], fill=(8, 6, 9, 140))
        d.polygon([(16, 11), (24, 27), (8, 27)], fill=body_c, outline=trim_c)
        d.ellipse([11, 4, 21, 13], fill=head_c, outline=trim_c)
        d.point([(14, 8), (18, 8)], fill=IVORY)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_origin("origin:default", SILVER, PORPHYRY, GOLD)
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
        d.line([(16, 13), (16, 26)], fill=col, width=2)
        if shape == "blade":
            d.line([(24, 8), (24, 23)], fill=wep_col, width=2)
            d.line([(21, 19), (27, 19)], fill=GOLD)
        elif shape == "rod":
            d.line([(24, 7), (24, 25)], fill=GOLD, width=2)
            d.ellipse([22, 4, 26, 8], fill=LUX)
        elif shape == "dagger":
            d.line([(23, 14), (27, 21)], fill=wep_col, width=2)
        elif shape == "shield":
            d.rectangle([5, 13, 11, 24], fill=IRON_DK, outline=col)
            d.line([(24, 11), (24, 24)], fill=wep_col, width=2)
        elif shape == "bow":
            d.arc([20, 8, 28, 24], 270, 90, fill=wep_col, width=2)
        elif shape == "scroll":
            d.rectangle([5, 14, 11, 22], fill=RECORD, outline=col)
        elif shape == "flask":
            d.ellipse([21, 16, 27, 22], fill=FALSE_SUN, outline=IVORY)
        elif shape == "coil":
            d.arc([20, 12, 27, 22], 0, 300, fill=SAGE, width=2)
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
        if mk != "bare_face":
            d.ellipse([12, 5, 20, 12], outline=mcol)
            if mk == "lilith":
                d.point([(16, 7)], fill=LUX)
            elif mk == "lux_venefica":
                d.arc([8, 2, 24, 16], 180, 360, fill=LUX, width=2)
                d.ellipse([14, 4, 18, 8], fill=FALSE_SUN)
        s.commit(k, t)
        rects[k] = s.rects[k]

    return s, rects


def draw_monsters_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "monsters.json").read_text())["entries"]
    # 12 columns x 10 rows = 120 slots (covers 10 tags + 86 monsters + default)
    s = Sheet(12, 10, 32)
    rects: dict[str, list[int]] = {}

    def render_mon(key: str, shape: str, fill_c, accent_c, boss: bool = False):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if boss:
            d.ellipse([4, 24, 28, 30], outline=GOLD_HI)
        if shape == "beast":
            d.ellipse([7, 15, 23, 25], fill=fill_c, outline=accent_c)
            d.ellipse([19, 12, 26, 19], fill=fill_c, outline=accent_c)
            d.line([(4, 19), (9, 17)], fill=accent_c, width=2)
            d.point([(23, 14)], fill=ALERT)
        elif shape == "undead":
            d.polygon([(16, 10), (23, 27), (9, 27)], fill=fill_c, outline=accent_c)
            d.ellipse([12, 4, 20, 11], fill=RECORD, outline=accent_c)
            d.point([(14, 7), (18, 7)], fill=VOID)
        elif shape == "soldier":
            d.rectangle([10, 11, 22, 26], fill=fill_c, outline=accent_c)
            d.polygon([(12, 4), (20, 4), (21, 11), (11, 11)], fill=IRON_HI, outline=accent_c)
            d.line([(25, 5), (25, 26)], fill=SILVER, width=2)
        elif shape == "inquisition":
            d.polygon([(16, 8), (25, 27), (7, 27)], fill=fill_c, outline=accent_c)
            d.polygon([(16, 2), (21, 10), (11, 10)], fill=accent_c, outline=GOLD)
            d.line([(7, 12), (7, 25)], fill=FALSE_SUN, width=2)
        elif shape == "radiant":
            d.polygon([(16, 4), (24, 16), (16, 27), (8, 16)], fill=fill_c, outline=FALSE_SUN)
            d.ellipse([13, 12, 19, 18], fill=IVORY)
        elif shape == "construct":
            d.rectangle([8, 7, 24, 27], fill=fill_c, outline=accent_c)
            d.rectangle([12, 11, 20, 15], fill=accent_c)
            d.line([(8, 20), (24, 20)], fill=GOLD)
        elif shape == "geometry":
            d.polygon([(16, 4), (26, 16), (16, 28), (6, 16)], fill=VOID, outline=accent_c)
            d.ellipse([12, 12, 20, 20], fill=LUX, outline=IVORY)
        elif shape == "serpent":
            d.arc([7, 8, 25, 26], 0, 270, fill=fill_c, width=4)
            d.ellipse([18, 7, 24, 13], fill=accent_c)
        else:
            d.polygon([(16, 6), (25, 17), (22, 27), (10, 27), (7, 17)], fill=fill_c, outline=accent_c)
            d.point([(14, 13), (18, 13)], fill=FALSE_SUN)
        if boss:
            d.polygon([(12, 4), (16, 1), (20, 4)], fill=FALSE_SUN)
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
    for tg, (sh, fc, ac) in tag_shapes.items():
        render_mon(f"tag:{tg}", sh, fc, ac)

    for e in data:
        mid = e["id"]
        tags = set(e.get("tags", []))
        is_boss = "boss" in tags or bool(e.get("unique", False))
        col = hex_rgba(e.get("color", ""), SILVER)
        shape = "construct"
        if is_boss:
            if "rat" in mid:
                shape = "beast"
            elif "sentinel" in mid or "cyrus" in mid or "auditor" in mid:
                shape = "construct"
            elif "cantor" in mid or "helios" in mid or "octavius" in mid or "severin" in mid:
                shape = "inquisition"
            elif "krell" in mid or "voss" in mid or "warden" in mid or "jailer" in mid:
                shape = "soldier"
            elif "malakor" in mid:
                shape = "geometry"
            else:
                shape = "radiant"
        elif "vermin" in tags or e.get("glyph") in ("r", "R", "f", "m", "x"):
            shape = "beast"
        elif "undead" in tags:
            shape = "undead"
        elif "dominion" in tags:
            shape = "soldier"
        elif "inquisition" in tags:
            shape = "inquisition"
        elif "false_sun" in tags:
            shape = "radiant"
        elif "geometry" in tags:
            shape = "geometry"
        elif "predator" in tags or e.get("glyph") in ("w", "s", "S"):
            shape = "serpent"
        render_mon(mid, shape, mix(col, VOID, 0.35), col, boss=is_boss)

    return s, rects


def draw_npcs_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "npcs.json").read_text())["entries"]
    s = Sheet(6, 4, 32)
    rects: dict[str, list[int]] = {}

    def make_npc(key: str, cloak_c, accent_c, prop_idx: int):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.polygon([(16, 10), (24, 27), (8, 27)], fill=cloak_c, outline=accent_c)
        d.ellipse([12, 4, 20, 11], fill=IVORY, outline=accent_c)
        if prop_idx % 4 == 0:
            d.line([(23, 12), (23, 25)], fill=GOLD, width=2)
        elif prop_idx % 4 == 1:
            d.rectangle([5, 14, 10, 21], fill=RECORD, outline=LUX)
        elif prop_idx % 4 == 2:
            d.ellipse([21, 14, 27, 20], fill=FALSE_SUN, outline=GOLD)
        else:
            d.line([(6, 15), (12, 23)], fill=SILVER, width=2)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_npc("default", SAGE_DK, SAGE, 0)
    for idx, e in enumerate(data):
        nid = e["id"]
        c = hex_rgba(e.get("color", ""), SAGE)
        make_npc(nid, mix(c, PORPHYRY, 0.45), c, idx)
    return s, rects


def draw_items_full() -> tuple[Sheet, dict[str, list[int]]]:
    data = json.loads((CORE / "items.json").read_text())["entries"]
    # 16 columns x 12 rows = 192 cells (165 items + 10 category defaults)
    s = Sheet(16, 12, 32)
    rects: dict[str, list[int]] = {}

    def draw_it(key: str, kind: str, eff: str, col, iid: str = "", is_art: bool = False):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if kind == "weapon":
            if "mace" in iid or "flail" in iid or "hammer" in iid or "cudgel" in iid or "bell" in iid:
                d.line([(9, 23), (21, 11)], fill=RECORD, width=2)
                d.ellipse([18, 6, 26, 14], fill=col, outline=IVORY)
            elif "halberd" in iid or "spear" in iid or "axe" in iid or "glaive" in iid or "scythe" in iid:
                d.line([(8, 25), (23, 7)], fill=GOLD, width=2)
                d.polygon([(19, 6), (26, 9), (22, 15)], fill=col, outline=IVORY)
            else:
                d.line([(9, 23), (23, 9)], fill=col, width=3)
                d.line([(10, 17), (15, 22)], fill=GOLD, width=2)
        elif kind == "ranged":
            if "rod" in iid or "focus" in iid or "staff" in iid or "prism" in iid or "pointer" in iid:
                d.line([(10, 24), (22, 9)], fill=GOLD, width=2)
                d.ellipse([19, 6, 26, 13], fill=col, outline=LUX)
            else:
                d.arc([8, 6, 22, 26], 270, 90, fill=col, width=2)
                d.line([(15, 7), (15, 25)], fill=RECORD)
        elif kind == "armor":
            d.polygon([(10, 9), (22, 9), (24, 15), (21, 24), (11, 24), (8, 15)], fill=col, outline=SILVER)
        elif kind == "amulet":
            d.ellipse([11, 7, 21, 17], outline=GOLD, width=2)
            d.ellipse([13, 16, 19, 23], fill=col, outline=IVORY)
        elif kind == "key":
            d.ellipse([9, 11, 16, 18], outline=col, width=2)
            d.line([(16, 15), (24, 15)], fill=col, width=2)
            d.line([(21, 15), (21, 19)], fill=col, width=2)
        elif kind == "relic":
            # Unique silhouette hints per relic
            if "crown" in iid:
                d.polygon([(7, 21), (9, 10), (13, 15), (16, 8), (19, 15), (23, 10), (25, 21)], fill=col, outline=GOLD_HI)
            elif "halo" in iid:
                d.arc([7, 7, 25, 25], 20, 280, fill=FALSE_SUN, width=3)
            elif "key" in iid:
                d.ellipse([8, 10, 16, 18], outline=LUX, width=2)
                d.line([(16, 14), (25, 14)], fill=GOLD_HI, width=2)
            elif "lamp" in iid:
                d.rectangle([11, 10, 21, 22], fill=FALSE_SUN, outline=GOLD)
                d.line([(16, 6), (16, 10)], fill=IRON_HI, width=2)
            elif "bell" in iid:
                d.polygon([(16, 7), (23, 21), (9, 21)], fill=col, outline=RIME)
            elif "mirror" in iid or "glass" in iid or "lens" in iid:
                d.ellipse([9, 8, 23, 22], fill=SILVER, outline=LUX)
                d.line([(12, 12), (18, 18)], fill=IVORY)
            elif "coin" in iid:
                d.ellipse([9, 9, 23, 23], fill=FALSE_SUN, outline=BLOOD)
            else:
                d.polygon([(16, 6), (24, 16), (16, 26), (8, 16)], fill=col, outline=LUX)
                d.ellipse([13, 13, 19, 19], fill=IVORY)
        elif eff == "scroll":
            d.rectangle([10, 9, 22, 23], fill=RECORD, outline=GOLD)
            d.line([(12, 13), (20, 13)], fill=col)
            d.line([(12, 17), (18, 17)], fill=VOID)
        elif eff == "projectile":
            d.line([(9, 22), (22, 9)], fill=SILVER, width=2)
            d.polygon([(23, 8), (18, 9), (22, 13)], fill=col)
        else:
            d.rectangle([13, 8, 19, 12], fill=RECORD)
            d.ellipse([10, 12, 22, 24], fill=col, outline=IVORY)
        if is_art:
            d.point([(7, 7), (25, 7), (7, 25), (25, 25)], fill=LUX)
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

    # 16x16 grid: 16 cols x 8 rows = 128 cells
    s = Sheet(16, 8, 16)
    status_rects: dict[str, list[int]] = {}
    icon_rects: dict[str, list[int]] = {}

    def make_ic(key: str, col, mode: str, store: dict):
        s.next_tile(key)
        t = Image.new("RGBA", (16, 16), VOID_T)
        d = ImageDraw.Draw(t)
        d.rectangle([1, 1, 14, 14], fill=PORPHYRY, outline=col)
        if mode == "diamond":
            d.polygon([(8, 3), (12, 8), (8, 13), (4, 8)], fill=col)
        elif mode == "cross":
            d.line([(8, 3), (8, 12)], fill=col, width=2)
            d.line([(4, 7), (12, 7)], fill=col, width=2)
        elif mode == "ring":
            d.ellipse([4, 4, 11, 11], outline=col, width=2)
        else:
            d.polygon([(8, 3), (12, 12), (4, 12)], fill=col)
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
    for idx, ct in enumerate(contracts):
        make_ic(f"contract:{ct['id']}", GOLD_HI, "diamond", icon_rects)

    return s, status_rects, icon_rects


def draw_emblems_64() -> tuple[Sheet, dict[str, list[int]]]:
    factions = json.loads((CORE / "factions.json").read_text())["entries"]
    # 6 cols x 4 rows = 24 emblems of 64x64
    s = Sheet(6, 4, 64)
    rects: dict[str, list[int]] = {}

    def make_emb(key: str, bg, ring, inner, kind: str):
        s.next_tile(key)
        t = Image.new("RGBA", (64, 64), VOID_T)
        d = ImageDraw.Draw(t)
        d.ellipse([3, 3, 60, 60], fill=bg, outline=ring, width=3)
        d.ellipse([8, 8, 55, 55], outline=mix(ring, VOID, 0.4), width=1)
        if kind == "eye":
            d.arc([12, 18, 52, 46], 190, 350, fill=inner, width=2)
            d.arc([12, 18, 52, 46], 10, 170, fill=inner, width=2)
            d.ellipse([25, 25, 39, 39], fill=LUX, outline=IVORY)
            d.ellipse([30, 30, 34, 34], fill=VOID)
        elif kind == "crown":
            d.polygon([(14, 44), (18, 22), (26, 32), (32, 16), (38, 32), (46, 22), (50, 44)], fill=inner, outline=ring)
        elif kind == "door":
            d.rectangle([20, 14, 44, 50], fill=VOID, outline=inner, width=2)
            d.ellipse([28, 28, 36, 36], fill=SAGE)
        elif kind == "serpent":
            d.arc([14, 14, 50, 50], 20, 300, fill=inner, width=4)
            d.polygon([(46, 26), (52, 22), (49, 32)], fill=LUX)
        elif kind == "seal":
            d.polygon([(32, 12), (50, 32), (32, 52), (14, 32)], outline=inner, width=2)
            d.line([(20, 20), (44, 44)], fill=ring, width=2)
            d.line([(44, 20), (20, 44)], fill=ring, width=2)
        else:
            d.polygon([(32, 12), (48, 44), (16, 44)], outline=inner, width=2)
            d.ellipse([26, 26, 38, 38], outline=ring, width=2)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_emb("title_crest", PORPHYRY, GOLD_HI, IVORY, "eye")
    for sn in range(1, 8):
        col = [SILVER, GOLD, PORPHYRY_LT, FALSE_SUN, EMBER, MIASMA, LUX][sn - 1]
        make_emb(f"sphere_{sn}", VOID, col, IVORY, ["seal", "crown", "eye", "seal", "crown", "seal", "door"][sn - 1])
    for idx, f in enumerate(factions):
        make_emb(f"faction:{f['id']}", PORPHYRY, [GOLD, SILVER, LUX, SAGE][idx % 4], IVORY, ["seal", "eye", "crown", "door"][idx % 4])
    make_emb("boss_seal", BLOOD, ALERT, FALSE_SUN, "crown")
    make_emb("way_serpent", PORPHYRY, LUX, SAGE, "serpent")
    make_emb("way_return", IRON_DK, SAGE, IVORY, "door")
    make_emb("unwritten_door", VOID, SAGE, IVORY, "door")
    make_emb("by_decree", PORPHYRY_LT, FALSE_SUN, GOLD_HI, "crown")
    make_emb("loss_catalogued", IRON_DK, RECORD, SILVER, "seal")
    make_emb("loss_fluent", PORPHYRY, LUX, ALERT, "eye")
    make_emb("loss_gilded", PORPHYRY, FALSE_SUN, BLOOD, "crown")

    return s, rects


SPHERE_THEMES = {
    1: {
        "name": "moon", "style": "ossuary",
        "floor": (28, 24, 32, 255), "floor_alt": (36, 31, 42, 255),
        "wall_cap": (76, 70, 84, 255), "wall_face": (53, 47, 59, 255),
        "mortar": (20, 17, 24, 255), "accent": SILVER,
    },
    2: {
        "name": "mercury", "style": "brass",
        "floor": (30, 34, 32, 255), "floor_alt": (40, 48, 44, 255),
        "wall_cap": (96, 82, 54, 255), "wall_face": (62, 54, 38, 255),
        "mortar": (22, 26, 24, 255), "accent": GOLD,
    },
    3: {
        "name": "venus", "style": "choir",
        "floor": (38, 22, 36, 255), "floor_alt": (50, 28, 46, 255),
        "wall_cap": (92, 50, 74, 255), "wall_face": (62, 32, 52, 255),
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
            "approval_status": "provisional_m8_asset",
            "associated_entities": entities,
            "modification_history": [f"Generated M8.4 complete atlas: {desc}"],
        })

    for snum, theme in SPHERE_THEMES.items():
        sh, tr, fr = draw_sphere_tile_atlas(snum, theme)
        aid = f"sphere_{snum}_{theme['name']}"
        rel = f"assets/tiles/{aid}.png"
        reg_atlas(aid, rel, sh, f"Sphere {snum} ({theme['name']}) 32x32 tiles & features", [f"sphere:{theme['name']}"])
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
    reg_atlas("emblems", "assets/portraits/emblems.png", em_s, "64x64 woodcut emblems (Title, 7 Spheres, 8 Institutions, Endings, Losses)", ["factions", "spheres", "endings"])
    for k, rect in em_r.items():
        registry["emblems"][k] = {"atlas": "emblems", "rect": rect}

    (PRES / "asset_registry.json").write_text(json.dumps(registry, indent=2) + "\n")
    (PRES / "asset_provenance.json").write_text(json.dumps({"schema": "asset_provenance", "version": 1, "entries": prov_entries}, indent=2) + "\n")
    print(f"Generated {len(prov_entries)} atlases into {ASSETS}")


if __name__ == "__main__":
    main()

