# Roadmap

## Milestone 0: foundations (done 2026-11-26)

Project, layering, content schema and validator, seeded RNG, test runner, and docs.

## Milestone 1: playable vertical slice (done 2026-11-26, Linux)

Everything in the M1 brief is implemented. The automated evidence is the headless suite, the soak and the UI smoke. All of it was run on Linux in a container under Xvfb. No human playtest has happened yet.

### Known defects and limits

- **Occultist & Assassin balance (7 Spheres):** *(Resolved in M5.1–M5.5)* M4 saw Fallen Knight lead `49/60` vs. Assassin `17/60` and Occultist `6/60`; after M5.5 Depth Pass, the held-out soak reaches `110/135` (`81%`) with balanced callings (`Knight 29/45`, `Occultist 40/45`, `Assassin 41/45`).
- **Ranged play & identification:** *(Resolved in M5.2–M5.3)* Ranged slot, thrown projectiles, occult scrolls, secret doors, and consumable/gear identification are implemented.
- **Typography and accessibility:** the glyph font is the engine default (proportional, centred per cell). A dedicated monospace font needs a license check first. There is no colour-blind palette option and no screen-reader support.
- **Unverified runtimes:** Windows runtime, Web browser `user://` persistence, physical Android device install/touch/kill-save test, and Android release signing are `NOT_RUN`.

## Milestone 2: the mythology as mechanics (done 2026-11-26)

