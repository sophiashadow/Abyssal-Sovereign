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
            # Bone-dust or subtle floor crack
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
        if v == 1:
            # Ossuary niche / arch inset
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


def draw_avatars_vertical_slice() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(8, 4, 32)
    rects: dict[str, list[int]] = {}

    def make_char(key: str, hood_col, robe_col, trim_col, weapon_col=None):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.ellipse([9, 26, 23, 30], fill=(8, 6, 9, 140))
        d.polygon([(16, 11), (24, 27), (8, 27)], fill=robe_col, outline=trim_col)
        d.ellipse([11, 4, 21, 13], fill=hood_col, outline=trim_col)
        d.point([(14, 8), (18, 8)], fill=IVORY)
        if weapon_col:
            d.line([(23, 10), (23, 24)], fill=weapon_col, width=2)
            d.line([(20, 19), (26, 19)], fill=GOLD)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    make_char("origin:default", SILVER, PORPHYRY, GOLD)
    make_char("origin:human", RECORD, PORPHYRY, GOLD)
    make_char("origin:revenant", SILVER_DK, IRON_DK, SILVER)
    make_char("origin:cambion", BLOOD, PORPHYRY_LT, EMBER)
    make_char("calling:default", VOID_T, VOID_T, GOLD, SILVER)
    # Calling trim overlay (drawn atop origin)
    for cl, col, wep in (
        ("fallen_knight", IRON_HI, SILVER),
        ("occultist", LUX, GOLD_HI),
        ("assassin", IRON_DK, ALERT),
    ):
        k = f"calling:{cl}"
        s.next_tile(k)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.line([(16, 13), (16, 26)], fill=col, width=2)
        d.line([(24, 8), (24, 23)], fill=wep, width=2)
        t = outline_sprite(t)
        s.commit(k, t)
        rects[k] = s.rects[k]

    # Mask overlays
    for mk, mcol in (("nyx", SILVER), ("eris", BLOOD), ("lilith", LUX), ("lux_venefica", GOLD_HI)):
        k = f"mask:{mk}"
        s.next_tile(k)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        d.ellipse([12, 5, 20, 12], outline=mcol)
        if mk == "lilith":
            d.point([(16, 7)], fill=LUX)
        elif mk == "lux_venefica":
            d.arc([8, 2, 24, 16], 180, 360, fill=LUX)
        s.commit(k, t)
        rects[k] = s.rects[k]

    return s, rects


def draw_monsters_vertical_slice() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(8, 2, 32)
    rects: dict[str, list[int]] = {}

    def mon(key: str, shape: str, fill_c, accent_c):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        if shape == "beast":
            d.ellipse([7, 15, 23, 25], fill=fill_c, outline=accent_c)
            d.ellipse([19, 12, 26, 19], fill=fill_c)
            d.line([(5, 19), (9, 17)], fill=accent_c)
            d.point([(23, 14)], fill=ALERT)
        elif shape == "undead":
            d.polygon([(16, 11), (22, 27), (10, 27)], fill=fill_c, outline=accent_c)
            d.ellipse([12, 5, 20, 12], fill=RECORD, outline=accent_c)
            d.point([(14, 8), (18, 8)], fill=VOID)
        elif shape == "cultist":
            d.polygon([(16, 9), (24, 27), (8, 27)], fill=fill_c, outline=accent_c)
            d.ellipse([12, 4, 20, 11], fill=accent_c)
            d.line([(23, 10), (23, 24)], fill=FALSE_SUN)
        elif shape == "construct":
            d.rectangle([9, 8, 23, 26], fill=fill_c, outline=accent_c)
            d.rectangle([12, 11, 20, 15], fill=FALSE_SUN)
        else:
            d.polygon([(16, 5), (25, 16), (22, 27), (10, 27), (7, 16)], fill=fill_c, outline=accent_c)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    mon("default", "undead", IRON, RECORD)
    mon("family:vermin", "beast", TEXT_DIM, BLOOD)
    mon("family:ossuary_undead", "undead", IRON_DK, RECORD)
    mon("family:dominion_soldier", "cultist", IRON, GOLD)
    mon("family:inquisition_agent", "cultist", PORPHYRY_LT, FALSE_SUN)
    mon("family:false_sun_manifestation", "construct", GOLD, FALSE_SUN)
    mon("warren_rat", "beast", (124, 102, 86, 255), ALERT)
    mon("catalogued_dead", "undead", IRON_DK, RECORD)
    mon("preliator_sentinel", "construct", IRON_HI, FALSE_SUN)
    return s, rects


def draw_npcs_vertical_slice() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(4, 1, 32)
    rects: dict[str, list[int]] = {}
    s.next_tile("default")
    t = Image.new("RGBA", (32, 32), VOID_T)
    d = ImageDraw.Draw(t)
    d.polygon([(16, 11), (24, 27), (8, 27)], fill=SAGE_DK, outline=SAGE)
    d.ellipse([12, 5, 20, 12], fill=IVORY, outline=SAGE)
    t = outline_sprite(t)
    s.commit("default", t)
    rects["default"] = s.rects["default"]
    return s, rects


