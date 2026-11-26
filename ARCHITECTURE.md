# Architecture

## Layers

```
content/core/*.json        data: species, classes, talents, contracts, items, monsters, statuses, floors
src/core/                  Rng (seeded, saveable), Dice, Grid helpers
src/content/               ContentSchema (field rules), ContentDB (load, validate, look up)
src/gen/                   DungeonGen: pure function (floor def, seed) -> FloorMap + spawn plan
src/sim/                   World, Actor, Item, Affixes, ItemSets, Ecology, FloorMap, Tiles, Traits, Masks, Fov, Pathing, Combat
src/persistence/           SaveIO (atomic file), SaveCheck (structural validation)
src/ui/                    main.gd (screens, input, autosave), MapView, Palette, GameSettings
tests/                     headless suite, helpers, AutoPlayer bot
tools/                     test.sh, verify.sh, export.sh, soak.gd (balance), ui_smoke.gd (drives the real UI)
```

Dependencies point one way, down the list. Nothing in `src/sim`, `src/gen`, `src/content` or `src/core` touches a Node, input or rendering. All of it is `RefCounted`. This is why the whole game runs headless in tests and the bot uses the same `World` API as the UI.

**World is the only API the UI calls.** `player_move`, `player_wait`, `player_pickup`, `player_drop`, `player_use`, `player_unequip`, `player_work_relic`, `player_transmute_relic`, `player_switch_mask`, `player_stairs`, `player_descend_gate`, `player_rest`, plus read-only queries (`describe_at`, `visible_hostiles`, `current_floor`, `needs_gate_to_descend`, `named_loss`, `victory_kind`). An action returns `true` when it spent time. The world then runs monsters until the player's turn comes round again.

## Determinism

- **Run RNG.** One `Rng` per run, seeded from `Rng.derive(run_seed, "play")`. Its state is saved, so a resumed run continues the same random stream. This is tested: a run saved and resumed midway serializes byte-identically to one played straight through (`tests/test_save.gd`).
- **Floor generation.** Each floor is seeded independently with `Rng.derive(run_seed, "floor:N")`, so the floor layout doesn't depend on what you did before arriving. (Monster spawn timing uses the run RNG.)
- **Seed derivation.** `Rng.derive` is FNV-1a over the seed and a salt. It has a golden-value test, so a refactor can't silently change every seed.
- **Iteration order.** No gameplay depends on Dictionary iteration over unordered keys, wall-clock time or frame timing.

## Content

JSON packs are validated against `ContentSchema` at load. The validator reports every error in one pass, each naming its file, entry and field. Ids are stable, and saves refer to content by id. A save records a content fingerprint and warns, without refusing, when the content has changed. Behaviour that needs code is a **trait**, named in content and implemented in `Traits`/`Combat`/`World`. A typo in a trait name is a validation error. See [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md).

## Saves

- **Format.** `user://run.save.json`, holding a `save_version` (currently 9; v1–v8 saves migrate automatically), run state, all visited floors, and the log. Terrain and exploration are base64 byte arrays.
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

## M5.1 Additions (Character Development)

- **Content:** `content/core/talents.json` (validated under `Schema.KINDS` `"talents"`) and `classes.resource` (`stamina`, `resonance`, `poise`); `statuses.json` adds `sundered`, `braced`, `apostate_focus`, `veiled`, `bleeding`; `traits.gd` adds `adaptable`.
- **Save schema:** `World.SAVE_VERSION := 4` with deterministic migration `v1 -> v2 -> v3 -> v4` adding `stat_points`, `talent_points`, `resource`, `talents`, and `cooldowns` to serialized actors (`SaveCheck.ACTOR_KEYS` updated).
- **World APIs:** `player_spend_stat(stat_name)`, `can_learn_talent(talent_id)`, `player_learn_talent(talent_id)`, `learned_active_talents()`, `nearest_visible_hostile(max_range)`, and `player_use_talent(talent_id)`.
- **UI:** `src/ui/main.gd` exposes `Build` (`c`, attribute allocation + 3 talent trees) and `Act` (`a` / `1`–`6`, active abilities) overlays plus class resource and unspent point counters in the HUD.

## M5.2 Additions (Combat Depth)

- **Core & Content:** `Grid.line(a, b)` Bresenham trace; `ContentSchema.DAMAGE_TYPES` (`physical`, `fire`, `cold`, `radiant`, `void`); `resists` field type checked in `ContentDB`; `ranged`, `projectile`, and `scroll` items plus elite/boss fields (`monsters.specials`, `ranged_damage`, `floors.boss`) in `content/core/*.json`.
- **Save schema:** `World.SAVE_VERSION := 5` with deterministic migration `v1 -> v2 -> v3 -> v4 -> v5` adding `resists`, `specials`, and `elite` to actors (`SaveCheck.ACTOR_KEYS` updated).
- **World & Combat APIs:** `Combat.mitigate`, `Combat.ranged_hit_chance`, `Combat.resolve_ranged`; `World.projectile_trace`, `World.player_fire`, `World.player_use_at`, `World.player_use_talent(tid, target_pos)`.
- **Targeting UI:** `MapView.aim_path` trajectory overlay and `Main` Aim Mode (`f` / `Fire`, `Throw`, `Cast`, `Tab` target cycling, tile tap confirmation).

