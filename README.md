# Abyssal Sovereign (`v1.0.0-rc.1`)

**An original turn-based traditional roguelike set in a sealed, seven-layered labyrinth beneath Terra Tenebrae.**

Abyssal Sovereign combines classical deterministic dungeon crawling, occult-medieval Gnostic theology, multi-faction contracts, and dual graphical/ASCII presentation — built to run **100% offline** with zero accounts, ads, subscriptions, or telemetry.

> **Release Candidate Status:** `v1.0.0-rc.1` is feature-complete locally on `main` and packaged for external review and human playtesting (`docs/PLAYTEST.md`). Windows runtime, Web IndexedDB persistence, physical Android hardware testing, human playtest rounds, external commissioned art (`provisional_m9_asset`), and original VENEFICA LUX soundtrack stems (`placeholder_liturgical_temp`) remain pending before final `v1.0.0` release.

---

## Core Features

- **Deep Character Creation:** 8 Origins × 8 Callings (`64` combinations) and `104` talents across `24` talent trees, including Veil-Touched affinities and Mask stances.
- **Seven Planetary Spheres (`28` Floors):** Descend from *Sphere 1 — Moon* through *Saturn*, spanning `86` monsters (including `15` Sphere guardians and bosses) and side branches.
- **Occult Ars Moriendi & Gear:** `165` base items, `46` affixes, `12` equipment sets, `26` named artifacts, and `16` interactive Relics with repeatable Relic Work and permanent Transmutation.
- **Living Labyrinth & Contracts:** `18` persistent NPCs, `8` competing institutions, `24` quest/narrative threads, consequential Contracts (with vows and breaking penalties), and four distinct Victory endings alongside permanent death.
- **Four Difficulty Profiles:** **Initiate**, **Exile** (canonical baseline), **Adversary**, and **Sovereign** — adjusting enemy density, elite pressure, and item cadence without artificial stat multipliers.
- **Dual Presentation & Accessibility:**
  - Switch live between **Tiles** mode (`13` pixel-art atlases, `24` woodcut emblems, radial lantern lighting) and **Glyph** mode (`CP437`-inspired traditional ASCII/symbol rendering).
  - Supports desktop keyboard/mouse, dedicated zero-scroll mobile **Portrait** and **Landscape** touch docks (optional **Left-Handed** swap), collapsible `Stats ▾` drawer, Android Back routing, text/tile scaling, camera zoom, **Reduced Motion**, **Instant Actions**, **High Contrast**, and **Deutan/Protan** + **Tritan** color filters.
- **Offline Liturgical Soundscape:** `47` mastered offline audio assets across 6 independent volume buses (`Master`, `Music`, `Ambience`, `Combat`, `Interface`, `Narrative`), playable at 100% silent mute.
- **Save Reliability:** Deterministic turn simulation with Save Version `12` and backwards-compatible `v1`–`v12` save migrations (`docs/INSTALL.md`).

---

## Quick Start (Players & Playtesters)

- **Install & Launch:** See [`docs/INSTALL.md`](docs/INSTALL.md) for Linux, Windows, Android APK, and Web instructions, OS `user://` save paths, backup/recovery, and offline details.
- **Human Playtest Guide:** See [`docs/PLAYTEST.md`](docs/PLAYTEST.md) for controls, tactical advice, accessibility testing matrix, bug reporting, and playtest questionnaire.
- **Release Materials:** See [`docs/release/`](docs/release/) (`RELEASE_NOTES.md`, `PRODUCT_KIT.md`, `PRIVACY.md`, `CREDITS_AND_LICENSES.md`).

---

## Building, Testing & Packaging from Source (Godot `4.7.2`)

Requires **Godot 4.7.2 stable** (GL Compatibility renderer). All tools work completely offline:

```sh
# Run the full automated unit, determinism, save-migration, content, audio, & asset test suite
./tools/test.sh

# Run full regression + UI smoke across 1280x720, 2340x1080, and 720x1280 + exports
./tools/verify.sh --exports

# Export and package portable RC1 archives + SHA256SUMS into build/release/
./tools/package_rc.sh v1.0.0-rc.1
```

Optional tooling in `tools/`:
- `python3 tools/gen_sprites.py` — regenerate sprite atlases, woodcut emblems, and launcher icons.
- `python3 tools/gen_audio.py` — regenerate RMS-mastered offline `.ogg` SFX, ambience loops, and temporary music stems.
- `./tools/m7_run.sh` / `tools/m8_perf_bench.gd` / `tools/ui_smoke.gd` — deterministic balance soaks, benchmarks, and multi-viewport UI verification.

---

## Documentation Index

- `ARCHITECTURE.md` — Layered codebase isolation (`core`, `content`, `gen`, `sim`, `persistence`, `ui`), save schema decisions
- `DESIGN.md` — Gameplay mechanics, Sphere structure, combat math, and soak findings
- `ROADMAP.md` — Milestones M0 through M9
- `docs/M9_REPORT.md` & `docs/RELEASE_CHECKLIST.md` — RC1 verification report and open human/owner gates
