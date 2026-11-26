# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-26

- **Branch:** `main` (default branch on `origin`, github.com/sophiashadow/Abyssal-Sovereign), preserving full commit history from `ccr-c6f8b898-fu2jtp` and `fac51e8`.
- **Milestones:** M0–M5 (`fac51e8`, Depth Pass complete), **M6 Breadth Pass (M6.1–M6.10 COMPLETE, save v11):**
  - **M6.1** Atlas of Terra Tenebrae (`28` floors across 7 Spheres, regional terrain & portals, save v9).
  - **M6.2** The Inhabitants (`76` monster archetypes, `15` named bosses/guardians, 10 tactical AI behaviors, 8 elite mutations, squad grouping).
  - **M6.3** Origins & Callings (`8` origins, `8` callings, `104` talents across 24 trees, 10 traits, Android-readable creation UI).
  - **M6.4** The Armory and Treasury (`165` base items, `46` affixes, `12` sets with `subjugation_cap_bonus`, `26` unique artifacts, `16` Work-vs-Transmute relics, distributed loot pools).
  - **M6.5** People, Institutions & Allegiances (`18` recurring NPCs across `8` two-minded institutions, standing `-2..+3`, no good/evil scalar, save v10).
  - **M6.6** Threads Beneath the Record (`24` multi-stage threads, seeded 8-thread per-run pool, goal/sacrifice/refusal/abandonment resolution paths, delayed aftermath scheduler, Thread Journal `j`, save v11).
  - **M6.7** Dungeon Variety & Emergent Encounters (`10` composable `RoomArchetypes` preserving 100% connectivity + `rune_puzzle`, `abandoned_rite`, `sanctuary_hearth`, `echo_cache`).
  - **M6.8** Discovery, Codex & Run History (`user://codex.json`, knowledge-only, zero power, zero spoilers, Codex overlay `k`, enriched end-of-run summaries).
  - **M6.9** Portable Worldbuilding Manifest (`content/lore/world_manifest.json` `schema_version: 1` + `docs/WORLD_MANIFEST.md` + validator).
  - **M6.10** Integration, Reachability (`tests/test_reachability.gd`), Final Held-Out Validation Soak, Platform Exports (`tools/export.sh all`), & M7 Handoff.
- **Last verified (local, Linux, M6.10):**
  - `tools/verify.sh` (M6.10):
    - `tools/test.sh`: `131` tests, `131` passed, `0` failed, `3883` checks, `142.7s` (`0` engine errors).
    - `tools/ui_smoke.gd` at `1280×720` and `2340×1080`: `21` steps, `0` failures each.
  - Fresh held-out final validation soak (`godot --headless --path . --script res://tools/soak.gd -- --seeds=3 --salt=m6_final_validation`, `192` runs across all `64` pairs, `497.6s`):
    - Overall: `144 / 192` wins (`75%`), mean `870` turns.
    - Origins (`24` each): `ashborn 22/24`, `human 19/24`, `ironbound_ward 19/24`, `cambion 18/24`, `penitent 18/24`, `revenant 17/24`, `unrecorded 16/24`, `veilkin 15/24`.
    - Callings (`24` each): `false_light_alchemist 22/24`, `occultist 21/24`, `preliator_warden 21/24`, `assassin 19/24`, `fallen_knight 18/24`, `tithe_marksman 17/24`, `ophite_binder 16/24`, `rite_weaver 10/24`.
    - Telemetry: `avg_talents=7.16`, `avg_npcs=0.22`, `avg_threads_seen=0.64`, `avg_threads_settled=0.00`, `branch_visits=0` (`AutoPlayer` follows spine exits directly).
  - Platform exports (`tools/export.sh all`):
    - Linux release: `build/linux/abyssal-sovereign.x86_64` (`71M`, `--audio-driver Dummy --quit-after 30` exited `0` cleanly, `0` script/content errors).
    - Android debug APK: `build/android/abyssal-sovereign-debug.apk` (`56M`, `177` files, `apksigner verify` SHA-256 `777545a61a5baa73f685da7d04c543ab18bbb2a4bb7d6dc266a20546787a00e5`).
    - Windows export: `build/windows/abyssal-sovereign.exe` (`105M`); Web export: `build/web/index.html` (`5.5K`).
- **NOT_RUN:** Windows runtime execution, Web browser `user://` IndexedDB persistence check, physical Android device install/playtest (no `adb` device connected), release-signed Android APK (no owner keystore outside repo), and M5.2–M6.10 human playtesting. There is no CI.

## M7 Refinement Pass: in progress (branch `ccr-4b7d6997-36eyn5`, draft PR #1)

Spec: `docs/M7_SPEC.md`. Owner authorized a push after each task (2026-11-26); no merge, release or publish.

