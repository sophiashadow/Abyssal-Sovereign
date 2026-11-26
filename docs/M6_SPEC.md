# Milestone 6 Implementation Specification — The Breadth Pass: The Unrecorded World

**Status:** Active Specification  
**Baseline:** Commit `fac51e8a8ae30940a3feb5840981e350e8aca4df` (`M5.5 — Metaphysical Depth`)  
**Verified M5.5 Baseline (reproduced locally):**
- `tools/test.sh`: `106` tests, `106` passed, `0` failed, `1800` checks, `0` engine errors.
- `SAVE_VERSION := 8` (v1–v7 migrations intact).
- Held-out M5.5 soak (documented in `DESIGN.md` / `HANDOFF.md`): `110/135` (`81%`), mean `718` turns.
- Content baseline: `3` origins (`human`, `revenant`, `cambion`), `3` callings (`fallen_knight`, `occultist`, `assassin`), `30` talents, `12` monsters, `34` items, `4` contracts, `7` floors (Moon–Saturn).

---

## 1. Governing Design Philosophy

M5 established mechanical depth. **M6 establishes breadth**: more circumstances in which existing mechanics—damage types, status combos, Mask governance, Eight Chains, Subjugation, Divine Contracts, Two Ways, Apotheosis Guard, identification, BUC, sets, Relics (Work vs. Transmute), traps, hazards, and tactical positioning—become meaningful.

