# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-26

- **Branch:** `ccr-c6f8b898-fu2jtp` on `origin` (github.com/sophiashadow/Abyssal-Sovereign). Not merged; no default branch exists yet. Creating `main` or a PR is an owner decision.
- **Milestones:** M0 (foundations), M1 (playable three-floor slice), M2 (Masks as stances, Eight Chains abilities, Relics, Named losses), and M3 (export presets + Linux/Windows/Web/Android-debug builds) are implemented.
- **Last verified (local, Linux):**
  - `tools/test.sh`: 71 tests, 71 passed, 0 failed, 1392 checks.
  - `tools/ui_smoke.gd` (`1280×720` and `2340×1080` phone settings): 21 steps, 0 failures.
  - `tools/soak.gd --salt=heldout`: bot wins 39% of 180 runs.
  - `tools/export.sh all`: built `build/linux/abyssal-sovereign.x86_64` (71M, smoke-tested with `--audio-driver Dummy --quit-after 30`), `build/windows/abyssal-sovereign.exe` (105M), `build/web/index.html` (39M total), and `build/android/abyssal-sovereign-debug.apk` (56M, debug-signed, contains `assets/content/core/classes.json`).
- **NOT_RUN:** Windows runtime, Web browser `user://` persistence test, physical Android device test, release-signed Android APK, any human playtest. There is no CI.

## Setup

1. Install Godot **4.7.2** (standard build, not .NET).
2. Make it reachable as `$GODOT`, as `godot` on `PATH`, or as a `./.tools/godot` symlink (gitignored).
3. Run `tools/test.sh`; it must exit 0 before you change anything.
4. The UI smoke needs a display: `xvfb-run -a godot --path . --audio-driver Dummy --script res://tools/ui_smoke.gd -- --shots=test-results/shots`. Screenshots go to the gitignored `test-results/`.

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

## Next assignment: Milestone 4 (depth) and Milestone 3 remaining verification

- **Milestone 3 remaining:** Test Windows binary on Windows, verify Web `user://` IndexedDB persistence in a browser, test the Android debug APK on a physical device (touch, back button, autosave on kill), and configure release signing with an owner-created keystore outside the repo.
- **Milestone 4 (depth):** Seven Spheres as depth bands with gates, the two Ways as alternative victories, and the Apotheosis ("By Decree") guard/victory.

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