- **M7.1 Instrumented Abyss: implemented and tested locally.** `src/sim/telemetry.gd` (local observer), `tests/policy_player.gd` (8 policies), `tools/m7_soak.gd`, `tools/m7_report.gd`, `tools/m7_run.sh`, `balance/validation_ledger.txt`. `tools/test.sh`: 137 tests, 137 passed, 3917 checks. No validation salt spent; dev salt `m7dev`.
- **Datasets (bot play, dev seeds, not human play):** `balance/b1_summary.md` (1248 runs, all policies), `balance/b2_summary.md` (384 runs; specialist, explorer and narrative re-run after bot fixes and mask discipline), `balance/mk1_summary.md` (occultist mask-discipline probe). Reproduce: `tools/m7_run.sh TAG --seeds=N [--policies=...]`. Raw JSONL is gitignored.
- **Findings so far:**
  - Rite Cantor and Occultist weakness under generic bots was a bot-competence gap (specialist rite_weaver wins 16/16 in b2; occultist with mask discipline rose from 50% to 79% in mk1, n=24).
  - d2 mortality is largely dive pace (specialist enters d2 at level 1.6).
  - Veil-Touched and Unrecorded trail by 15 to 20 points under generic play; radiant is 20.7% of damage taken and void 7.4%, so Veil-Touched's void +35 is near-worthless while its radiant -25 bites.
  - Ophite Binder is weakest in explorer (31%).
  - 14 active talents were never used by any policy in b2 (backstep, chain_reversal, cleanse_vapor, fade_to_ash, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step, volatile_salve).
  - `the_taken_name` contract: 21 broken vs 2 fulfilled in narrative and explorer runs; to be read in M7.6.
  - Threads silently auto-abandon after 350 turns at depth 5 or deeper.
- **Next:** M7.2 origin and calling changes, each logged in `balance/CHANGES.md` with dev re-measure; then M7.3 to M7.6, M7.7 to M7.9, M7.10 final gate.
- **NOT_RUN:** UI smoke, exports, validation soak (all M7.10).

## Known-Defect & Observation Register (for M7)

1. **`rite_weaver` calling win-rate trails peers (`10/24` in `m6_final_validation`; `penitent/rite_weaver` and `revenant/rite_weaver` `0/3`, plus `veilkin/ophite_binder` `0/3`):** Review `rite_weaver` durability/early Resonance economy and active talent usage (`Rite Cantor` lacks early physical mitigation compared to `Bastion Warden` / `Seam Alchemist`).
2. **`d2 The Vault Enumerator` early mortality spike (`11` of `48` total deaths in `m6_final_validation`):** Evaluate Depth 2 spine boss stat/accuracy/telegraph tuning relative to level 2–3 builds.
3. **Bot coverage scope (`branch_visits=0`, `avg_threads_settled=0.00` in `soak.gd`):** `AutoPlayer` paths directly to main-spine `down_pos`/`exit_pos`, so branch floors, alt-routes, and active thread goal chasing are verified by targeted unit tests (`test_atlas`, `test_threads`, `test_reachability`) rather than end-to-end soak traversal.

## Setup

1. Install Godot **4.7.2** (standard build, not .NET).
2. Make it reachable as `$GODOT`, as `godot` on `PATH`, or as a `./.tools/godot` symlink (gitignored).
3. Run `tools/verify.sh` (or `tools/test.sh`); it must exit 0 before you change anything.
4. Android physical-device install (once USB debugging is enabled and `adb devices` shows your device): `adb install -r build/android/abyssal-sovereign-debug.apk`.

## Where things are

- `ARCHITECTURE.md`: layers, determinism, saves (`SAVE_VERSION := 11`), decisions D1–D8.
- `DESIGN.md`: rules, numbers, balance tables (`m6_final_validation` recorded).
- `ROADMAP.md`: Milestone summary and M7 next work.
- `docs/LORE.md`: every lore element tagged Canon / Canon-derived / Interpretation / Proposed, plus excluded material.
- `docs/WORLD_MANIFEST.md` & `content/lore/world_manifest.json`: portable setting manifest (`schema_version: 1`).
- `docs/CONTENT_SCHEMA.md`: the JSON content format enforced by `tests/test_content.gd`.

## Next assignment: Milestone 7 — Balance & Refinement (Not Started)

- Address the M6.10 Known-Defect & Observation Register (`rite_weaver` durability, `The Vault Enumerator` Depth 2 spike, optional branch/thread `AutoPlayer` heuristics if desired for deeper soak coverage).
- Conduct human playtest review across all 8×8 builds, desktop (`1280×720`) and phone (`2340×1080`) layouts, physical Android device install (`adb`), Windows & Web smoke verification, and release-keystore signing when ready.

## Owner decisions still open

- Release Android keystore creation (owner creates outside the repo).
- Formal canon promotion review for `Proposed` M6 entities (PR #300 locations/people/institutions/threads remain `Proposed`).

## Do not

- Modify FALSE LIGHT, Sovereign-Ops or any other repository. FALSE LIGHT documents are read-only sources.
- Push to a new branch, merge, publish or release without the owner's explicit authorization for that action.
- Add credentials, keystores, personal or biographical information, or persona and voice documents.
- Settle what the lore sources leave ambiguous, or tune balance against the held-out salt.
- Report a build, test or device result that did not run.
