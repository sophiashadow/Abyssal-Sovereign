# Milestone 9 Verification & Release Candidate Report (`v1.0.0-rc.1`)

**Milestone:** M9 — The Ascension Pass (`v1.0.0-rc.1`)  
**Starting Checkpoint:** `15a98d0` (M8 completion)  
**Target Branch:** `main` (local commits only — nothing pushed, tagged, merged, or released)  
**Save Schema Compatibility:** `World.SAVE_VERSION := 12` (`v1`–`v12` automatic migrations intact)

---

## 1. Submilestone Summary & Commit Ledger

| Submilestone | Commit | Scope Delivered |
|---|---|---|
| **M9.0 Production Audit** | `5fe196a` | Verified M8 baseline (`210/210, 4918 checks`); audited screenshots, APK contents, manifests, and benchmarks; created `docs/M9_SPEC.md` & `docs/M9_DEFECT_REGISTER.md` |
| **M9.1 Artistic Mastery** | `aa13381` | Upgraded 32×32 Sphere tilesets, humanoid origin/calling silhouettes, 15 bespoke boss seals, 18 institution NPCs, 16 relics, 26 artifacts, 24 unique woodcut emblems, 7 launcher/adaptive icons (`provisional_m9_asset`), `AssetRegistry` region/tile caching, soft radial lantern lighting, 4 comparison sheets, and `docs/ASSET_BACKLOG.md` |
| **M9.2 Mobile-First UX** | `af556fd` | Fixed Atlas/People single-column text wrapping (`P1-1`), built zero-scroll Portrait touch dock + collapsible `Stats ▾` drawer (`P1-2`), sticky `[×]` scrollable modals + full Back routing (`P1-3`), frame-0 title screenshot fix (`P1-5`), and verified `1280x720`, `2340x1080`, `720x1280` viewports |
| **M9.3 Game Feel & UX Polish** | `6d2e125` | Added `World` melee `actor_id` events + `VfxLayer` lunge animations & text shadow, contextual button highlights (`Get`/`Use`/`Stairs`/`Build`/`Rest`/`Mask`), Aim/Look/Auto touch mode bars, seamless NPC counsel & multi-buy merchant modal, Forsake-contract confirmation, `[?]/[✦]/[☠]/[▲]/[▼]` inventory tags, and `tests/test_m9_polish.gd` |
| **M9.4 Narrative & Atmosphere** | `c51c588` | Added `APP_VERSION := "1.0.0-rc.1"` Title footer, fixed Boss Sighting banners (`description` + `boss_seal`, `P1-6`), cleaned Exile/origin/Sphere 1 copy, grouped starting gear stacks, fixed End screen pluralization/formatting, and created `docs/OWNER_CANON_LEDGER.md` |
| **M9.5 Audio Mastering** | `f9e3c66` | Regenerated all 47 audio assets at `44.1 kHz` with RMS normalization (`1.1 MB` total; 16 music stems kept `placeholder_liturgical_temp`), added dual-deck Sphere ambience crossfader, `45 ms` SFX cooldown + micro-jitter, fixed `set_paused()` unmute-at-zero bug, and wired all 24 SFX cues |
| **M9.6 Final Gameplay Integrity** | `47989fa` | Ran 4×32 dev profile sweeps (`m9dev_prof_*`), 256-run dev matrix (`m9dev_matrix`), and 256-run held-out `m9_rc1_validation` soak (`v9_rc1_exile`); updated `balance/CHANGES.md` & `DESIGN.md` with zero unvalidated stat tuning |
| **M9.7 Human Playtest Gate** | `099ab5d` | Transformed `docs/PLAYTEST.md` into an actionable external playtest package (install guides, controls, tactical primer, known limitations, bug template, accessibility matrix, 9-axis questionnaire; preserves `Status: No human playtest has been run.`) |
| **M9.8 Distribution Architecture** | `c2057df` | Excluded dev/balance/lore/docs/tests/tools from all 4 export presets (`P0-1`), configured `1.0.0-rc.1` version + launcher/PWA/Android adaptive icons, created `tools/package_rc.sh` & `docs/INSTALL.md`, updated `tools/verify.sh` |
| **M9.9 Product & Release Kit** | `30271ca` | Rewrote `README.md` (`v1.0.0-rc.1`), authored `docs/release/{PRODUCT_KIT,RELEASE_NOTES,PRIVACY,CREDITS_AND_LICENSES}.md`, closed `P2-5`, verified zero personal home path leaks |
| **M9.10 Release Candidate Gate** | *(this commit)* | Guarded Dummy audio driver playback (`src/ui/audio_manager.gd`) + Windows version keys (`export_presets.cfg`) eliminating all exit resource leaks/warnings; ran final post-edit 214-test gate, benchmarks, 3-viewport screenshots, package rebuild, Linux launch smoke, `docs/M9_REPORT.md`, `docs/RELEASE_CHECKLIST.md`, `ROADMAP.md` |

