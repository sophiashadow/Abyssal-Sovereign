# Handoff: ABYSSAL SOVEREIGN

For the next agent: Antigravity, Gemini, Codex, Claude or any other. Read `AGENTS.md` first; its rules win over this file. Update this file at every stop.

## State as of 2026-11-27 (M8 Incarnation Pass complete locally on `main`; awaiting owner review & human playtest)

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
- **M7 Refinement Pass (M7.1–M7.10 COMPLETE, save v12):** merged in PR #1; details and evidence in the M7 section below and `docs/M7_REPORT.md`. The "Last verified" block that follows is the M6.10 record.
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

## M7 Refinement Pass: complete and merged (PR #1, merge commit `361a40f`, 2026-11-27)

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
- **M7.2 to M7.6 (audited, bot play on dev seeds; every row with evidence is in `balance/CHANGES.md`):**
  - One stat change: Veil-Touched base HP 3 to 5 and radiant resist -25 to -10; Unrecorded base HP 3 to 4. Same-seed A/B (o0 to o1): Veil-Touched 56% to 61%, Unrecorded 66% to 68%, controls identical. Veil-Touched is still the weakest origin; whether a residual gap is intended is a human-playtest question.
  - No change, with reasons: the 14 unused talents (all work, `tests/test_m7_talents.gd`); d2 Vault Enumerator (deaths follow arrival level: 16% at level 1, 8% at level 2, 0 of 563 at level 3 or more); Binder and Cantor (kit-dependent: 50% and 36% generic, 81% and 100% with a specialist); DoT and bursts (no unavoidable burst in 3,036 runs); healing and relic economy (`tests/test_m7_relics.gd`); Sphere pacing (even, narrative backtracking is a navigation problem).
  - Bot fix: bots crossed every Sphere Gate By Name, which the contract The Taken Name forbids. They now use the Serpent's Key under that contract (c1: broken 12 to 0, fulfilled 2 to 11).
  - Not instrumented, left to human playtest: per-Sphere mechanical identity; ending preference.
  - `tools/test.sh` after this batch: 146 tests, 146 passed, 4023 checks, 107.9s (commit `c4cb219`, pushed).
- **M7.7 Player agency and QoL: implemented, tested locally (commit `ca418cd`, pushed).** `src/sim/assist.gd` (Node-free): safe auto-explore, interruptible rest, travel between visited floors, quest/Atlas navigation, advisory descent warnings, equipment compare, inventory sort/filter/search, log filters, enemy inspection. Automation stops for hostiles, dangerous statuses, low or falling HP, hazards and revealed traps; it never uses features, signs contracts or crosses a new Sphere Gate. UI: Auto button (key O), configurable shortcuts, log filter, compare tooltips, confirmations for Transmute, dropping relics/rare gear and abandoning a thread, Atlas and Threads travel buttons, status details, options in Settings. The old Threads (J) and Codex (K) keys were shadowed by movement keys and never worked; defaults are now T and Z. `tools/test.sh`: 173 tests, 173 passed, 4187 checks (new: `test_m7_assist` 24, `test_m7_settings` 3). UI smoke: 39 steps, 0 failures. Limits: auto-explore cannot see hidden traps; the recommended-level hint is evidence-based for depth 2 only; touch layout and pacing feel need a human on a device.
- **M7.8 Profiles and onboarding (commits `d5c13cf`, `ba2438c`).** Four descent profiles in `content/core/difficulty.json` (names provisional), `src/sim/difficulty.gd`, optional hints in `src/sim/hints.gd`, `SAVE_VERSION` 12 (v11 loads as Exile; unknown ids refused), profile shown on the create screen, pause overlay and run history. Same-seed bot A/B: Initiate 81%, Exile 75%, Adversary 70%, Sovereign 67%; adjacent profiles are within noise.
- **M7.9 `docs/PLAYTEST.md` (`d9f4288`).** Coverage matrix, observation prompts, severity scale, local report template. No human playtest has run.
- **M7.10 Final gate (2026-11-27).**
  - Local, at code commit `d5c13cf` (later commits touch only docs, balance and the ledger): `tools/test.sh` 190 tests, 190 passed, 4323 checks, 110.6 s; UI smoke 39 steps, 0 failures.
  - Validation soak, fresh salt `m7_final_validation` (spent), Exile, 512 runs, four bot policies: 369 won (72.1%), 52 died, 91 hit the action cap. Not comparable with M6.10's 75%.
  - Exports (Godot 4.7.2 templates, SHA-512 checked): Linux built and launched under xvfb (exit 0, gameplay not driven); Windows built, runtime NOT_RUN; Web built, persistence NOT_RUN; Android debug APK built, `apksigner verify` passes, device install NOT_RUN.
  - Report: `docs/M7_REPORT.md` (datasets, reproduction commands, known defects, playtest requirements, structured M8 recommendations).