1. **Masks as stances** (`mask_stances` on Occultist: Bare Face, Nyx, Eris, Lilith; `SAVE_VERSION` 2).
2. **Eight Chains enemy abilities** (`chain_isolation` on cultist of the false sun, `chain_fog` / `perception_fog` on Preliator Sentinel).
3. **Relics, worked or transmuted** (*Confessor's Glass*, *Ophite Key*, *Broken Halo*).
4. **Named losses** (Catalogued, Fluent, Gilded) on the death screen.

Owner decisions resolved 2026-11-26 (see [docs/LORE.md](docs/LORE.md)): Apotheosis ("By Decree") can be a win; the Unwritten Door, origins, and callings are canon.

## Milestone 3: platforms (presets & local builds done 2026-11-26)

1. **Linux export preset and build:** Done (`build/linux/abyssal-sovereign.x86_64`, verified launching cleanly).
2. **Android debug APK:** Done (`build/android/abyssal-sovereign-debug.apk`, aligned & debug-signed; physical device test `NOT_RUN`).
3. **Release signing:** Needs a keystore the owner creates and keeps outside the repo.
4. **Windows and Web exports:** Done (`build/windows/abyssal-sovereign.exe`, `build/web/index.html`; Windows runtime and Web browser `user://` persistence `NOT_RUN`).

## Milestone 4: depth (done 2026-11-26)

1. **Seven Spheres** (Moon through Saturn, depths 1–7) with **Sphere Gates** (`Stormed`, `Serpent's Key`, `Given Back`, `By Name`) and deeper Dominion enemies (`Inquisition Cantor`, `Tithe Inquisitor`).
2. **Two Ways** (`The Serpent's Way`, `The Way of Return`) as alternative victory families.
3. **Apotheosis guard** and the hollow **"By Decree"** victory.

## Milestone 5.1: character development (done 2026-11-26)

1. **Talent trees & progression:** 3 talent trees per calling (`27` talents total in `content/core/talents.json`) with active and passive abilities, prerequisites, and tier/level gates.
2. **Attribute allocation:** Players gain attribute points on odd levels and talent points every level from 2; `Might` increases max HP (`+2/pt`), `Agility` increases crit chance (`+2%/pt`), and `Will` scales Occultist abilities and healing.
3. **Class resources & cooldowns:** `Stamina` (Fallen Knight), `Resonance` (Occultist), and `Poise` (Assassin), with tactical active cooldowns and Build (`c`) / Act (`a` / `1`–`6`) UI panels.
4. **Species differentiation:** Humans gain `adaptable` (extra attribute points at levels 2/5 and talent points at levels 3/6); Revenants ignore `bleeding` and gain `Braced` on `deathless` triggers; Cambions pay `-1` HP when working Relics and deal `+2` damage with active talents while at `>= 2` `infernal_blood`.

## Milestone 5.2: combat depth (done 2026-11-26)

1. **Ranged & occult arsenal:** Added `ranged` weapon slot, thrown `projectile` items/flasks (including AoE splash), and `scroll` spells (`phase_step`, piercing `abyssal_lance`, `cinder_ward`), with line-of-fire blocking (`Grid.line`) and interactive Aim Mode (`f` / `Fire` + trajectory highlight).
2. **Damage types & resistances:** `physical`, `fire`, `cold`, `radiant`, and `void` damage with innate species/mask/gear/status resistances and vulnerabilities.
3. **Tactical movement & status synergies:** Added `Vanguard Charge`, `Veil Step`, and `Crippling Shot` (total `30` talents) plus emergent status combos (`Thermal Shock`, `Scalding Steam`, `Cauterize`, `Hemorrhage`, and `False Light` Void fracture).
4. **Enemy specials, elites & bosses:** Added `ossuary_arbalest`, `cinder_acolyte`, `ossuary_wight`, monster specials (`solar_bolt`, `cinder_bolt`, `grave_chill`, `void_bolt`, `iron_shackle`, `judgment_nova`, `warren_pounce`, `leech_bite`), deterministic elites (`Ashen`, `Rime-bound`, `Apostate`, `Ironbound`), Sphere 3/5 mid-bosses (`Choir Cantor Prime`, `Iron Auditor`), and `SAVE_VERSION := 5`.

## Milestone 5.3: equipment and discovery (done 2026-11-26)

1. **Procedural affixes & rarity:** Implemented `Affixes` (`common`, `uncommon`, `rare`, `artifact`) across 10 prefixes and 6 suffixes granting stats, resists, elemental conversions, and status procs.
2. **Identification & BUC:** Run-shuffled disguises for unknown consumables/scrolls (`id_aliases`), hidden affixes until equipped or witnessed (`scroll_of_identify`, `Confessor's Glass`, `Ward-Keeper's Lamp`), and `blessed` / `cursed` gear with slot-locking curses (`scroll_of_unbind`, `Break the Chain`, `Transmute Pain`, relic transmutation).
3. **Equipment sets, unique artifacts & EXODUS relics:** 3 sets (`Inquisitor's Audit`, `The Eye Unblinking`, `Cinder & Oath`), 4 non-duplicating artifacts (`Unwritten Edge`, `Cowl of the First Witness`, `Serpent's Recurver`, `Chainbreaker Seal`), 3 EXODUS relics (`Severed Crown`, `Ward-Keeper's Lamp`, `Almoner's Purse`), and `SAVE_VERSION := 6`.

## Milestone 5.4: dungeon ecology (done 2026-11-26)

1. **Traps & secret doors:** Added `spike`/`cinder`/`rime`/`shackle` traps, `secret_door` caches, passive keen-sight detection, `Search` (`s` / disarm +5 XP), and revealed secret passages opening into guaranteed magical loot.
2. **Environmental hazards:** Added walkable `ASH_EMBER`, `RIME_ICE`, `MIASMA`, and `SOLAR_GLARE` tiles interacting cleanly with M5.2 damage resistances and status combos, with safe tap-to-travel stops.
3. **Interactive dungeon sites & Sphere profiles:** Added *Altars of Unbinding*, *Shrines of the Unblinking Eye*, *Geometric Ritual Circles*, *Locked Audit Vaults* (`vault_key` + reusable `ophite_key`), *Wandering Debt-Brokers* (blood/barter), *Trial Bell Monoliths*, Sphere-specific `SPHERE_PROFILES`, and `SAVE_VERSION := 7`.

## Milestone 5.5: metaphysical depth (done 2026-11-26)

1. **Eight Chains enemy grammar & Subjugation clock:** Completed all eight chain tags (`isolation`, `fog`, `debility`, `threat`, `indulgence`, `omnipotence`, `degradation`, `trivial`), `demanded` resource-regen block, and the `subjugation` clock culminating in `entangled`.
2. **Masks, Relics, False Light, Apotheosis & Two Ways interactions:** Wired live clock modifiers across Masks (`nyx`/`lilith`/`eris`), Relics (`Broken Halo`/`Severed Crown`), `false_light`/`reckoning`, `apotheosis` (`sovereign_mark`), and sustained Way orientations (`return_oriented`, `serpents_seam`).
3. **Divine contracts & Lectern of Rites:** Added `contracts.json` (*The Fast*, *Vow of Poverty*, *The Taken Name*, *The Crown Taken*), `contract_lectern` sites, `ritual_circle` oath attestation, permanent `reward_mods`, `forsworn` oath breaches, and `SAVE_VERSION := 8`.

M5 (The Depth Pass: M5.1–M5.5) is complete.

## Milestone 6.1: The Atlas of Terra Tenebrae (done 2026-11-26)

1. **28-floor Atlas across Seven Spheres:** Expanded `floors.json` from 7 linear floors to 7 main-spine floors plus 21 regional sub-floors (branches, sanctuaries, vaults, strongholds, settlements), with deterministic per-run selection of 2 branches per Sphere (`21` active floors per run) and bidirectional `alt_down` cross-Sphere routes.
2. **Regional Terrain & Portals:** Added `BRANCH_IN`, `BRANCH_OUT`, `WATER_SHALLOW`, `SANCTUARY_FLOOR`, and `IRON_GRATE` with distinct movement, elemental, noise, regen, and Subjugation rules, plus Atlas overlay (`Tab` / Pause) and `SAVE_VERSION := 9` (`v8 -> v9` migration).

## Milestone 6.2: The Inhabitants (done 2026-11-26)

1. **76-archetype Bestiary & 15 Bosses/Guardians:** Expanded `monsters.json` across 10 distinct families plus 12 new named regional bosses across spine and branch floors.
2. **Tactical AI, Elite Mutations & Squads:** Added `telegraph_slam`, `kite_ranged`, `ambusher`, `support_ward`, `support_rally`, `drain_resource`, `lay_hazard`, `pull_chain`, `protect_ally`, and `exploit_status`, plus 4 new elite mutations (`radiant`, `swift`, `vampiric`, `warded`) and squad room spawns.

## Milestone 6.3: Origins and Callings (done 2026-11-26)

1. **8 Origins, 8 Callings, 104 Talents:** Expanded character creation with 5 Proposed origins (`ashborn`, `veilkin`, `ironbound_ward`, `unrecorded`, `penitent`) and 5 Proposed callings (`preliator_warden`, `tithe_marksman`, `rite_weaver`, `false_light_alchemist`, `ophite_binder`), 10 new mechanical traits, `ward_sigil`/`snare` tactical features, and compact Android-readable origin/calling pills.

## Milestone 6.4: The Armory and Treasury (done 2026-11-26)

1. **165 Base Items, 46 Affixes, 12 Sets, 26 Artifacts, 16 Relics:** Expanded `items.json`, `Affixes`, `ItemSets` (with `subjugation_cap_bonus`), 15 new scroll spells in `World._cast_scroll()`, and distributed loot pools across all 28 `floors.json` tables.

## Milestone 6.5: People, Institutions and Allegiances (done 2026-11-26)

1. **18 Recurring NPCs & 8 Divided Institutions (`SAVE_VERSION := 10`):** Added `"factions"` and `"npcs"` content packs, deterministic floor placement, `npc_standing` (`-2..+3`) and `faction_flags` persistence (`v9 -> v10` migration), 8 deterministic NPC service types, and People & Institutions overlay (`p`).

## Milestone 6.6: Threads Beneath the Record (done 2026-11-26)

1. **24 World Threads & Delayed Consequences (`SAVE_VERSION := 11`):** Added `threads.json`, `Threads` seeded per-run subset selection, alternative resolution (`goal`/`sacrifice`/`refuse`/`abandon`), delayed aftermath scheduling, non-spoiler Thread Journal (`j`), and `v10 -> v11` save migration.

## Milestone 6.7: Dungeon Variety and Emergent Encounters (done 2026-11-26)

1. **10 Room Archetypes & 4 Emergent Sites:** Added `RoomArchetypes`, safe interior tactical geometry preserving `100%` connectivity, and interactive `rune_puzzle`, `abandoned_rite`, `sanctuary_hearth`, and `echo_cache` sites.

## Milestone 6.8: Discovery, Codex and Run History (done 2026-11-26)

1. **Knowledge-Only Codex (`user://codex.json`):** Added `Codex`, `CodexIO` (atomic, zero-spoiler, zero-power), Codex overlay (`k` / Title / Pause), and enriched end-of-run Victory/Death summaries.

## Milestone 6.9: Portable Worldbuilding Manifest (done 2026-11-26)

1. **Setting Manifest & Validator:** Added `content/lore/world_manifest.json` (`schema_version: 1`), `docs/WORLD_MANIFEST.md`, and `tests/test_manifest.gd`.

## Milestone 6.10: Integration, Reachability & Exports (done 2026-11-26)

1. **Reachability, Validation Soak & Exports:** Added `tests/test_reachability.gd` (zero dead content), `FloorMap.set_explored()`, documented `AutoPlayer` + expanded `tools/soak.gd` telemetry (`144/192 = 75%` held-out validation across all 64 pairs), verified `./tools/export.sh all` (`linux`, `windows`, `web`, `android` debug APK), Linux binary launch, and APK signature.

M6 (The Breadth Pass: M6.1–M6.10) is complete.

## Milestone 7: the Refinement Pass (done 2026-11-27, draft PR #1; not merged)

Tempering, not enlarging: no major content added. Instrumented soak and eight bot policies (M7.1); two origin stat changes with a same-seed A/B and reasoned no-change verdicts elsewhere (M7.2 to M7.6); safe auto-explore, travel, compare, sort/filter/search, log filters, rebindable shortcuts and confirmations (M7.7); four descent profiles, optional onboarding hints, save v12 (M7.8); `docs/PLAYTEST.md` (M7.9); final gate with a fresh validation salt and exports (M7.10). Full evidence, defects and limits are in `docs/M7_REPORT.md`. All balance data is bot play; no human playtest has run.

## Next: Milestone 8 — The Incarnation Pass (not started; needs owner authorization)

Gate: run human playtest round 1 (`docs/PLAYTEST.md`) first. Then, from the structured list in `docs/M7_REPORT.md`: diagnose the 91 unfinished validation runs, settle profile names and parameters, instrument Sphere identity, add Work-relic bot coverage, decide Veil-Touched's residual gap, and complete the NOT_RUN platform checks (Windows runtime, Web persistence, physical Android, release keystore).
