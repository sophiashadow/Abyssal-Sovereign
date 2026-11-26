# ABYSSAL SOVEREIGN

An original turn-based traditional roguelike set beneath Terra Tenebrae, in the cosmology of FALSE LIGHT. It is built with Godot 4 and typed GDScript, and plays fully offline.

**Status: v0.4 (Milestones 0–4 implemented, export presets & builds ready on Linux).** It has a title screen, character creation (3 origins × 3 callings), and a seeded seven-sphere descent (Moon through Saturn). Gameplay covers:

- Field of view with exploration memory.
- Melee combat, XP and levels.
- Equipment, consumables, and Relics (Work for temporary power with a cost, or Transmute for permanent stats).
- **Masks as stances** (`m` key / Mask button for Occultists: Bare Face, Nyx, Eris, Lilith) with risk accrual and seizures.
- The **False Light** status: relief, then the Reckoning.
- **Eight Chains** enemy abilities (Isolation and Monopolized Sight fog).
- **Sphere Gates** between Spheres (`Stormed`, `Serpent's Key`, `Given Back`, `By Name`) and the **Apotheosis Guard**.
- The Preliator Sentinel guardian, **Named losses** (Catalogued, Fluent, Gilded), and four victory outcomes (Unwritten Door, The Serpent's Way, The Way of Return, and Victory: By Decree).
- Permadeath with atomic save/resume (`save_version` 3, migrating v1/v2 saves).

Android, Windows and Web builds can be exported via `tools/export.sh` (see [ROADMAP.md](ROADMAP.md); Windows runtime, Web browser `user://` persistence, and physical Android device runtime tests have not run yet). Any distributed export must ship Godot's license notices.

## Run it

The game requires Godot **4.7.2** (standard build, not .NET).

```sh
godot --path .                 # play
tools/test.sh                  # headless test suite (exit 0 = all passed)
tools/test.sh test_save        # one test file
tools/verify.sh                # full local regression gate (tests + desktop/phone UI smoke)
tools/verify.sh --exports      # also refresh all 4 platform exports and verify outputs
tools/export.sh                # export Linux, Windows, and Web builds into build/
tools/export.sh all            # also export Android debug APK into build/android/
godot --headless --path . --script res://tools/soak.gd -- --seeds=20            # balance soak
xvfb-run -a godot --path . --audio-driver Dummy --script res://tools/ui_smoke.gd # UI smoke (needs a display)
```

`tools/test.sh` finds Godot from `$GODOT`, then `godot` on `PATH`, then `./.tools/godot`. A failed test that used random seeds prints the seed so it can be replayed.

## Controls

| Action | Keyboard | Touch / mouse |
|---|---|---|
| Move / attack | arrows, numpad, `hjklyubn` | d-pad, or tap an adjacent tile |
| Travel | | tap a remembered tile (stops when a new enemy appears) |
| Wait | `.` `5` space | centre of the d-pad, or tap yourself |
| Pick up | `g` `,` | Get, or tap yourself |
| Stairs | Enter `>` `<` | Stairs, or tap yourself on stairs |
| Rest | `r` | Rest |
| Inventory | `i` | Bag |
| Masks (Occultist) | `m` | Mask |
| Inspect | `x`, then tap | Look, long-press or right-click |
| Menu | Esc | Menu, Android back |

Text size, tile size, travel speed and on-screen controls are under Settings.

## Documents

- [DESIGN.md](DESIGN.md): what the game is and how the mythology becomes mechanics.
- [ARCHITECTURE.md](ARCHITECTURE.md): code layout, layering and decisions.
- [ROADMAP.md](ROADMAP.md): milestones and known defects.
- [docs/LORE.md](docs/LORE.md): canon / interpretation / proposed ledger.
- [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md): JSON content format.
- [AGENTS.md](AGENTS.md): rules for coding agents.
- [docs/HANDOFF.md](docs/HANDOFF.md): current state and next assignment for the next agent.

## Rights

The code is original to this project. FALSE LIGHT names, lore and palette are the owner's own creative property and are used by the owner's authorization. The project includes no third-party code or assets beyond the Godot engine, whose license notices must ship with any exported build. All rights reserved; no license is granted.