- **Merged:** PR #1 into `main` on owner instruction (2026-11-27). Nothing released or published. M8 not started.
- **NOT_RUN:** human playtest, Windows runtime, Web persistence, physical Android install, release-signed APK, CI (none exists).

## Known-Defect & Observation Register (M6.10 items, status after M7)

1. **`rite_weaver` calling win-rate trails peers (`10/24` in `m6_final_validation`; `penitent/rite_weaver` and `revenant/rite_weaver` `0/3`, plus `veilkin/ophite_binder` `0/3`):** Review `rite_weaver` durability/early Resonance economy and active talent usage (`Rite Cantor` lacks early physical mitigation compared to `Bastion Warden` / `Seam Alchemist`).
2. **`d2 The Vault Enumerator` early mortality spike (`11` of `48` total deaths in `m6_final_validation`):** Evaluate Depth 2 spine boss stat/accuracy/telegraph tuning relative to level 2–3 builds.
3. **Bot coverage scope (`branch_visits=0`, `avg_threads_settled=0.00` in `soak.gd`):** `AutoPlayer` paths directly to main-spine `down_pos`/`exit_pos`, so branch floors, alt-routes, and active thread goal chasing are verified by targeted unit tests (`test_atlas`, `test_threads`, `test_reachability`) rather than end-to-end soak traversal.

**Status after M7 (bot play; see `docs/M7_REPORT.md`):** (1) Rite Cantor weakness was mostly a bot-competence gap (specialist wins 16/16 in b2); no stat change. (2) Vault Enumerator deaths follow arrival level; answered with an advisory warning, no nerf; still the largest death cluster on the validation salt (19 of 52 deaths at depth 2). (3) Branch and thread coverage remains test-based; Work-relic bot behaviour is still missing.

## Setup

1. Install Godot **4.7.2** (standard build, not .NET).
2. Make it reachable as `$GODOT`, as `godot` on `PATH`, or as a `./.tools/godot` symlink (gitignored).
3. Run `tools/verify.sh` (or `tools/test.sh`); it must exit 0 before you change anything.
4. Android physical-device install (once USB debugging is enabled and `adb devices` shows your device): `adb install -r build/android/abyssal-sovereign-debug.apk`.

## Where things are

- `ARCHITECTURE.md`: layers, determinism, saves (`SAVE_VERSION := 12`), decisions D1–D8.
- `DESIGN.md`: rules, numbers, balance tables (`m6_final_validation` recorded).
- `ROADMAP.md`: Milestone summary and M7 next work.
- `docs/LORE.md`: every lore element tagged Canon / Canon-derived / Interpretation / Proposed, plus excluded material.
- `docs/WORLD_MANIFEST.md` & `content/lore/world_manifest.json`: portable setting manifest (`schema_version: 1`).
- `docs/CONTENT_SCHEMA.md`: the JSON content format enforced by `tests/test_content.gd`.

## Next assignment: Milestone 8 — The Incarnation Pass (In Progress)

Spec: `docs/M8_SPEC.md`.

- **M8.0 Foundation & Outstanding Refinement (complete, verified locally):**
  - Diagnosed and resolved the M7 unfinished bot runs in `tests/policy_player.gd` (fixed `narrative` stair ping-pong in `_may_descend()`/`_has_pending_thread_travel()`, `explorer` branch exit pathfinding in `_explore_goal()`/`_branch_exit_pos()`, `pinned` non-combat stall in `_walk_to()`, 16-turn FOV-corner oscillation loop-breaker, and mask-switching cooldown; added Relic Work behavior for `explorer`, `narrative`, and `specialist` while leaving `baseline`/`AutoPlayer` unchanged).
  - Post-fix dev check (`m8_diag_post`, 12 runs across `explorer`, `narrative`, `specialist` on `human/veilkin × occultist/assassin`): 0 unfinished runs (`explorer` 4/4 mean 5135 turns, `narrative` 4/4 mean 4002 turns, `specialist` 3/4 mean 514 turns), 82 Relic Work calls recorded.
  - Added pure-observer Sphere mechanical identity (`sphere_turns`, `sphere_damage_taken`, `sphere_actions`, `sphere_statuses`) and relic usage (`relic_work`, `relic_transmute`) telemetry to `src/sim/telemetry.gd`, `src/sim/world.gd`, and `tools/m7_report.gd`.
  - Added `tests/test_m8_telemetry.gd` (3 tests, 14 checks).
