# Agent instructions: ABYSSAL SOVEREIGN

This is the canonical instruction file. `CLAUDE.md` points here.

## Boundaries

- **Repository scope.** This repository is independent. Do not modify FALSE LIGHT, Sovereign-Ops or any other repository. FALSE LIGHT documents are read-only source material.
- **Authorization.** No pushing, publishing, releasing, merging or creating remotes without the owner's explicit authorization for that action.
- **Privacy.** No credentials, signing keys or personal or biographical information in tracked files. The protagonist is never the author's persona. Persona and voice documents are never bundled.
- **Lore.** Every new lore element gets a row in `docs/LORE.md`, tagged Canon (with its source), Interpretation, or Proposed. Never settle what the sources leave ambiguous.
- **Evidence.** Never report a test, build or device result that did not actually run. Report NOT_RUN for anything that didn't run.

## Code rules

- `src/core`, `src/content`, `src/gen`, `src/sim` and `src/persistence` stay free of Nodes, input and rendering. The UI talks only to `World`.
- Typed GDScript. Content changes go in JSON. Behaviour goes in a named trait, plus an entry in `Traits.KNOWN` and in `docs/CONTENT_SCHEMA.md`. A test enforces the doc.
- Determinism:
  - All randomness comes from the run `Rng` or a derived seed.
  - Nothing may depend on frame time or unordered iteration.
  - The resumed-run test in `tests/test_save.gd` must keep passing.
- Any change to the save shape bumps `World.SAVE_VERSION`, adds a migration, and adds a test.
- Bug fixes start with a failing test.
- Balance changes go through `tools/soak.gd` and are confirmed on a held-out `--salt`. Record each one in the DESIGN.md balance table.

## Commands

```sh
tools/test.sh                                   # must exit 0
godot --headless --path . --script res://tools/soak.gd -- --seeds=20 --salt=heldout
xvfb-run -a godot --path . --audio-driver Dummy --script res://tools/ui_smoke.gd
```

Godot 4.7.2. `tools/test.sh` looks for `$GODOT`, then `godot`, then `./.tools/godot`.
