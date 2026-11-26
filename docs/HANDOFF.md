# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-26

- **Branch:** `main` (default branch on `origin`, github.com/sophiashadow/Abyssal-Sovereign), preserving full commit history from `ccr-c6f8b898-fu2jtp`.
- **Milestones:** M0–M4, **M5.1 (Character Development)** (`37e5984`, pushed), and **M5.2 (Combat Depth)** are implemented (`ranged` weapons/projectiles/scrolls, 5 damage types + resistances, `30` talents incl. tactical movement, status combos, monster specials, mutated elites & Sphere 3/5 mid-bosses, `SAVE_VERSION := 5`, Aim Mode UI).
- **Last verified (local, Linux):**
  - `tools/verify.sh` (M5.2):
    - `tools/test.sh`: 88 tests, 88 passed, 0 failed, 1598 checks (0 engine errors).
    - `tools/ui_smoke.gd` at `1280×720` and `2340×1080`: 21 steps, 0 failures each.
  - `tools/soak.gd --seeds=15 --salt=heldout` (M5.2 balance pass): bot wins `83%` (`112/135` runs, mean `711` turns).
  - *Prior M4 exports (`build/`)*: `tools/export.sh all` refreshed Linux/Windows/Web/Android-debug exports at v0.4 (`apksigner verify` SHA-256 `a0000912831e593cdea65be68bda40f99f0d0e4d779332fff711199eb578a279`); exports have not yet been rebuilt after M5.1/M5.2.
- **NOT_RUN:** Post-M5.1/M5.2 platform exports, Windows runtime, Web browser `user://` persistence test, physical Android device install/test (no device attached to `adb`), release-signed Android APK, M5.2 human playtest. There is no CI.

## Setup

1. Install Godot **4.7.2** (standard build, not .NET).
2. Make it reachable as `$GODOT`, as `godot` on `PATH`, or as a `./.tools/godot` symlink (gitignored).
3. Run `tools/verify.sh` (or `tools/test.sh`); it must exit 0 before you change anything.
4. Android physical-device install (once USB debugging is enabled and `adb devices` shows your device): `adb install -r build/android/abyssal-sovereign-debug.apk`.

## Where things are

- `ARCHITECTURE.md`: layers, determinism, saves, decisions D1–D8.
- `DESIGN.md`: rules, numbers, balance table.
- `ROADMAP.md`: known defects and the next milestones.
- `docs/LORE.md`: every lore element tagged Canon / Interpretation / Proposed, plus excluded material and open owner decisions.
- `docs/CONTENT_SCHEMA.md`: the JSON content format. A test checks that it matches the code.

## Milestone 2 (done 2026-11-26)

1. ~~**Masks as stances**~~ (`Masks`, `mask_stances` trait on Occultist, `SAVE_VERSION := 2` with v1→v2 migration, HUD/`m` key/overlay, `tests/test_masks.gd`).
2. ~~**Two Eight Chains enemy abilities**~~ (`chain_isolation` on `false_sun_cultist` and `chain_fog` / `perception_fog` on `preliator_sentinel`, tests in `tests/test_ai.gd`).
3. ~~**Relics, worked or transmuted**~~ (`kind: "relic"` schema + `Confessor's Glass`, `Ophite Key`, `Broken Halo` in `items.json` / `floors.json`, `player_work_relic` / `player_transmute_relic` in `World`, UI buttons in `main.gd`, tests in `tests/test_items.gd`).
4. ~~**Named losses**~~ (`World.named_loss()` classifying `Gilded`, `Fluent`, and `Catalogued` on the death screen, tests in `tests/test_turns.gd`).

## Next assignment: M5.3–M5.5 Depth Pass + Playtest & Platform Verification

- **M5.3 (Equipment and discovery):** Procedurally generated equipment affixes, equipment rarity and unique artifacts, unidentified potions/scrolls/magical equipment, cursed and blessed equipment, equipment sets and build synergies, and additional relics from authorized FALSE LIGHT mythology.
- **M5.4–M5.5:** Dungeon ecology (traps, secret doors, altars/shrines/ritual circles, locked vaults, merchants/wandering encounters, hazards, Sphere features) and Metaphysical depth (complete Eight Chains enemy grammar, rituals/contracts, Masks/Relics/False Light/Apotheosis/Two Ways interactions).
- **Milestone 3 remaining:** Rebuild exports after M5 milestones, install `build/android/abyssal-sovereign-debug.apk` on a physical Android device (`adb install -r build/android/abyssal-sovereign-debug.apk`) and test touch, back button, and autosave on kill; test Windows binary on Windows; verify Web `user://` IndexedDB persistence in a browser; configure release signing with an owner-created keystore outside the repo.
- **Human playtest & polish:** Playtest M5.1 + M5.2 ranged combat, projectiles, scrolls, status combos, and Sphere mid-bosses; review remaining items in `ROADMAP.md` (monospace glyph font, colour-blind palette).

Smaller known defects (fixed 2026-11-26):

- ~~Awake monsters are omniscient: add last-known-position tracking.~~ (Fixed: monsters pursue last-seen position and lose awareness once they check it and still don't see the player.)
- ~~The player starts on the up stairs, so the `@` hides the `<`.~~ (Fixed: depth 1 spawns the player adjacent to `<`.)
- ~~Text scale at phone resolution is unverified: inject `user://settings.cfg` before the smoke and check the screenshots.~~ (Verified at `2340x1080` with `text_scale_index=2`, `tile_size_index=4`, `touch_controls=true`: 21/21 smoke steps passed; HUD, inventory, settings, and map render cleanly, with the character creation screen's bottom action row slightly below the fold in its scroll container.)

## Owner decisions still open

- Android SDK license acceptance and a release keystore. The owner creates the keystore and keeps it outside the repo.

*(Resolved 2026-11-26: Apotheosis can be a win; the Unwritten Door is canon; origins and callings are canon. Recorded in `docs/LORE.md`.)*

## Do not

- Modify FALSE LIGHT, Sovereign-Ops or any other repository. FALSE LIGHT documents are read-only sources.
- Push to a new branch, merge, publish or release without the owner's explicit authorization for that action.
- Add credentials, keystores, personal or biographical information, or persona and voice documents.
- Settle what the lore sources leave ambiguous, or tune balance against the held-out salt.
- Report a build, test or device result that did not run.