- **M8.1 The Visual Codex (complete):**
  - Authored `docs/ART_DIRECTION.md`: Gnostic/occult-medieval visual identity, 8-color foundational palette (`VOID`, `IRON`, `PORPHYRY`, `GOLD`, `FALSE_SUN`, `IVORY`, `LUX`, `SILVER`, `BLOOD`), functional color meanings + mandatory non-color signifiers, Deuteranopia/Protanopia/Tritanopia/High-Contrast modes, 32×32 tile grid & 16×16/64×64 specs, 8px spacing / 48px touch targets, lighting/FOV & 60–180ms animation rules, asset naming/provenance schema, and the Ossuary Warrens vertical-slice treatment.
- **M8.2 The Dual Rendering Architecture (complete, verified locally):**
  - Extended `src/ui/palette.gd` (M8 palette constants, Sphere accents, `color_for_mode` R/G & B/Y colorblind + high-contrast transforms) and `src/ui/game_settings.gd` (`render_mode`, `TILE_SIZES`, `integer_scale`, `camera_zoom`, `decorative_lighting`, `color_mode`, `high_contrast`, `left_handed`).
  - Added `src/ui/asset_registry.gd` (`AssetRegistry`) loading `content/presentation/asset_registry.json` and `asset_provenance.json` with safe `null` fallback.
  - Created `tools/gen_sprites.py` generating the Ossuary Warrens (Moon, Sphere 1) vertical-slice 32x32 tileset and core entity/item sprites (`assets/tiles/sphere_1_moon.png`, `assets/sprites/{avatars,monsters,npcs,items}.png`).
  - Upgraded `src/ui/map_view.gd` to support both `"tiles"` and `"glyph"` modes, `TEXTURE_FILTER_NEAREST`, integer scaling, mouse-wheel/setting camera zoom, FOV falloff, remembered dimming, optional decorative lighting, non-color signifiers (hostile brackets, NPC diamond, elite crown, boss aureole, HP micro-bar, telegraph icon, hazard patterns), and per-cell glyph fallback.
  - Verified `test_m8_renderer` (3/3, 13 checks), `test_m7_settings` (3/3, 80 checks), and `tools/ui_smoke.gd` at `1280x720` (`39` steps, `0` failures).
- **M8.3 The Seven Spheres Incarnate (complete, verified locally):**
  - Expanded `tools/gen_sprites.py` to generate distinct 32x32 environmental tile & feature atlases for all Seven Spheres (`assets/tiles/sphere_1_moon.png` .. `sphere_7_saturn.png`) covering Ossuary Warrens, Tithe Vaults, Gilded Choir, False Solar Court, Iron Scriptorium, Chamber of Decrees, and Sealed Stair, plus regional modulation in `MapView`.
  - Verified all 7 Sphere atlases (`test_m8_renderer` 4/4, 182 checks; `tools/ui_smoke.gd` 39 steps, 0 failures).
- **M8.4 Inhabitants, Relics & the Material World (complete, verified locally):**
  - Expanded `tools/gen_sprites.py` and `AssetRegistry` to generate and map 13 atlases with 100% content coverage: 8 Origins + 8 Callings + 5 Masks (`assets/sprites/avatars.png`), 86 monsters + 15 bespoke bosses (`assets/sprites/monsters.png`), 18 distinct NPCs (`assets/sprites/npcs.png`), 165 items + 16 bespoke relics + 26 unique artifact treatments (`assets/sprites/items.png`), 16x16 icons for 51 statuses / 24 talent trees / 8 elite mutations / Eight Chains / 4 contracts (`assets/sprites/icons.png`), and 64x64 woodcut emblems for Title / 7 Spheres / 8 Institutions / Endings / Named Losses (`assets/portraits/emblems.png`).
  - Created `docs/ASSET_REGISTRY.md` and `tests/test_m8_assets.gd`; all asset rects and provenance metadata (`content/presentation/asset_provenance.json`) validated (`test_m8_assets` 3/3, 65 checks; `test_m8_renderer` 4/4, 182 checks).
