# Architecture

## Layers

```
content/core/*.json        data: species, classes, items, monsters, statuses, floors
src/core/                  Rng (seeded, saveable), Dice, Grid helpers
src/content/               ContentSchema (field rules), ContentDB (load, validate, look up)
src/gen/                   DungeonGen: pure function (floor def, seed) -> FloorMap + spawn plan
src/sim/                   World, Actor, Item, FloorMap, Tiles, Traits, Fov, Pathing, Combat
src/persistence/           SaveIO (atomic file), SaveCheck (structural validation)
src/ui/                    main.gd (screens, input, autosave), MapView, Palette, GameSettings
tests/                     headless suite, helpers, AutoPlayer bot
tools/                     test.sh, soak.gd (balance), ui_smoke.gd (drives the real UI)
```

Dependencies point one way, down the list. Nothing in `src/sim`, `src/gen`, `src/content` or `src/core` touches a Node, input or rendering. All of it is `RefCounted`. This is why the whole game runs headless in tests and the bot uses the same `World` API as the UI.

**World is the only API the UI calls.** `player_move`, `player_wait`, `player_pickup`, `player_drop`, `player_use`, `player_unequip`, `player_stairs`, `player_rest`, plus read-only queries (`describe_at`, `visible_hostiles`, `current_floor`). An action returns `true` when it spent time. The world then runs monsters until the player's turn comes round again.

## Determinism

- **Run RNG.** One `Rng` per run, seeded from `Rng.derive(run_seed, "play")`. Its state is saved, so a resumed run continues the same random stream. This is tested: a run saved and resumed midway serializes byte-identically to one played straight through (`tests/test_save.gd`).
- **Floor generation.** Each floor is seeded independently with `Rng.derive(run_seed, "floor:N")`, so the floor layout doesn't depend on what you did before arriving. (Monster spawn timing uses the run RNG.)
- **Seed derivation.** `Rng.derive` is FNV-1a over the seed and a salt. It has a golden-value test, so a refactor can't silently change every seed.
- **Iteration order.** No gameplay depends on Dictionary iteration over unordered keys, wall-clock time or frame timing.

## Content

JSON packs are validated against `ContentSchema` at load. The validator reports every error in one pass, each naming its file, entry and field. Ids are stable, and saves refer to content by id. A save records a content fingerprint and warns, without refusing, when the content has changed. Behaviour that needs code is a **trait**, named in content and implemented in `Traits`/`Combat`/`World`. A typo in a trait name is a validation error. See [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md).

## Saves

- **Format.** `user://run.save.json`, holding a `save_version` (currently 2; v1 saves migrate automatically), run state, all visited floors, and the log. Terrain and exploration are base64 byte arrays.
- **Writes are atomic:** the save goes to `.tmp`, then is renamed.
- **Loading.**
  1. Parse the JSON.
  2. Check the version.
  3. `SaveCheck` validates the structure, including content references.
  4. Only then build. A bad save gives readable errors and never a half-built world. The UI offers to discard it but never deletes it unasked.
- **Permadeath.** The save is deleted on death or victory.
- **Autosave triggers:** run start, floor change, every 20 turns, app pause, focus loss and window close.
- **Version changes.** A future `save_version` bump must ship a migration function and a test that loads a stored v1 fixture.

## Decisions

- **D1: Godot 4.7.2, GL Compatibility renderer.** This renderer gives the widest Android/Web coverage, and the game needs no 3D. The pin is recorded in `project.godot`. Upgrading means re-running the full suite and the UI smoke.
- **D2: typed GDScript only.** No C#, so Web export and Android stay simple and there is no .NET runtime.
- **D3: time-based scheduler**, not energy ticks. Speed is easy to read, and the player's tie-win is explicit and tested.
- **D4: glyph rendering via `draw_string` with the engine's default font.** No art pipeline was needed for M1, and the cells scale freely. A tileset can replace `MapView._draw` without touching the sim.
- **D5: UI built in code**, not in `.tscn` layouts. Text and tile scaling apply uniformly, and screens are rebuilt on settings change.
- **D6: generation produces a spawn plan; World instantiates it.** This keeps the generator pure and testable on its own.
- **D7: one save slot, deleted on death.** Permadeath is enforced by data, not by trust.
- **D8: tests are plain GDScript** with a 60-line runner, with no addon dependency. The runner fails on any engine error in the log as well as on assertions.

## Platform notes

- **Linux:** run from source with Godot 4.7.2 or exported via `tools/export.sh linux` (`build/linux/abyssal-sovereign.x86_64` verified launching cleanly).
- **Android:** landscape sensor orientation is set, and `import_etc2_astc` is enabled in `project.godot`. Touch controls default on for touch devices. The back button opens the menu and closes overlays. Autosave on pause covers process kills. Debug APK builds via `tools/export.sh android` (`build/android/abyssal-sovereign-debug.apk`); physical device testing and release signing remain `NOT_RUN`.
- **Windows / Web:** no platform-specific code. Exported via `tools/export.sh windows web` (`build/windows/abyssal-sovereign.exe` and `build/web/index.html`). On Web, Quit is hidden, and `user://` maps to IndexedDB (browser runtime/persistence `NOT_RUN`; Windows runtime `NOT_RUN`).
