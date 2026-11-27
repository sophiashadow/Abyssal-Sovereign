# Milestone 8 — The Incarnation Pass Report

**Status:** Complete locally on `main` (M8.0–M8.10; commits `aef17e4`..`26e7bc6` + M8.10 closure). **No human playtest has been run yet (`docs/PLAYTEST.md`)**, and physical Android / Windows / Web runtimes remain `NOT_RUN` (awaiting owner testing and release authorization).

**Baseline preserved:** M7 reference checkpoint `c6379ab` (8 origins, 8 callings, 104 talents across 24 trees, 28 floors across Seven Spheres, 76 monsters + 15 bosses = 86 monster entries, 165 base items, 46 affixes, 12 sets, 26 artifacts, 16 relics, 18 NPCs, 8 institutions, 24 threads, 4 descent profiles, `World.SAVE_VERSION := 12`, backward-compatible v1–v12 save migrations).

---

## 1. Submilestone Summary (M8.0–M8.10)

| Submilestone | Commit | Key Deliverables |
|---|---|---|
| M8.0 Foundation & Refinement | `aef17e4` | `docs/M8_SPEC.md`, fixed `tests/policy_player.gd` loop/branch/pinned stalls + added Relic Work automation (`baseline` unchanged), pure-observer Sphere identity & relic telemetry (`src/sim/telemetry.gd`, `src/sim/world.gd`, `tools/m7_report.gd`), `tests/test_m8_telemetry.gd` |
| M8.1 Visual Codex | `d6492d5` | `docs/ART_DIRECTION.md` (Gnostic/occult-medieval codex, 8-color palette, non-color signifiers, Deuteranopia/Protanopia/Tritanopia/High-Contrast transforms, 32×32 tiles / 16×16 icons / 64×64 emblems, spacing, lighting, provenance, Ossuary Warrens slice) |
| M8.2 Dual Rendering Architecture | `c312bea` | `src/ui/palette.gd`, `src/ui/game_settings.gd`, `src/ui/asset_registry.gd` (`AssetRegistry`), `tools/gen_sprites.py` vertical slice, dual `"tiles"`/`"glyph"` `MapView` (`src/ui/map_view.gd`) with `TEXTURE_FILTER_NEAREST`, integer scale, zoom, FOV falloff, non-color signifiers, graceful fallback, `tests/test_m8_renderer.gd` |
| M8.3 Seven Spheres Incarnate | `dcde97b` | All 7 environmental 32×32 atlases (`assets/tiles/sphere_1_moon.png`..`sphere_7_saturn.png`) + regional lighting modulation across all 28 floors |
| M8.4 Material World & Assets | `c943742` | 13 PNG atlases (`avatars.png`, `monsters.png`, `npcs.png`, `items.png`, `icons.png`, `emblems.png`, plus 7 Sphere tilesets), 100% content registry (`content/presentation/asset_registry.json`), full provenance (`content/presentation/asset_provenance.json`), `docs/ASSET_REGISTRY.md`, `tests/test_m8_assets.gd` |
| M8.5 Sovereign Interface | `820a3a7` | Responsive landscape & `720x1280` portrait HUD, Title crest, live layered Character Creation avatar preview, progressive bars + Sphere emblem, `Tiles/Glyph` & `Z-/Z+` controls, Inventory comparison icons, Institutional emblems + two-pole bars + NPC sprites in People, Sphere/Ending emblems, `left_handed` + safe-area handling (`src/ui/main.gd`) |
| M8.6 Motion, Impact & Feedback | `4584b4d` | Bounded non-serialized `World.events`, `src/ui/vfx_layer.gd` (`VfxLayer` with isolated `_cosmetic_rng`), tile glide, hit/ranged/trap/status/telegraph/death feedback, motion & intensity controls in `GameSettings`, `tests/test_m8_vfx.gd` |
| M8.7 Sound of Terra Tenebrae | `24dbfee` | `tools/gen_audio.py`, 24 deterministic dark SFX (`assets/audio/sfx/*.ogg`), 7 seamless Sphere ambience loops (`assets/audio/ambience/*.ogg`), `src/ui/audio_manager.gd` (`AudioManager`, 6 buses: `Master`, `Music`, `Ambience`, `Combat`, `Interface`, `Narrative`), isolated pitch RNG, pause/focus muting, per-bus volume controls |
| M8.8 Liturgical Soundtrack | `3f3c8a9` | `content/presentation/soundtrack_manifest.json` (all 16 contexts tagged `placeholder_liturgical_temp` for zero-code drop-in VENEFICA LUX stem swap), 16 synthesized placeholder stems (`assets/audio/music/*.ogg`), dual-deck crossfader in `AudioManager`, contextual switching in `Main`, `tests/test_m8_audio.gd` |
| M8.9 Narrative & Accessibility | `26e7bc6` | `content/presentation/narrative_frames.json` (`localization_ready: true`, `loc_key` keys, strict Canon-tag fidelity), `src/ui/narrative_frames.gd`, non-blocking dismissible Opening Descent / Sphere Transition / Boss Sighting banners, Gate & Mask framing, `Narrative framing` toggle, `tests/test_m8_narrative.gd` |
| M8.10 Beta Gate & Packaging | HEAD | Fixed top-banner wrapping (`docs/screenshots/m8`), `Actor` boss/unique tag checks & `AudioManager` tree guards, `export_presets.cfg` `docs/*` exclusion, `tools/m8_perf_bench.gd`, `tools/m8_smoke.gd`, 3-viewport screenshots, full test suite, fresh M8 dev soak, 4-target exports & APK/binary audit |