- **M8.5 The Sovereign Interface (complete, verified locally):**
  - Refined `src/ui/main.gd` with occult-medieval theme borders & high-contrast support, Title crest emblem, live layered Character Creation avatar preview, progressive-disclosure HP/Resource/Subjugation progress bars + Sphere emblem + quick `Tiles/Glyph` & `Z-/Z+` controls, responsive landscape (`1280x720`, `2340x1080`) and portrait (`720x1280`) layouts with safe-area padding and left/right-handed touch option, item sprites in Inventory & Item Inspection, institution emblems + two-pole bars + NPC sprites in People, Sphere emblems in Atlas, and Ending/Named Loss emblems on End screen.
  - Verified `tools/ui_smoke.gd` (`39` steps, `0` failures at `1280x720`, `2340x1080`, and `720x1280`) and full `./tools/test.sh` (`203` tests, `203` passed, `4623` checks).
- **M8.6 Motion, Impact & Feedback (complete, verified locally):**
  - Added bounded, non-serialized, non-RNG `World.events` ring buffer (`src/sim/world.gd`) emitting movement, melee, ranged, damage, status, telegraph, trap, door, relic, mask, subjugation, death, and victory events.
  - Added `src/ui/vfx_layer.gd` (`VfxLayer`) integrated into `MapView` and `Main` with configurable `anim_speed`, `instant_actions`, `reduced_motion`, `screen_shake`, `particles`, `floating_text`, and `flash_intensity` in `GameSettings`.
  - Added `tests/test_m8_vfx.gd` and verified `test_m8_vfx`, `test_save`, `test_m8_renderer`, and `tools/ui_smoke.gd`.
- **M8.7 The Sound of Terra Tenebrae (complete, verified locally):**
  - Created `tools/gen_audio.py` generating 24 deterministic dark occult SFX (`assets/audio/sfx/*.ogg`) and 7 sample-exact seamless Sphere ambience loops (`assets/audio/ambience/sphere_1_moon.ogg`..`sphere_7_saturn.ogg`) via numpy + ffmpeg (`libvorbis -q:a 1 -ar 22050`), with provenance entries merged into `content/presentation/asset_provenance.json`.
  - Extended `src/ui/game_settings.gd` with `[audio]` controls (`audio_enabled`, `vol_master`, `vol_music`, `vol_ambience`, `vol_combat`, `vol_interface`, `vol_narrative`).
  - Added `src/ui/audio_manager.gd` (`AudioManager`) configuring 6 `AudioServer` buses (`Master`, `Music`, `Ambience`, `Combat`, `Interface`, `Narrative`), isolated cosmetic RNG pitch variation, pooled SFX playback from `World.events` + UI triggers, seamless Sphere ambience transitions, and pause/focus muting, wired into `src/ui/main.gd`.
  - Verified `test_m7_settings`, `test_m8_assets`, and `tools/ui_smoke.gd` (`39` steps, `0` failures).
- **M8.8 The Liturgical Soundtrack (complete, verified locally):**
  - Created `content/presentation/soundtrack_manifest.json` documenting all 16 liturgical contexts (`main_title`, `character_creation`, 7 Sphere themes, `sanctuaries`, `boss_encounters`, 4 Victory endings, `death_named_losses`), all explicitly tagged `status: "placeholder_liturgical_temp"` and `license_status: "project-original-placeholder"` for drop-in VENEFICA LUX stem replacement.
  - Extended `tools/gen_audio.py` to synthesize 16 seamless placeholder liturgical organ/bell stems (`assets/audio/music/*.ogg`) and record provenance in `content/presentation/asset_provenance.json`.
  - Extended `src/ui/audio_manager.gd` with `play_music_context()` + dual-deck crossfading and wired contextual transitions into `src/ui/main.gd`.
  - Added `tests/test_m8_audio.gd` and verified `test_m8_audio`, `test_m8_assets`, and `tools/ui_smoke.gd`.