## M5.3 Additions (Equipment & Discovery)

- **Core & Sim modules:** `src/sim/affixes.gd` (`Affixes`: prefixes, suffixes, `BUC`, run-shuffled aliases) and `src/sim/item_sets.gd` (`ItemSets`: 2pc/3pc set aggregation and Mask risk cap bonus); extended `Item` (`src/sim/item.gd`) with per-instance `rarity`, `affixes`, `buc`, `identified`, `mods`, `resists`, `bonus_damage_type`, `bonus_status`.
- **Save schema:** `World.SAVE_VERSION := 6` with deterministic migration `v1 -> ... -> v5 -> v6` adding root `id_known`, `id_aliases`, `uniques`, plus extended item fields (`rar`, `aff`, `buc`, `idn`, `mods`, `res`, `dt`, `st`) validated by `SaveCheck`.
- **World APIs:** `World.item_name`, `World.is_item_identified`, `World.identify_item`, `World.identify_pack`, `World.unbind_curses`, `scroll_of_identify`, `scroll_of_unbind`, and unique artifact spawning.
- **UI:** Set bonus summaries in `_show_build()`, rarity/BUC/affix/ID-aware `_item_stats()` and inventory labels in `src/ui/main.gd`, plus floor item rarity tinting in `MapView`.

## M5.4 Additions (Dungeon Ecology)

- **Core, Sim & Gen:** `Tiles` hazards (`ASH_EMBER`, `RIME_ICE`, `MIASMA`, `SOLAR_GLARE`), `src/sim/ecology.gd` (`Ecology` traps, hazards, Sphere profiles, site descriptors), `FloorMap.features` serialization, `DungeonGen._place_ecology()` deterministic hazard/trap/secret/site placement, and `vault_key` (`kind: "key"`).
- **Save schema:** `World.SAVE_VERSION := 7` with migration `v6 -> v7` backfilling `features` on serialized floors (`SaveCheck.FLOOR_KEYS` updated).
- **World APIs:** `World.player_search()`, `World.player_interact(pos, choice)`, `_on_actor_enter_tile()`, `_passive_detect()`, and `_open_secret_door()`.
- **UI:** `Palette` hazard visuals, `MapView` revealed feature rendering, `Main` `Srch` (`s`), `Use` (`e`), travel hazard/trap stops, and `_show_feature()` interactive overlays.

## M5.5 Additions (Metaphysical Depth)

- **Content & Schema:** Added `"contracts"` kind in `ContentSchema` (`content/core/contracts.json`), expanded `statuses.json` with chain/contract/allegiance/apotheosis statuses, and tagged monsters across all 8 `chain_*` abilities.
- **Core, Sim & Ecology:** Added `contract_lectern` (`SPHERE_PROFILES[2, 4, 6]`), `Actor.stat("damage_bonus")` `bonus_damage` support, `World.CHAIN_TAGS`, `World.SUBJUGATION_LIMIT := 6`, `World.chain_limit()`, `_chain_hit()`, `_entangle()`, `_tick_subjugation()`, `_update_allegiance()`, `World.player_sign_contract()`, `_contract_event()`, `_advance_contract()`, `_breach_contract()`, and `ritual_circle` `"attest"` interaction.
- **Save schema:** `World.SAVE_VERSION := 8` with migration `v7 -> v8` backfilling `subjugation`, `contract`, `contract_progress`, and `contract_log` (validated in `SaveCheck.problems()`).
- **UI:** Live Subjugation meter, active Contract tracker, and Way allegiance status in HUD, plus Lectern of Rites signing/forsaking and Ritual Circle oath attestation in `_show_feature()`.

## M6.1 Additions (The Atlas of Terra Tenebrae)