---

## 2. Automated Verification & Presentation Mode Matrix

- **Full test suite (`./tools/test.sh`):** `210` tests, `210` passed, `0` failed, `4,918` checks (`214.4s`). Includes simulation determinism, save v1–v12 migration & round-trip exactness, 100% reachability, content schema, renderer parity, full asset/provenance coverage, VFX isolation, 6-bus audio/manifest coverage, and narrative framing schema.
- **Presentation & accessibility mode matrix (`tools/m8_smoke.gd`):** `4` combinations tested end-to-end (`tiles_std`, `glyph_hc`, `tiles_deutan_reduced_silent`, `glyph_tritan_reduced_silent`), `0` engine errors, identical post-turn simulation RNG state (`-4367008355839543814`).
- **Automated UI smoke & screenshots (`tools/ui_smoke.gd`):** `39` steps, `0` failures at:
  - `1280x720` (Desktop): [docs/screenshots/m8/desktop/](screenshots/m8/desktop/)
  - `2340x1080` (Mobile landscape): [docs/screenshots/m8/mobile_landscape/](screenshots/m8/mobile_landscape/)
  - `720x1280` (Mobile portrait): [docs/screenshots/m8/mobile_portrait/](screenshots/m8/mobile_portrait/)

---

## 3. Performance, Memory & Footprint Benchmarks (`tools/m8_perf_bench.gd`)

Measured on development host via `./.tools/godot --headless --path . --script res://tools/m8_perf_bench.gd`:

| Metric | Measured Value |
|---|---|
| Cold `ContentDB.load_default()` | `34.10 ms` |
| Presentation atlases + `AssetRegistry` + `NarrativeFrames` load | `6.87 ms` |
| Simulation turn latency (`200` `AutoPlayer` turns) | Mean `2.171 ms/turn`, p95 `8.687 ms/turn` |
| Full-floor draw-prep cost (`100` full-grid passes) | Glyph: `142.46 ms` total; Tile lookup: `1587.41 ms` total |
| Save/load round-trip (`world.to_dict` / `from_dict`) | `66,743` bytes JSON; save `3.70 ms`, load `6.48 ms` (`valid_reload=true`) |
| Static memory usage | `37.74 MB` current, `76.71 MB` peak |
| On-disk `assets/` directory size (`du -sh assets`) | `816 KB` (13 PNG atlases + 47 OGG assets) |

---

## 4. M8 Dev Soak & Sphere Identity Telemetry (`m8_final_check`)

Ran `tools/m7_soak.gd -- --set=dev --salt=m8_final_check --seeds=1 --policies=baseline,explorer,narrative,specialist --species=human,veilkin --classes=occultist,rite_weaver,fallen_knight,assassin` (`32` runs total; M7 ledger salt `m7_final_validation` untouched):

| Policy | Runs (`n`) | Wins | Deaths | Unfinished (Cap) | Mean Depth | Mean Level | Mean Turns |
|---|---:|---:|---:|---:|---:|---:|---:|
| `baseline` | 8 | 6 (`75.0%`) | 1 (`d4 Fleet gilded idol`) | 1 (`playing`, capped) | 6.13 | 12.8 | 1097 |
| `explorer` | 8 | 8 (`100.0%`) | 0 | 0 | 7.00 | 16.2 | 5886 |
| `narrative` | 8 | 8 (`100.0%`) | 0 | 0 | 7.00 | 16.2 | 4213 |
| `specialist` | 8 | 8 (`100.0%`) | 0 | 0 | 7.00 | 14.1 | 819 |

