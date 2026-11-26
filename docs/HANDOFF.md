# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-26

- **Branch:** `ccr-c6f8b898-fu2jtp` on `origin` (github.com/sophiashadow/Abyssal-Sovereign). Not merged; no default branch exists yet. Creating `main` or a PR is an owner decision.
- **Milestones:** M0 (foundations) and M1 (playable three-floor slice) are implemented and tested on Linux, from source.
- **Last verified (local, in a Linux container):**
  - `tools/test.sh`: 59 tests, 59 passed, 0 failed, 1331 checks.
  - `tools/ui_smoke.gd` under Xvfb: 21 steps, 0 failures at 1280×720 and at 2340×1080.
  - `tools/soak.gd --salt=heldout`: bot wins 33% of 180 runs.
- **NOT_RUN:** any export build (Linux, Android, Windows, Web), any device test, any human playtest. There is no CI.

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

## Next assignment: Milestone 2 (needs owner review of each design first)

1. **Masks as stances**, which also gives the Occultist a kit. Propose it as a `docs/LORE.md` row tagged Proposed. Implement as a trait plus content, with tests, and confirm on the soak's held-out salt.
2. **Two Eight Chains enemy abilities**, starting with Isolation and Monopolization of Perception (the fog).
3. **Relics**, worked or transmuted.
4. **Named losses** on the death screen.

Smaller known defects you can fix without a design decision, each test-first:

- Awake monsters are omniscient: add last-known-position tracking.
- The player starts on the up stairs, so the `@` hides the `<`.
- Text scale at phone resolution is unverified: inject `user://settings.cfg` before the smoke and check the screenshots.

## Owner decisions still open

- Is apotheosis ("By Decree") a winning ending?
- Is the Unwritten Door canon?
- Where do the origins and callings sit in the lore?
- Android SDK license acceptance and a release keystore. The owner creates the keystore and keeps it outside the repo.

## Do not

- Modify FALSE LIGHT, Sovereign-Ops or any other repository. FALSE LIGHT documents are read-only sources.
- Push to a new branch, merge, publish or release without the owner's explicit authorization for that action.
- Add credentials, keystores, personal or biographical information, or persona and voice documents.
- Settle what the lore sources leave ambiguous, or tune balance against the held-out salt.
- Report a build, test or device result that did not run.
