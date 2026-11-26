# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-26

- **Branch:** `main` (default branch on `origin`, github.com/sophiashadow/Abyssal-Sovereign), preserving full commit history from `ccr-c6f8b898-fu2jtp`.
- **Milestones:** M0–M5 (`fac51e8`, Depth Pass complete), **M6.1** (Atlas: 28 floors, save v9), **M6.2** (Inhabitants: 76 archetypes, 15 bosses/guardians), **M6.3** (Origins & Callings: 8×8, 104 talents), **M6.4** (Armory & Treasury: 165 items, 46 affixes, 12 sets, 26 artifacts, 16 relics), **M6.5 (People, Institutions and Allegiances, save v10)** — `18` recurring NPCs across `8` two-minded institutions, deterministic placement, standing (`-2..+3`), institutional pole splits (no good/evil meter), People overlay (`p`).
- **Last verified (local, Linux, M6.5):**
  - `tools/verify.sh` (M6.5):
    - `tools/test.sh`: `123` tests, `123` passed, `0` failed, `2245` checks (`0` engine errors).
    - `tools/ui_smoke.gd` at `1280×720` and `2340×1080`: `21` steps, `0` failures each.
  - `tools/soak.gd --seeds=2 --salt=heldout` (M6.3): bot wins `69%` (`88/128` runs across all `64` pairs, mean `918` turns).
  - *Prior M4 exports (`build/`)*: `tools/export.sh all` refreshed Linux/Windows/Web/Android-debug exports at v0.4 (`apksigner verify` SHA-256 `a0000912831e593cdea65be68bda40f99f0d0e4d779332fff711199eb578a279`); exports have not yet been rebuilt after M5.1–M6.5.
- **NOT_RUN:** Post-M5.1–M6.5 platform exports, Windows runtime, Web browser `user://` persistence test, physical Android device install/test (no device attached to `adb`), release-signed Android APK, M5.2–M6.5 human playtest. There is no CI.

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

## Next assignment: Milestone 6 Breadth Pass (`docs/M6_SPEC.md`)

- **M6.1 (The Atlas of Terra Tenebrae):** Done (2026-11-26).
- **M6.2 (The Inhabitants):** Done (2026-11-26).
- **M6.3 (Origins and Callings):** Done (2026-11-26).
- **M6.4 (The Armory and Treasury):** Done (2026-11-26).
- **M6.5 (People, Institutions and Allegiances):** Done (2026-11-26).
- **Next:** **M6.6 (Threads Beneath the Record)** — add `"threads"` (`24` multi-stage threads, deterministic per-run subset, delayed consequences, alternative resolutions, refusal/abandonment outcomes) and `SAVE_VERSION := 11`. Then M6.7–M6.10 per `docs/M6_SPEC.md`.
- **Platform verification (M3 / M6.10):** Rebuild exports after M6 tranches (`tools/export.sh`), test physical Android device / Windows / Web when available, and configure release signing with an owner-created keystore outside the repo.

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