- **Content reachability during soak:** `86/86` monsters killed, `28/28` floors visited, `19/24` threads accepted.
- **Relic telemetry (`m8_final_check`):** `229` Relic Work actions (`penitents_scourge` 97, `almoners_purse` 40, `ophite_key` 33, `ward_keepers_lamp` 31, `cantors_fork` 24, `confessors_glass` 4) and `32` Transmutes (`ophite_key` 15, `confessors_glass` 6, `ward_keepers_lamp` 3, etc.).
- **Sphere identity telemetry (`d1:Moon`–`d7:Saturn`):** Captured per-Sphere turn counts (`10,828`–`15,520`), elemental/physical/void/radiant damage profiles (e.g., `Sun` radiant peak `432`, `Mars` fire `341` + `sundered`/`degradation`, `Jupiter` `hexed` `45` + `sundered` `22`, `Saturn` cold `256` + void `240`), actions, and status frequencies cleanly in `test-results/m8_final_check_summary.md`.

---

## 5. Asset Provenance & Rights Hygiene

- Every sprite atlas (13), SFX file (24), Sphere ambient loop (7), and liturgical music stem (16) is deterministically generated in-repo by `tools/gen_sprites.py` and `tools/gen_audio.py` and recorded in `content/presentation/asset_provenance.json` (`asset_id`, `path`, `source`, `author_or_method`, `license_status`, `approval_status`, `associated_entities`, `modification_history`).
- All visual/SFX/ambient assets carry `approval_status: "provisional_m8_asset"` (`license_status: "project-original-cc0-equivalent"`); all 16 liturgical music stems carry `approval_status: "placeholder_liturgical_temp"` (`license_status: "project-original-placeholder"`) and can be replaced individually by external authorized VENEFICA LUX recordings via `content/presentation/soundtrack_manifest.json` without touching engine code.
- No files were imported from `/home/lux/Music/VENEFICA STUDIO`, `/home/lux/Pics`, FALSE LIGHT, or Sovereign-Ops.

---

## 6. Cross-Platform Export & Honest Verification Status

Exported cleanly via `./tools/export.sh all` with `exclude_filter="build/*,docs/*,test-results/*,tests/*,tools/*"` and `include_filter="*.json"`:

| Target | Build Path & Size | Export | Verification Performed | Runtime Status |
|---|---|---|---|---|
| Linux (`x86_64`) | `build/linux` (`72M`) | Pass | Launched `--headless --quit --audio-driver Dummy` (exit 0) + windowed `ui_smoke.gd` | Verified locally |
| Windows Desktop | `build/windows` (`106M`) | Pass | Binary built via Godot export template | `NOT_RUN` (Linux host; no Wine/Windows runner) |
| Web (HTML5/WASM) | `build/web` (`40M`) | Pass | Package built via Godot export template | `NOT_RUN` (browser & IndexedDB persistence unverified) |
| Android Debug APK | `build/android` (`57M`) | Pass | `unzip -l` confirmed 13 atlases, 47 OGGs, 4 presentation JSONs, 0 `docs/*`; `apksigner verify --verbose` verified v2 + v3 signatures (1 signer) | `NOT_RUN` on physical hardware (`adb devices` empty) |

---

## 7. Remaining Owner Decisions & M9 Prerequisites

1. **Human playtest (`docs/PLAYTEST.md`):** No human playtest has been run yet (`status: no human playtest has been run`). Human rounds across difficulty profiles, mobile portrait/landscape readability, tile scale, and liturgical presentation balance remain outstanding.
2. **Physical platform & release signing verification:** Windows runtime, Web browser/IndexedDB save persistence, physical Android touch/audio/backgrounding hardware tests, and owner-held release keystore signing.
3. **Open M7/M8 design & canon decisions:** Final difficulty profile naming/tuning, whether Veil-Touched's residual bot-play win-rate gap is intentional, M6 `Proposed` lore Canon promotion review, and VENEFICA LUX external soundtrack stem authorization/swap.
4. **Repository state:** All changes committed locally on `main`; awaiting owner authorization before any push, PR, merge, release, or M9 start.