---

## 2. Defect Register Closure (`docs/M9_DEFECT_REGISTER.md`)

- **P0-1 (Export Leak):** **Resolved** — all 4 presets exclude `balance/*,build/*,docs/*,release/*,test-results/*,tests/*,tools/*,content/lore/*,*.md`; APK and portable archive inspections pass zero-leak checks.
- **P1-1 through P1-6:** **All 6 P1 Defects Resolved** (Atlas/People wrapping, mobile Portrait touch dock + `Stats ▾` drawer, sticky `[×]` modals + Back routing, `AssetRegistry` 6.7× cache speedup, frame-0 title screenshot + RC1 footer, Boss Sighting description + `boss_seal` emblem).
- **P2-1 through P2-5:** **All 5 P2 Defects Resolved** (art/lighting upgrade + backlog, tactical game-feel polish, narrative copy cleanup, 44.1 kHz RMS audio + crossfading + cooldowns + exit-leak cleanup, product/release packaging & docs).
- **P3-1 (External Human / Platform / Art / Music / Canon Gates):** **Explicitly Tracked** (Section 6 below & `docs/RELEASE_CHECKLIST.md`).

---

## 3. Performance Benchmarks (`tools/m8_perf_bench.gd`)

Measured on developer Linux workstation before (M8 `15a98d0`) and after M9 optimizations:

| Metric | M8 Baseline | M9.10 (`v1.0.0-rc.1`) | Change |
|---|---:|---:|---|
| `prep_100frames_tile_ms` | `1587.41 ms` | **`236.88 ms`** | **~6.7× faster** (`AssetRegistry` region/tile cache) |
| `prep_100frames_glyph_ms` | `142.46 ms` | `135.39 ms` | Maintained |
| `turn_mean_ms` (200 turns) | `~2.1 ms` | `2.161 ms` (`p95: 8.831 ms`) | Deterministic parity preserved |
| `content_load_ms` / `pres_load_ms` | — | `36.45 ms` / `8.68 ms` | Fast startup |
| `save_bytes` / `save_ms` / `load_ms` | `66743 B` | `66743 B` / `3.69 ms` / `6.18 ms` (`valid_reload=true`) | Exact `SAVE_VERSION := 12` parity |
| Static memory (current / peak) | — | `37.85 MB` / `77.16 MB` | Bounded footprint |

---

## 4. Gameplay Integrity & Validation Soaks (M9.6)

No gameplay formulas or balance tables were modified during M9; soaks verify M8.0 navigation/Relic-Work fixes and difficulty separation on `v1.0.0-rc.1`:

### Dev Profile Separation (`salt=m9dev_profiles`, 32 runs per profile)
- **Initiate:** `24/32` won (`75.0%`), `8` dead, `0` capped (`d2` deaths: `3`)
- **Exile:** `22/32` won (`68.8%`), `9` dead, `1` capped (`d1:1, d2:5, d3:3`)
- **Adversary:** `21/32` won (`65.6%`), `11` dead, `0` capped (`d1:1, d2:6`)
- **Sovereign:** `18/32` won (`56.2%`), `11` dead, `3` capped (`d1:3, d2:3`)