- **M8.9 Narrative Presentation & Accessibility (complete, verified locally):**
  - Created `content/presentation/narrative_frames.json` (`localization_ready: true`, `loc_key` keys for Opening Descent, all 7 Spheres, Boss Sightings, Gate Threshold, Contract Pact, and Mask Aspect, preserving Canon tagging without promoting `Proposed` lore) and `src/ui/narrative_frames.gd` (`NarrativeFrames`).
  - Added non-blocking, click/tap-dismissible, reduced-motion-safe Opening Descent, Sphere Transition, and Boss Sighting framing banners plus Gate/Mask atmospheric framing and the `Narrative framing: on/off` preference (`GameSettings.narrative_banners`) in `src/ui/main.gd`.
  - Added `tests/test_m8_narrative.gd` and verified `test_m8_narrative`, `test_m7_settings`, and `tools/ui_smoke.gd`.
- **M8.10 Performance, Portability & Internal Beta Gate (complete, verified locally; see `docs/M8_REPORT.md`):**
  - Fixed top-banner wrapping across landscape & portrait viewports (`src/ui/main.gd`), replaced `.is_boss` with `tags.has("boss") or unique` checks (`main.gd`, `audio_manager.gd`), added `is_inside_tree()` playback guards (`AudioManager`), and excluded `docs/*` in `export_presets.cfg` on all 4 presets.
  - Added & ran `tools/m8_perf_bench.gd` (`ContentDB` load `34.10 ms`, presentation `6.87 ms`, 200-turn mean `2.171 ms` / p95 `8.687 ms`, save `66,743` B in `3.70 ms` / load `6.48 ms`, peak static memory `76.71 MB`, `assets/` `816 KB`) and `tools/m8_smoke.gd` (`4` presentation/accessibility combinations, `0` errors, invariant RNG).
  - Captured verified screenshots (`docs/screenshots/m8/{desktop,mobile_landscape,mobile_portrait}/`) at `1280x720`, `2340x1080`, and `720x1280` (`tools/ui_smoke.gd`: `39` steps, `0` failures each).
  - Full test suite (`./tools/test.sh`): `210` tests, `210` passed, `0` failed, `4,918` checks (`214.4s`).
  - Fresh M8 dev soak (`m8_final_check`, 32 runs): `explorer 8/8`, `narrative 8/8`, `specialist 8/8` (`0` unfinished), `baseline 6/8` (`1` death, `1` action-capped), `86/86` monsters killed, `28/28` floors visited, `229` Relic Work + `32` Transmute events, complete 7-Sphere identity telemetry.
  - Cross-platform export (`./tools/export.sh all`): Linux (`72M`, headless launch verified exit `0`), Windows (`106M`, runtime `NOT_RUN`), Web (`40M`, runtime `NOT_RUN`), Android Debug APK (`57M`, `unzip -l` verified atlases/OGGs/JSONs present & `0` `docs/*`, `apksigner verify` v2+v3 valid; physical Android runtime `NOT_RUN` — `adb devices` empty).
- **Next assignment:** Owner review of M8 (`docs/M8_REPORT.md`), human playtest rounds (`docs/PLAYTEST.md`), physical Android/Windows/Web verification, VENEFICA LUX stem swap (`content/presentation/soundtrack_manifest.json`), and explicit authorization before pushing, merging, releasing, or starting M9.

## Owner decisions still open

- Profile names and parameters (provisional); whether Veil-Touched's residual bot-play gap is intended.
- Human playtest results (`docs/PLAYTEST.md`) and physical Android / Windows / Web runtime verification (`NOT_RUN`).
- Release Android keystore creation (owner creates outside the repo) and external VENEFICA LUX soundtrack authorization/swap.
- Formal canon promotion review for `Proposed` M6 entities (PR #300 locations/people/institutions/threads remain `Proposed`).

## Do not

- Modify FALSE LIGHT, Sovereign-Ops or any other repository. FALSE LIGHT documents are read-only sources.
- Push to a new branch, merge, publish or release without the owner's explicit authorization for that action.
- Add credentials, keystores, personal or biographical information, or persona and voice documents.
- Settle what the lore sources leave ambiguous, or tune balance against the held-out salt.
- Report a build, test or device result that did not run.