def draw_items_vertical_slice() -> tuple[Sheet, dict[str, list[int]]]:
    s = Sheet(8, 2, 32)
    rects: dict[str, list[int]] = {}

    def item_draw(key: str, fn):
        s.next_tile(key)
        t = Image.new("RGBA", (32, 32), VOID_T)
        d = ImageDraw.Draw(t)
        fn(d)
        t = outline_sprite(t)
        s.commit(key, t)
        rects[key] = s.rects[key]

    item_draw("default", lambda d: d.rectangle([11, 11, 21, 21], fill=GOLD, outline=IVORY))
    item_draw("kind:weapon", lambda d: (d.line([(9, 23), (23, 9)], fill=SILVER, width=3), d.line([(10, 17), (15, 22)], fill=GOLD, width=2)))
    item_draw("kind:ranged", lambda d: (d.arc([8, 6, 22, 26], 270, 90, fill=GOLD, width=2), d.line([(15, 7), (15, 25)], fill=RECORD)))
    item_draw("kind:armor", lambda d: d.polygon([(10, 9), (22, 9), (24, 15), (21, 24), (11, 24), (8, 15)], fill=IRON_HI, outline=SILVER))
    item_draw("kind:amulet", lambda d: (d.ellipse([11, 8, 21, 18], outline=GOLD, width=2), d.ellipse([13, 17, 19, 23], fill=LUX, outline=IVORY)))
    item_draw("kind:consumable", lambda d: (d.rectangle([13, 8, 19, 12], fill=RECORD), d.ellipse([10, 12, 22, 24], fill=BLOOD, outline=IVORY)))
    item_draw("kind:consumable:scroll", lambda d: (d.rectangle([10, 9, 22, 23], fill=RECORD, outline=GOLD), d.line([(12, 13), (20, 13)], fill=LUX), d.line([(12, 17), (18, 17)], fill=VOID)))
    item_draw("kind:consumable:projectile", lambda d: (d.line([(9, 22), (22, 9)], fill=SILVER, width=2), d.polygon([(23, 8), (18, 9), (22, 13)], fill=ALERT)))
    item_draw("kind:relic", lambda d: (d.polygon([(16, 6), (24, 16), (16, 26), (8, 16)], fill=FALSE_SUN, outline=LUX), d.ellipse([13, 13, 19, 19], fill=IVORY)))
    item_draw("kind:key", lambda d: (d.ellipse([9, 11, 16, 18], outline=GOLD_HI, width=2), d.line([(16, 15), (24, 15)], fill=GOLD_HI, width=2), d.line([(21, 15), (21, 19)], fill=GOLD_HI, width=2)))
    return s, rects


SPHERE_THEMES = {
    1: {
        "name": "moon",
        "floor": (28, 24, 32, 255),
        "floor_alt": (36, 31, 42, 255),
        "wall_cap": (76, 70, 84, 255),
        "wall_face": (53, 47, 59, 255),
        "mortar": (20, 17, 24, 255),
        "accent": SILVER,
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
            "modification_history": [f"Generated M8.2 vertical slice: {desc}"],
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

    av_s, av_r = draw_avatars_vertical_slice()
    reg_atlas("avatars", "assets/sprites/avatars.png", av_s, "Vertical-slice layered player avatars & masks", ["player", "species", "classes", "masks"])
    for k, rect in av_r.items():
        registry["avatars"][k] = {"atlas": "avatars", "rect": rect}

    mo_s, mo_r = draw_monsters_vertical_slice()
    reg_atlas("monsters", "assets/sprites/monsters.png", mo_s, "Vertical-slice monster family silhouettes", ["monsters"])
    for k, rect in mo_r.items():
        registry["monsters"][k] = {"atlas": "monsters", "rect": rect}

    np_s, np_r = draw_npcs_vertical_slice()
    reg_atlas("npcs", "assets/sprites/npcs.png", np_s, "Vertical-slice NPC base sprite", ["npcs"])
    for k, rect in np_r.items():
        registry["npcs"][k] = {"atlas": "npcs", "rect": rect}

    it_s, it_r = draw_items_vertical_slice()
    reg_atlas("items", "assets/sprites/items.png", it_s, "Vertical-slice item category sprites", ["items"])
    for k, rect in it_r.items():
        registry["items"][k] = {"atlas": "items", "rect": rect}

    (PRES / "asset_registry.json").write_text(json.dumps(registry, indent=2) + "\n")
    (PRES / "asset_provenance.json").write_text(json.dumps({"schema": "asset_provenance", "version": 1, "entries": prov_entries}, indent=2) + "\n")
    print(f"Generated {len(prov_entries)} atlases into {ASSETS}")


if __name__ == "__main__":
    main()