Core principles:
1. **Meaningful distinctions over numerical bloat:** Do not pad content to hit arbitrary quotas or inflate numbers. Every addition must introduce a recognizable tactical, strategic, narrative, or economic decision.
2. **Reuse existing systems:** All new regions, enemies, origins, callings, items, NPCs, factions, and threads extend the typed GDScript simulation (`src/core`, `src/content`, `src/gen`, `src/sim`, `src/persistence`) cleanly without engine/Node coupling.
3. **Preserve cosmology & ambiguity:** The Seven Spheres (Moon–Saturn), Sphere Gates, Two Ways, Apotheosis Guard, Unwritten Door, and FALSE LIGHT ambiguity remain intact.
4. **Read-only mythology boundaries:** Public FALSE LIGHT texts (`game/THE_POISONER_OF_FALSE_LIGHT.md`, `OCCULT.md`, `EXODUS.md`, and Sovereign-Ops PR #300 `BREADTH_PASS.md`) are read-only sources. Surface locations inform underground equivalents or threshold connections without claiming all surface districts are literal caves. Unapproved PR #300 people, factions, and threads remain tagged **Proposed** in `docs/LORE.md` and `content/lore/world_manifest.json`. Private editions, rulebook §13 Tier 1–2 real-world threat archetypes, and personal/persona details are excluded.
5. **Determinism, Permadeath, Offline & Android Readability:** All randomness uses seeded `Rng`; saves remain atomic with explicit `SAVE_VERSION` migrations; discovery codex persists knowledge only (no meta-power); UI remains touch-first and readable at `2340x1080`.

---

## 2. Submilestone Architecture & Deliverables

### M6.1 — The Atlas of Terra Tenebrae (`SAVE_VERSION := 9`)
- **Scope:** Expand the 7 linear Sphere floors into a **28-floor Atlas** (7 main-spine floors + 21 regional sub-floors across the Seven Spheres: optional branches, sanctuaries, vault complexes, Dominion strongholds, and unrecorded settlements).
- **Per-Run Divergence:** Each run deterministically selects 2 of 3 regional branches per Sphere (`21` active floors per run: `7` spine + `14` branches) with bidirectional `BRANCH_IN` / `BRANCH_OUT` portals and optional `alt_down` cross-Sphere routes (triggering Sphere Gate choices when entering a Sphere deeper than `max_sphere_reached`).
- **Regional Terrain & Rules:**
  - `WATER_SHALLOW` (`~`): `+25` move cost, extinguishes `burning`, `+25%` cold damage taken while standing in water.
  - `SANCTUARY_FLOOR` (`,`): halves natural regeneration interval, `-1` Subjugation clock gain from incoming Chains.
  - `IRON_GRATE` (`:`): audible footsteps wake unaware foes within Chebyshev radius `5`.
- **UI & Atlas View:** HUD/Look/Pause display region kind and portal destinations; an in-run **Atlas** overlay shows discovered spheres/branches without spoiling unvisited secrets.

### M6.2 — The Inhabitants
- **Scope:** Expand bestiary to **60+ mechanically distinct monster archetypes** across 10 families (Dominion soldiers/officials, Inquisition agents, Ossuary undead, Metaphysical predators, Contract-bound entities, False-sun manifestations, Unrecorded creatures, Ritual constructs, Rogue Geometry servants, Sphere-adapted organisms) + **12+ named regional bosses/mid-bosses** with telegraphed abilities and counterplay.
- **Tactical AI & Encounter Composition:** Kiting ranged units, concealed ambushers, ally-warding/rallying supporters, resource drainers, hazard layers, telegraphed slams, chain pullers, protectors, 4 new elite mutations (`radiant`, `swift`, `vampiric`, `warded`), and multi-role room squads.

### M6.3 — Origins and Callings
- **Scope:** Expand `species.json` to **8 origins** (preserving Human, Revenant, Cambion; adding 5 lore-compatible Proposed origins with non-stat mechanical traits) and `classes.json` to **8 callings** (preserving Fallen Knight, Occultist, Assassin; adding 5 Proposed callings using `stamina`/`resonance`/`poise`—e.g. defensive bulwark, dedicated archer/crossbowman, ritualist, alchemist/artificer, binder/controller).
- **Talents:** Expand `talents.json` to **100–130 meaningful talents** (3 trees per calling, active + passive, synergies with equipment/Masks/Relics/Chains). Keep `_show_create()` readable on mobile (`2340x1080`).

### M6.4 — The Armory and Treasury
- **Scope:** Expand `items.json` to **150+ base items** across melee, ranged, armor, amulets, occult implements, consumables, scrolls, projectiles, ritual components, utility tools, and keys.
- **Procedural & Unique Depth:** Expand `Affixes` to **40–50** playstyle-changing prefixes/suffixes, `ItemSets` to **10–12 sets**, **25+ unique artifacts**, and **15+ relics** (preserving the 6 EXODUS relics and Work-vs-Transmute strategic trade-offs).

### M6.5 — People, Institutions and Allegiances (`SAVE_VERSION := 10`)
- **Scope:** Add `factions.json` (8 two-minded institutions: 5 from PR #300 + 3 underground, tracked via named flags rather than a linear good/evil bar) and `npcs.json` (18 recurring NPCs: 12 from PR #300 tagged `Proposed` + 6 underground figures) with hidden per-run standing (`-2..+3`), dialogue/barter/service choices, and integration with contracts, rites, and Two Ways.

### M6.6 — Threads Beneath the Record (`SAVE_VERSION := 11`)
- **Scope:** Add `threads.json` and `src/sim/threads.gd` supporting **20–26 multi-stage procedural threads** (delayed consequences, branch discoveries, rival institutional demands, relic/rescue/refusal dilemmas) with consequences for completion, refusal, or abandonment.

### M6.7 — Dungeon Variety and Emergent Encounters
- **Scope:** Add `src/gen/room_archetypes.gd` with composable room templates (pillared halls, cross vaults, sanctuary alcoves, ambush chokes, ritual chambers, flooded cisterns, archive stacks, gauntlet corridors, settlement courts), environmental rune puzzles, costly rest sanctuaries, and rare non-combat encounters while maintaining 100% map navigability invariants.

### M6.8 — Discovery, Codex and Run History
- **Scope:** Add `src/sim/codex.gd` and `src/persistence/codex_io.gd` (`user://codex.json`) recording persistent discovery knowledge (creatures, locations, equipment, artifacts/relics, NPCs, institutions, threads, contracts, win/loss history) separate from per-run state, with no meta-power progression and no spoilers for undiscovered entries, plus rich death/victory summaries.

### M6.9 — Portable Worldbuilding Manifest
- **Scope:** Add `content/lore/world_manifest.json` + `docs/WORLD_MANIFEST.md` separating shared FALSE LIGHT / Terra Tenebrae worldbuilding from Abyssal Sovereign stats/mechanics, validated by `tests/test_manifest.gd` (including strict privacy and exclusion checks).

### M6.10 — Integration, Verification, Exports & M7 Handoff
- **Scope:** Expand `AutoPlayer` and `tools/soak.gd` telemetry; add `tests/test_reachability.gd`; run `tools/verify.sh`, fresh held-out validation soak (`--salt=m6_final_validation`), and platform exports (`tools/export.sh linux android` plus Windows/Web if available); deliver final metrics, `NOT_RUN` table, known-defect register, and M7 Balance & Refinement handoff in `docs/HANDOFF.md`.

---

## 3. Balance & Verification Policy

- **During M6:** Fix genuine exploits, broken interactions, generation dead-ends, infinite loops, and severe economy defects. Do NOT tune difficulty against held-out validation seeds and do NOT arbitrarily nerf player kits or inflate enemy HP/damage. Full difficulty tuning belongs to M7.
- **Quality Gates (every submilestone):**
  1. `tools/test.sh` passes with 0 failures and 0 Godot runtime/script/parse errors.
  2. `tools/ui_smoke.gd` passes at `1280x720` and `2340x1080` with 0 failures.
  3. `docs/CONTENT_SCHEMA.md` matches `ContentSchema` & `Traits.KNOWN` (enforced by test).
  4. `docs/LORE.md` and `docs/HANDOFF.md` updated cleanly before atomic commit.