### Held-Out Validation (`salt=m9_rc1_validation`, Exile, 256 runs: 64 pairs × 4 policies)
Claimed once in `balance/validation_ledger.txt`; nothing tuned against these runs.
- **Totals:** **`219/256` won (`85.5%`)**, **`35` dead (`13.7%`)**, **`2` action-capped (`0.8%`)** (down from `91/512` capped in `m7_final_validation`; `0` capped across all `192` runs of `explorer`, `narrative`, and `specialist`).
- **By Policy:** `baseline 51/64 (79.7%, 11d, 2c)`, `explorer 54/64 (84.4%, 10d, 0c)`, `narrative 59/64 (92.2%, 5d, 0c)`, `specialist 55/64 (85.9%, 9d, 0c)`.
- **By Origin (`n=32`):** `ashborn 29/32`, `ironbound_ward 29/32`, `cambion 28/32`, `revenant 28/32`, `penitent 27/32`, `unrecorded 27/32`, `human 26/32`, `veilkin 25/32 (78.1%)`.
- **Coverage:** `86/86` monsters killed, `28/28` floors visited, `24/24` narrative threads accepted, all 4 Victory endings reached (`by_decree:76, unwritten:68, serpent:47, return:28`), `1,534` Relic Work uses + `246` Transmutations.

---

## 5. Final Verification Suite & Release Package Inventory

Executed after the final code edit (`src/ui/audio_manager.gd`):
- **`./tools/test.sh`:** **`RESULT: 214 tests, 214 passed, 0 failed, 4947 checks, 195.2s`** (0 failures, 0 engine errors).
- **`tools/m8_smoke.gd`:** **`M8_MODE_SMOKE: 4 combinations passed, RNG invariant (-4367008355839543814)`**.
- **`tools/ui_smoke.gd` (3 viewports):** `1280x720` (`desktop`), `2340x1080` (`mobile_landscape`), and `720x1280` (`mobile_portrait`) all passed **`UI smoke: 39 steps, 0 failures`** with **0 errors, 0 warnings, and 0 ObjectDB/resource leaks at exit**; key RC1 PNG screenshots visually inspected.
- **Exported Linux Binary Launch:** `./build/linux/abyssal-sovereign.x86_64 --audio-driver Dummy --quit-after 30` exited `0` with **0 errors, 0 warnings, and 0 exit leaks**.

### Portable Packages (`build/release/SHA256SUMS.txt` verified OK)

| Artifact | Size | SHA-256 |
|---|---:|---|
| `abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` | `57M` | `d97ce2b0b7f95132539f0e8d1c84c1b17065bf59d1030bd967a8a524b93c134f` |
| `abyssal-sovereign-v1.0.0-rc.1-linux-x86_64.tar.gz` | `29M` | `20a141744c8cc63353afc562f5e6d7fd31c831c23b155cdc91a30e474986b9c5` |
| `abyssal-sovereign-v1.0.0-rc.1-web.zip` | `11M` | `a791d71432ae98e0e6836a150a5f4056e0b6e3e36dc7236ca2a3d5d12e128e01` |
| `abyssal-sovereign-v1.0.0-rc.1-windows-x86_64.zip` | `38M` | `561ad153de1fcec6efb67f103c9fcbf318c8d7548c4dae2ce13185c0dfe913d4` |

*(Note: Android APK was signed and verified during Godot export via `apksigner sign`; standalone `apksigner verify` on shell PATH requires `java` in default `PATH`, not installed in default `PATH` on this environment.)*

---

## 6. Unresolved External, Human & Owner Gates

The following items are **not automated-completable** and remain open before promoting beyond `v1.0.0-rc.1`:
1. **Human Playtesting (`docs/PLAYTEST.md`):** Zero human runs have occurred; needed to judge Difficulty profiles (Initiate–Sovereign), Depth 2 `The Vault Enumerator`, `occultist`/`ophite_binder` early frailty, tactile phone usability, and accessibility modes.
2. **External Platform Runtimes (`NOT_RUN`):** Physical Windows desktop execution, Web browser IndexedDB save persistence, and physical Android hardware install / notch safe-areas / touch gestures / background suspend resume.
3. **Release Keystore Signing:** Owner must generate/configure a non-repo Android release keystore outside git before public Android distribution (`docs/INSTALL.md`).
4. **Music & Art Upgrades:** Replace `16` `placeholder_liturgical_temp` music stems with owner-approved VENEFICA LUX recordings (`soundtrack_manifest.json`), and review commissioned art priorities (`docs/ASSET_BACKLOG.md`).
5. **Canon & Release Authorization:** Owner sign-off on `docs/OWNER_CANON_LEDGER.md` and explicit authorization before git push, tagging `v1.0.0-rc.1`, or public release (`docs/RELEASE_CHECKLIST.md`).
