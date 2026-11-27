# Milestone 8 Specification — The Incarnation Pass: Giving the Abyss Form

Reference checkpoint: M7 merged into `main` (PR #1 / commit `c6379ab`).

## Mission

Transform the mechanically refined M7 alpha into a visually coherent, atmospheric, accessible, and professionally presented traditional roguelike RPG grounded in the cosmology of Terra Tenebrae. M8 builds identity, immersion, and presentation quality strictly on top of the existing deterministic simulation without modifying core gameplay rules or save compatibility.

## Non-Negotiable Invariants

1. **Strict Separation of Simulation and Presentation:**
   - `src/core/`, `src/content/`, `src/gen/`, `src/sim/`, and `src/persistence/` must remain completely free of `Node`, `Input`, `Texture2D`, `AudioStream`, rendering, or frame-time dependencies.
   - All presentation reads `World` state (plus a read-only, non-serialized `events` ring buffer) and never influences simulation RNG, turn order, combat outcomes, enemy AI, procedural generation, or deterministic replay.
   - Any cosmetic randomness (such as audio pitch jitter or tile decorative variants) must come from an isolated cosmetic RNG or pure spatial hash, never `World.rng`.
2. **Dual Rendering Coexistence & Graceful Fallback:**
   - The classic glyph renderer remains a first-class, fully supported presentation mode alongside the graphical 32x32 tile renderer.
   - Switching render modes, zoom, tile scale, lighting, or animation settings consumes zero turns and never alters `World` state or `World.to_dict()`.
   - Missing or unloaded graphical/audio assets must degrade gracefully (to glyph rendering or silence) with zero script errors.
3. **Save & Content Compatibility:**
   - `World.SAVE_VERSION := 12` is preserved; all v1–v12 saves remain compatible.
   - Presentation, accessibility, and audio preferences are stored in `GameSettings` (`user://settings.cfg`).
   - Presentation manifests live under `content/presentation/` (outside `content/core/`) so `ContentDB.fingerprint()` remains unchanged.
4. **Offline Operation & Privacy:**
   - Zero cloud dependencies, telemetry endpoints, analytics services, ad SDKs, or mandatory accounts. Local telemetry (`Telemetry`) stays in-memory/local-only and is `null` in normal play.
   - No credentials, release keystores, personal/biographical data, or private-edition lore in tracked files.
5. **Lore & Asset Provenance Discipline:**
   - FALSE LIGHT and Sovereign-Ops repositories are read-only sources and must never be modified.
   - No external music, artwork, or proprietary assets are imported without verified game-distribution rights.
   - Every presentation asset is tracked in `content/presentation/asset_provenance.json` with source, generation method, licensing status, approval status, associated game entity, and modification history.
   - Proposed lore is never promoted to Canon without explicit owner authorization.
6. **Evidence Honesty:**
   - Automated verification (headless tests, bots, UI smoke, exported binary launch) is strictly separated from human playtesting and hardware runtime checks.
   - Anything not executed (Windows runtime, Web IndexedDB persistence, physical Android install/touch, human playtesting) is reported `NOT_RUN`.

## Submilestone Plan (M8.0 – M8.10)

| Submilestone | Scope | Key Deliverables |
|---|---|---|
| **M8.0** | Foundation & Outstanding Refinement | `docs/M8_SPEC.md`, unfinished bot run diagnosis & fixes in `tests/policy_player.gd`, Relic Work bot behavior, local Sphere identity & relic telemetry (`src/sim/telemetry.gd`), `docs/PLAYTEST.md` human playtest matrix tracking |
| **M8.1** | The Visual Codex | `docs/ART_DIRECTION.md` (palette, functional color meanings, non-color signifiers, typography, 32x32 grid, lighting, animation, accessibility, Ossuary Warrens vertical slice) |
| **M8.2** | The Dual Rendering Architecture | `src/ui/palette.gd` accessibility modes, `src/ui/game_settings.gd` display prefs, `src/ui/asset_registry.gd`, dual `MapView` glyph/tile renderer, Ossuary Warrens vertical-slice sprites, `tests/test_m8_renderer.gd` |
| **M8.3** | The Seven Spheres Incarnate | Seven distinct 32x32 Sphere environmental tile atlases (`assets/tiles/sphere_1_moon.png` .. `sphere_7_saturn.png`) covering terrain, hazards, portals, sites, and architectural accents |
| **M8.4** | Inhabitants, Relics & the Material World | Layered player avatars (8 origins, 8 callings, Masks), 10 enemy families + 15 bosses + 8 mutations, 18 NPCs, equipment/consumables/16 relics/artifacts, 16x16 icons, 64x64 emblems, `content/presentation/asset_registry.json`, `asset_provenance.json`, `docs/ASSET_REGISTRY.md`, `tests/test_m8_assets.gd` |
| **M8.5** | The Sovereign Interface | Cohesive mobile-first & keyboard-complete UI across all 20 screens/overlays, live equipment comparison deltas, enemy inspection card, avatar preview, responsive portrait/landscape, safe-area padding, left/right-handed touch, high-contrast/colorblind modes |
| **M8.6** | Motion, Impact & Feedback | Non-serialized `World.events` ring buffer, `src/ui/vfx_layer.gd`, combat/spell/status/telegraph/relic/mask/chain/ending feedback, reduced motion & instant mode, `tests/test_m8_vfx.gd` |
| **M8.7** | The Sound of Terra Tenebrae | 6-bus offline `AudioManager` (`Master`, `Music`, `Ambience`, `Combat`, `Interface`, `Narrative`), 24 procedural SFX + 7 Sphere ambient loops, isolated cosmetic variation, Android pause/focus handling |
| **M8.8** | The Liturgical Soundtrack | `content/presentation/soundtrack_manifest.json` covering 16 liturgical contexts, dual-deck crossfading player, clearly labeled replaceable placeholder tracks (`placeholder_liturgical_temp`), `tests/test_m8_audio.gd` |
| **M8.9** | Narrative Presentation & Accessibility | `content/presentation/narrative_frames.json` (localization-keyed), refined dramatic framing for Descent, Spheres, Bosses, NPCs, Contracts, Masks, False Light, Two Ways, Named Losses, and Endings, `tests/test_m8_narrative.gd` |
| **M8.10** | Performance, Portability & Internal Beta Gate | `tools/m8_perf_bench.gd`, full regression + deterministic + renderer-equivalence + UI smoke + screenshots (`docs/screenshots/m8/`), platform exports (`linux`, `windows`, `web`, `android`), `docs/M8_REPORT.md`, updated docs |

## Owner-Dependent & Human Playtest Gates

The following items from M7 and `docs/PLAYTEST.md` require human testers, owner hardware, or owner decisions and remain explicitly marked `NOT_RUN` / `OPEN` until performed:

1. **Human Playtest Matrix (`docs/PLAYTEST.md`):** Minimum 8 human sessions covering Initiate/Exile/Adversary/Sovereign, first-time & returning players, desktop keyboard & touchscreen, Veil-Touched/Unrecorded/Human/Cambion origins, and Ophite Binder & Rite Cantor callings.
2. **Owner Design Decisions:** Final naming and parameters of the 4 difficulty profiles; whether Veil-Touched's residual bot-play gap is intended; hidden-trap cue policy for auto-explore; Canon promotion review for `Proposed` M6 lore; approval/replacement of provisional M8 art and liturgical soundtrack assets with final production assets (e.g. approved VENEFICA LUX audio).
3. **Platform & Release Verification:** Physical Android device install & touchscreen testing (`adb`), Windows runtime execution, Web browser IndexedDB persistence verification, and external Android release keystore signing.