- **Content & Schema:** Extended `ContentSchema.FIELDS["floors"]` with `region_kind`, `branch`, `hazard`, `terrain`, `parent`, `alt_down`, `sites`, `provenance`, and `branch_end` exits (`content/core/floors.json` expanded to 28 floors: 7 spine + 21 regional sub-floors). `ContentDB.floor_for_depth()` and `max_depth()` preserve spine semantics; added `floor_def()`, `spine_floor_id()`, `branch_floors_for_depth()`, `all_floor_ids()`.
- **Terrain & Generation:** Added `Tiles.BRANCH_IN`, `BRANCH_OUT`, `WATER_SHALLOW` (+25 move cost, douses `burning`, +25% cold damage), `SANCTUARY_FLOOR` (2x regen rate, -1 Subjugation gain), and `IRON_GRATE` (wakes unaware foes within radius 5). `FloorMap` tracks `floor_id` and `portals`; `DungeonGen.generate()` places bidirectional branch portals and regional terrain/sites.
- **World & Save v9:** `World.floors` keyed by `floor_id`, deterministic per-run `_build_atlas()` selecting 2 of 3 branches per Sphere plus active `alt_down` cross-Sphere routes with Sphere Gate support, `SAVE_VERSION := 9` with `v8 -> v9` migration.
- **UI:** Region kind indicators in HUD, portal prompt/travel, and `_show_atlas()` (`Tab` / Pause menu).

## M6.2 Additions (The Inhabitants)

- **Content:** Expanded `content/core/monsters.json` to 76 archetypes across 10 families including 15 named bosses/guardians (12 new regional bosses across spine and branch floors).
- **Tactical AI & Encounter Composition:** Added `telegraph_slam` (2-turn telegraphed area blow), `kite_ranged`, `ambusher`, `support_ward`, `support_rally`, `drain_resource`, `lay_hazard`, `pull_chain`, `protect_ally` (physical shield aura), and `exploit_status` in `World`, 4 additional elite mutations (`radiant`, `swift`, `vampiric`, `warded`), and multi-role room squad grouping in `DungeonGen`.

## M6.3 Additions (Origins and Callings)

- **Content & Traits:** Expanded `content/core/species.json` to 8 origins and `content/core/classes.json` to 8 callings, all reusing `stamina`/`resonance`/`poise`; expanded `content/core/talents.json` to 104 talents (13 per calling across 3 trees each); added 10 traits in `src/sim/traits.gd` (`cinder_born`, `liminal_sight`, `ledger_forged`, `unfiled`, `penance_vigor`, `bulwark_stance`, `steady_aim`, `ritual_cadence`, `alchemical_potency`, `chain_binder`).
- **Simulation:** Wired all 10 origin/calling traits across `Actor`, `Combat`, `Ecology`, and `World`, added `ward_sigil` + `"snare"` trap features and `_tick_wards()`, and implemented active talent effects for all 5 new callings (`warden_bash`, `threshold_hold`, `bulwark_slam`, `warden_challenge`, `piercing_bolt`, `barbed_quarrel`, `twin_quarrel`, `pinning_volley`, `beacon_shot`, `execution_bolt`, `hex_sigil`, `summon_ward_sigil`, `place_snare`, `chain_shackle`, `unmaking_chorus`, `radiant_rebuke`, `sanctify_ground`, `alchemical_bomb`, `frost_tincture`, `thermal_catalysis`, `volatile_salve`, `philosophers_loan`).
- **UI:** Compacted `_show_create()` pill layout for phone readability while preserving smoke labels, and wired `steady_aim` `+1` ranged reach in Aim Mode.

## M6.4 Additions (Armory and Treasury)

- **Content:** Expanded `content/core/items.json` to `165` base items (`27` melee, `23` ranged/implements, `22` armor, `22` amulets including `26` unique artifacts; `18` heal/status consumables, `14` projectiles/bombs, `20` scrolls, `3` keys, `16` relics) and `statuses.json` with 17 consumable/scroll/relic statuses; updated `floors.json` loot tables.
- **Affixes & Sets:** Expanded `Affixes` (`24` prefixes + `22` suffixes = `46` affixes, `24` potion & `24` scroll disguise aliases) and `ItemSets` (`12` sets with 2pc/3pc bonuses including `subjugation_cap_bonus` wired into `World.chain_limit()`).
- **Simulation:** Added `15` new scroll spells in `World._cast_scroll()`, side-effects for new relics in `World.player_work_relic()`, and generic `kind == "key"` unlocking at `vault_gate`s.

## M6.5 Additions (People, Institutions and Allegiances)

- **Content & Schema:** Added `"factions"` (`8` two-minded institutions with competing `pole_a`/`pole_b` flags) and `"npcs"` (`18` recurring figures with preferred floors, deterministic services, and institutional leanings) in `ContentSchema` and `ContentDB._kind_rules()`.
- **Simulation & Save v10:** Deterministically places `"npc"` features (`_place_floor_npcs()`) per floor seed; tracks `npc_standing` (`-2..+3`), `faction_flags`, and `npcs_met` across save version `10` (`v9 -> v10` migration in `_migrate()` + validation in `SaveCheck`); implements `_interact_npc()` (`talk`, `service`, `pledge`, `refuse`, standing gating & opposing-pole shifts).
- **UI:** Extended `Ecology` + `_show_feature()` with `"npc"` dialogue/service/pledge controls and added `_show_people()` (`p` / Pause) showing institutional splits and met NPCs.
