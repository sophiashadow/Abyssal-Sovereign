# Design

## Pillars

1. **A traditional roguelike.** Turn-based on a grid, with permadeath, procedural floors, and readable deterministic rules. Every number the player meets is in the content files or this document.
2. **Escape, not conquest.** "You do not clear Terra Tenebrae. You survive it, unwork it, and get free of it." (FALSE LIGHT rulebook §1). A win is a way *out*.
3. **Metaphysics as mechanism.** Relief that collects later, power that turns on its holder, a record that catalogues you. These are trades with costs, never alignment points.
4. **Ambiguity is preserved.** Mechanics never settle what the sources leave open. See [docs/LORE.md](docs/LORE.md).
5. **Phone-first, keyboard-complete.** Every action is reachable by tap and by key. Nothing depends on hover. Text and tiles scale.

## Implemented rules (Milestones 1–4)

- **Turns.** Time-based. A normal action costs 100. Speed scales the cost (`cost × 100 / speed`). The lowest `(next_time, id)` acts next, and the player wins ties. Statuses tick at the start of the bearer's turn.
- **Combat.**
  - Hit chance: `70 + 5 × (accuracy − evasion)`, clamped to 5–95%.
  - Crit chance: 5% plus weapon and modifiers. A crit rolls the damage dice twice.
  - Damage: `dice + might + damage mods − defense`, minimum 1.
- **Awareness & Pursuit.** An unaware monster that can see you notices with 60% chance per turn (30% while wearing Nyx, +2 perception range while wearing Lilith). Awake monsters pursue your last-known position and lose pursuit if you are no longer visible when they arrive.
- **Progression.** The XP needed to reach level *L* is `15 · n(n+1)/2`, where *n* = *L* − 1. Each level adds class plus species HP. Odd levels add +1 accuracy. If `apotheosis >= 8` (the **Apotheosis Guard**), XP gain stops.
- **Recovery.** 1 HP every 6 turns (Revenants every 12), paused while wearing Eris or afflicted by `isolation`. Rest waits until full, isolated, or an enemy comes into view.
- **Inventory & Relics.** 16 slots; stackables share a slot. Equipment slots are weapon, armor and amulet. **Relics** (*Confessor's Glass*, *Ophite Key*, *Broken Halo*) can be **Worked** for temporary status buffs at an HP cost or **Transmuted** (consumed) for permanent stats.
- **Masks as stances.** Occultists (`mask_stances`) switch between **Bare Face**, **Nyx**, **Eris**, and **Lilith** for 1 turn. Active Masks build `mask_risk` toward `12`, triggering **Dissolution**, **Isolation**, or **Exposure**; only Bare Face cools risk.
- **Eight Chains.** Dominion cultists and cantors can inflict `isolation` on hit; the Preliator Sentinel and Inquisition Cantors can cast `perception_fog` (`sight -4`).
- **Seven Spheres & Sphere Gates.** Seven persisted floors (`Moon` through `Saturn`), with bidirectional stairs and a **Sphere Gate** choice (`Stormed`, `Serpent's Key`, `Given Back`, `By Name`) on first descent into each deeper Sphere.
- **Endings.**
  - **Victories:** Killing the Preliator Sentinel on depth 7 opens the Unwritten Door; stepping through yields **Victory: By Decree** (if `apotheosis >= 8`), **The Serpent's Way**, **The Way of Return**, or the balanced **Unwritten Door** escape.
  - **Named losses:** Deaths classify as **Gilded** (under False Light / Reckoning), **Fluent** (under Mask seizure or Eight Chains status), or **Catalogued**.
- **Saves.** One slot (`save_version` 8, with `v1 → v2 → ... → v8` migration), written atomically. It is deleted on death or victory.

### Origins and callings

| | Gift | Cost |
|---|---|---|
| Human | +25% XP | none |
| Revenant | *deathless*: once per floor, a killing blow leaves 1 HP | half healing, half regeneration |
| Cambion | *infernal blood*: blows ignore 1 defense | lowest base HP |
| Fallen Knight | *iron oath*: +2 defense below half HP; longsword, mail | |
| Occultist | *soul siphon*: heal 1 + will per kill; two vials of false light | fragile |
| Assassin | *sneak attack*: unaware targets are always hit, +50% crit | light armor |

### False Light

A vial gives 20 turns of +2 accuracy, +2 damage and +2 HP per turn. It is then followed by 40 turns of the Reckoning: −3 accuracy, −3 evasion, −1 damage. Drinking it is right when the fight is decisive now. It is wrong when the fight might continue afterwards. That trade is the point (rulebook §7).

## Balance (measured, not felt)

`tools/soak.gd` runs the test bot. The bot knows where the exit is, rests only when no enemy is in view, and drinks False Light against a guardian. The results measure the bot, not people. Balance targets are set on the default seed salt and confirmed on a held-out salt.

| Date | Change | Bot wins (tuning salt) | Bot wins (held-out) |
|---|---|---|---|
| 2026-11-26 | Before: no regeneration, Sentinel 60 HP 2d6+1 def 3 | 0–2% | n/a |
| 2026-11-26 | Regeneration and rest; Sentinel 45 HP 1d10+1 def 2; 1d6 for stiletto and knife; Occultist HP 12 (+4/level) | 44% (90 runs) | **33% (180 runs)** |
| 2026-11-26 | M2.1 Masks as stances (`mask_stances` on Occultist: Bare Face, Nyx, Eris, Lilith) | n/a | **37% (180 runs; Occultist 15/60 vs. 8/60 prior)** |
| 2026-11-26 | M2.2 Eight Chains enemy abilities (`chain_isolation` on cultist, `chain_fog` on Sentinel) | n/a | **35% (180 runs)** |
| 2026-11-26 | M2.3–M2.4 Relics (Work or Transmute) and Named losses (Catalogued, Fluent, Gilded) | n/a | **39% (180 runs)** |
| 2026-11-26 | M4 Seven Spheres (depths 1–7), Sphere Gates, Two Ways, Apotheosis Guard, Cantor & Inquisitor | 18% (135 runs, pre-tune) | **40% (180 runs, post-tune)** |

Known imbalance: in the 7-sphere soak (`180 runs`, `72 wins / 40%`), Fallen Knight still leads (`49/60`) over Assassin (`17/60`) and Occultist (`6/60`), because the simple bot does not kite, exploit Nyx/Lilith stealth/sight, or work relics tactically.

## Where the mythology goes next

Milestones 1–5 implemented Masks as stances, the Seven Spheres with Sphere Gates, the two Ways as victory families, all Eight Chains abilities with the Subjugation clock, Divine Contracts with Lecterns of Rites, item identification/BUC/sets/artifacts, the Apotheosis guard ("By Decree"), all six EXODUS Relics (Work or Transmute), and Named losses. Milestone 6 (The Breadth Pass: The Unrecorded World) expands the Atlas, bestiary, origins/callings, armory, recurring people/institutions, procedural threads, codex, and portable worldbuilding manifest (see `docs/M6_SPEC.md`).

## M5.1 — Character Development

M5.1 expands character building without changing the core turn loop or headless determinism:

- **Talent trees & points:** Each calling now has 3 talent trees (`9` trees total, `27` talents in `content/core/talents.json`) combining active abilities, multi-rank passives, prerequisites (`prereq`), and tier/level gates (tier 2 requires level `2`, tier 3 requires level `4`). Players gain `+1` talent point per level from level `2`, plus `+1` attribute point (`Might`, `Agility`, `Will`) on odd levels (`3, 5, 7, ...`).
- **Class resources & cooldowns:** Each calling uses a distinct resource (`classes.resource`, pool `10`): **Fallen Knight** uses `Stamina` (`+1` when taking a hit, `+1` every `3` turns), **Occultist** uses `Resonance` (`+2` on kill, `+1` every `3` turns), and **Assassin** uses `Poise` (`+1` on crit or sneak strike, `+1` every `2` turns). Active abilities spend resource and enter per-talent cooldowns.
- **Attribute scaling & species interactions:** Every positive point of `Might` also adds `+2` max HP for the player, and `Agility` adds `+2%` crit chance. **Humans** gain the `adaptable` trait (`+1` extra attribute point at levels `2` and `5`, `+1` extra talent point at levels `3` and `6`). **Revenants** are immune to `bleeding` and gain `Braced` when `deathless` triggers. **Cambions** pay `-1` HP when working Relics and deal `+2` damage with active talents while at `>= 2` `infernal_blood`.

### Measured Balance (M5.1 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `101 / 135` (`75%`) | `795` | Deaths: Spheres 2–7 (`warren` -> `preliator`) |
| `human` | `36 / 45` (`80%`) | — | `fallen_knight` 14/15, `assassin` 14/15, `occultist` 8/15 |
| `cambion` | `34 / 45` (`76%`) | — | `fallen_knight` 14/15, `assassin` 14/15, `occultist` 6/15 |
| `revenant` | `31 / 45` (`69%`) | — | `fallen_knight` 14/15, `assassin` 10/15, `occultist` 7/15 |

*(Occultist lags behind Knight and Assassin under deterministic bot play due to Mask risk management; upcoming M5.2 combat depth and enemy special attacks will further re-balance depth progression.)*

## M5.2 — Combat Depth

M5.2 deepens moment-to-moment tactical combat across ranged positioning, elemental/metaphysical resistances, status synergies, and elite encounters:

- **Ranged weapons, projectiles & occult scrolls:** Added dedicated `ranged` gear slot (`ashwood_shortbow`, `eye_focus`, `dominion_arbalest`, `sun_censer_sling`, `abyssal_rod`), thrown `projectile` consumables (`throwing_knife`, `javelin`, `cinder_flask` AoE, `ossuary_rime_vial`, `false_sun_prism`), and occult `scroll` spells (`scroll_of_phase_step`, `scroll_of_abyssal_lance` piercing line, `scroll_of_cinder_ward` fire nova). Line-of-fire uses Bresenham traces (`Grid.line`) blocked by walls and intervening actors.
- **Damage types & resistances:** Five damage types (`physical`, `fire`, `cold`, `radiant`, `void`). Armor `defense` mitigates `physical` blows; non-physical attacks bypass armor and scale by actor `resist(type)` (`-100..100%`) summed from innate species traits, equipped gear, active statuses, and Occultist Masks.
- **Tactical movement & ranged talents:** Added `Vanguard Charge` (rush + knockback + wall slam), `Veil Step` (blink + clear `pinned` + cool risk), and `Crippling Shot` (`chilled` / unaware `pinned`), bringing the total to `30` talents.
- **Status interactions & enemy specials:** `fire` + `chilled` triggers *Thermal Shock* (`+4` + `sundered`); `cold` + `burning` triggers *Scalding Steam* (`+3` + `perception_fog`); `fire` + `bleeding` triggers *Cauterize* (`+2`, removes bleed); `bleeding` + `sundered` triggers *Hemorrhage* (`+3`); `void` + `false_light` fractures the loan (`+3`, `-3` turns). Monsters deploy `warren_pounce`, `ranged_shot`, `solar_bolt`, `cinder_bolt`, `grave_chill`, `void_bolt`, `iron_shackle` (`pinned`), `leech_bite`, and `judgment_nova`.
- **Elites & Sphere Mid-Bosses:** Depth `>= 2` spawns deterministic mutated elites (`Ashen`, `Rime-bound`, `Apostate`, `Ironbound`); Sphere 3 (`The Gilded Choir`) and Sphere 5 (`The Iron Scriptorium`) place `Choir Cantor Prime` and `Iron Auditor` near the descent gate. Elites and bosses drop floor loot on death.

### Measured Balance (M5.2 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `112 / 135` (`83%`) | `711` | Balanced callings (`Knight 30/45`, `Occultist 40/45`, `Assassin 42/45`) |
| `human` | `40 / 45` (`89%`) | — | `assassin` 15/15, `occultist` 13/15, `fallen_knight` 12/15 |
| `cambion` | `36 / 45` (`80%`) | — | `assassin` 15/15, `occultist` 13/15, `fallen_knight` 8/15 |
| `revenant` | `36 / 45` (`80%`) | — | `occultist` 14/15, `assassin` 12/15, `fallen_knight` 10/15 |

## M5.3 — Equipment & Discovery

M5.3 turns loot into run-defining builds and discovery decisions:

- **Procedural affixes & rarity:** `Affixes` (`src/sim/affixes.gd`) rolls `common`, `uncommon`, `rare`, and unique `artifact` drops across depth-scaled magic odds. Prefixes (`Keen`, `Brutal`, `Ashen`, `Rimed`, `Abyssal`, `Gilded`, `Warded`, `Swift`, `Stout`, `Occult`) and suffixes (`of the Eye`, `of Cinders`, `of Hoarfrost`, `of the Oath`, `of Venom`, `of False Light`) grant stat mods, elemental/void damage types, on-hit statuses, and resistances.
- **Unidentified consumables & gear:** Every run deterministically shuffles disguise names (`cloudy phial`, `parchment inked 'TITHE'`, etc.) for unseen consumables and scrolls; starting items begin known. Unidentified magical/blessed/cursed gear conceals affixes until equipped or identified by a `scroll of witness`, `Confessor's Glass`, or `Ward-Keeper's Lamp`.
- **Blessed & Cursed (`BUC`):** Floor drops can be `blessed` (`+1` combat/armor mods, `+10%` Void/Radiant resist) or `cursed` (`-1` combat/armor mods, locked into its equipment slot until freed by a `scroll of unbinding`, `Break the Chain`, `Transmute Pain`, or transmuting a relic).
- **Equipment Sets & Unique Artifacts:** `ItemSets` (`src/sim/item_sets.gd`) grants 2-piece and 3-piece build bonuses for *Inquisitor's Audit*, *The Eye Unblinking* (including `+3` Mask risk cap), and *Cinder & Oath*. Four non-duplicating unique artifacts (*Unwritten Edge*, *Cowl of the First Witness*, *Serpent's Recurver*, *Chainbreaker Seal*) spawn deterministically at depth `>= 3` or on boss kills.
- **Additional EXODUS Relics:** Added *Severed Crown*, *Ward-Keeper's Lamp* (identifies pack + clears fog), and *Almoner's Purse* (regen + evasion + restores `+4` class resource).

### Measured Balance (M5.3 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `121 / 135` (`90%`) | `728` | Affixes/sets boosted late-floor durability; M5.4 hazards will tighten depth pressure |
| `human` | `43 / 45` (`96%`) | — | `assassin` 15/15, `fallen_knight` 14/15, `occultist` 14/15 |
| `cambion` | `39 / 45` (`87%`) | — | `assassin` 15/15, `occultist` 14/15, `fallen_knight` 10/15 |
| `revenant` | `39 / 45` (`87%`) | — | `occultist` 14/15, `assassin` 13/15, `fallen_knight` 12/15 |

## M5.4 — Dungeon Ecology

M5.4 transforms every Sphere into a distinct mechanical ecology rather than bare rooms:

- **Traps & Secret Doors:** Concealed `spike`, `cinder`, `rime`, and `shackle` traps fire on entry (`revealed` + `used` once triggered). Passive sight checks (`20 + sight * 5%`, or guaranteed while wearing *Eye of Lilith*, *Confessor's Clarity*, *Keeper's Vigil*, or *Lilith*) and `Search` (`s`, radius `3`) uncover hidden traps and `secret_door` caches; searching within `1` tile disarms revealed traps (`+5 XP`). Bumping or interacting with a revealed secret door opens the alcove and drops guaranteed magical loot.
- **Environmental Hazards:** Walkable Sphere terrain (`ASH_EMBER`, `RIME_ICE`, `MIASMA`, `SOLAR_GLARE`) deals mitigated elemental/metaphysical damage to any actor entering the tile and can ignite/chill/hex/expose—triggering M5.2 combos such as *Thermal Shock* and *Scalding Steam* for both players and monsters.
- **Altars, Shrines & Ritual Circles:** Interactive sites create tactical resource/apotheosis trade-offs: *Altar of Unbinding* (`Cleanse` curses + `-apotheosis` + `+Way of Return`, or blood `Tithe` for `+2 max HP`), *Shrine of the Unblinking Eye* (`Witness` reveals entire floor + identifies pack, or `Steal` `+1 Will` / `+2 apotheosis`), and *Geometric Ritual Circle* (`Inscribe` affix onto weapon/armor, or `Drain` `50%` heal + clear cooldowns & Mask risk).
- **Locked Vaults, Debt-Brokers & Trial Bells:** Audit vaults open with a consumable `vault_key` or reusable `ophite_key` relic (or `Force` for HP + apotheosis + alarm) for high-tier loot; wandering *Debt-Brokers* trade identified stock for blood (`HP`) or surplus goods (`barter`); *Trial Bell Monoliths* summon an elite-led ambush for guaranteed high loot and `+1` attribute point.
- **Signature Sphere Ecology:** Each Sphere (`1–7`, Moon–Saturn) selects its signature hazard tiles, trap mix, and guaranteed encounter sites (`Ecology.SPHERE_PROFILES`).

### Measured Balance (M5.4 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `120 / 135` (`89%`) | `786` | Balanced across origins (`41 / 40 / 39` of 45) & callings (`37 / 42 / 41` of 45) |
| `human` | `41 / 45` (`91%`) | — | `assassin` 15/15, `occultist` 14/15, `fallen_knight` 12/15 |
| `cambion` | `40 / 45` (`89%`) | — | `assassin` 15/15, `occultist` 14/15, `fallen_knight` 11/15 |
| `revenant` | `39 / 45` (`87%`) | — | `fallen_knight` 14/15, `occultist` 14/15, `assassin` 11/15 |

## M5.5 — Metaphysical Depth

M5.5 weaves the cosmology directly into tactical play across every enemy family, ritual site, relic, Mask, and path out:

- **Complete Eight Chains Grammar & Subjugation Clock:** Every Dominion and grave-chain ability maps into `World.CHAIN_TAGS` (`chain_isolation` → `isolation`, `chain_fog` → `perception_fog`, `chain_debility` → `debility`, `chain_threat` → `dread`, `chain_indulgence` → `false_light`, `chain_omnipotence` → `exposure`, `chain_degradation` → `degradation`, `chain_trivial` → `demanded`, which halts passive resource recovery). Landing a chain advances `subjugation` toward `chain_limit()` (`SUBJUGATION_LIMIT := 6`), culminating in `entangled` (speed, evasion, and accuracy penalty) before stepping the clock back to half limit.
- **Metaphysical Interactions (Masks, Relics, False Light, Apotheosis, Two Ways):**
  - *Masks:* `nyx` cushions chain `subjugation` gain (`-1`), `lilith` blocks `chain_fog` (`perception_fog`), and `eris` prevents passive `subjugation` decay every `10` turns.
  - *Relics:* *Broken Halo*'s `halo_aegis` turns incoming chain statuses aside; *Severed Crown*'s `crown_decree` refuses `entangled`, and working the Crown clears existing `entangled` and resets `subjugation` to `0`.
  - *False Light & Apotheosis:* Active `false_light` cushions `subjugation` gain (`-1`), whereas `reckoning` (`+1`) and mid-to-high `apotheosis` (`4..7`, granting `sovereign_mark`: `+2` damage, `+1` accuracy, and `+1` chain gain) accelerate the Subjugation clock.
  - *Two Ways:* Sustained leaning (`|way_return - way_serpent| >= 2`) bestows `return_oriented` (`+2` `chain_limit()`, `+1` defense, `+4` max HP, `+15%` Radiant resist) or `serpents_seam` (`+8%` crit, `+1` evasion, `+15%` Void resist).
- **Divine Contracts & Lectern of Rites:** *Lecterns of Rites* (`contract_lectern`) in Spheres `2`, `4`, and `6` offer four oath-bound contracts (`contracts.json`: *The Fast*, *Vow of Poverty*, *The Taken Name*, *The Crown Taken*). Signing grants an active boon (`boon_*`) until the required `floors` are kept (or attested at a *Geometric Ritual Circle* for `-3` HP) to win permanent `reward_mods` and a Way increment; breaking the oath or forsaking strips the boon and inflicts `forsworn`.

### Measured Balance (M5.5 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `110 / 135` (`81%`) | `718` | Eight Chains & Subjugation pressure tightened win rate (`Knight 29/45`, `Occultist 40/45`, `Assassin 41/45`) |
| `human` | `39 / 45` (`87%`) | — | `assassin` 14/15, `occultist` 14/15, `fallen_knight` 11/15 |
| `cambion` | `34 / 45` (`76%`) | — | `assassin` 14/15, `occultist` 13/15, `fallen_knight` 7/15 |
| `revenant` | `37 / 45` (`82%`) | — | `assassin` 13/15, `occultist` 13/15, `fallen_knight` 11/15 |

## M6.1 — The Atlas of Terra Tenebrae

M6.1 expands the seven linear Sphere floors into a 28-floor multi-region Atlas (`7` spine + `21` regional branches, sanctuaries, vaults, strongholds, and settlements; `2` branches per Sphere active per run via deterministic seed selection) plus bidirectional portals, `alt_down` cross-Sphere routes with Sphere Gates, and three regional terrain rules (`WATER_SHALLOW`, `SANCTUARY_FLOOR`, `IRON_GRATE`).

### Measured Balance (M6.1 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `111 / 135` (`82%`) | `742` | Callings: `Knight 33/45`, `Occultist 40/45`, `Assassin 38/45` |
| `human` | `41 / 45` (`91%`) | — | `assassin` 15/15, `occultist` 14/15, `fallen_knight` 12/15 |
| `cambion` | `31 / 45` (`69%`) | — | `assassin` 10/15, `occultist` 12/15, `fallen_knight` 9/15 |
| `revenant` | `39 / 45` (`87%`) | — | `assassin` 13/15, `occultist` 14/15, `fallen_knight` 12/15 |

## M6.2 — The Inhabitants

M6.2 expands the bestiary to `76` archetypes across `10` families including `15` named bosses/guardians (`12` new regional bosses across spine and branch floors), `9` new tactical AI behaviors (`telegraph_slam`, `kite_ranged`, `ambusher`, `support_ward`, `support_rally`, `drain_resource`, `lay_hazard`, `pull_chain`, `protect_ally`, `exploit_status`), `4` additional elite mutations (`radiant`, `swift`, `vampiric`, `warded`), and multi-role room squad generation.

### Measured Balance (M6.2 held-out soak, `tools/soak.gd --seeds=15 --salt=heldout`, `135` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `104 / 135` (`77%`) | `717` | Callings: `Knight 28/45`, `Occultist 40/45`, `Assassin 36/45` |
| `human` | `40 / 45` (`89%`) | — | `assassin` 14/15, `occultist` 15/15, `fallen_knight` 11/15 |
| `cambion` | `31 / 45` (`69%`) | — | `assassin` 12/15, `occultist` 12/15, `fallen_knight` 7/15 |
| `revenant` | `33 / 45` (`73%`) | — | `assassin` 10/15, `occultist` 13/15, `fallen_knight` 10/15 |

## M6.3 — Origins and Callings

M6.3 expands character creation to `8` origins (adding `ashborn`, `veilkin`, `ironbound_ward`, `unrecorded`, `penitent`) and `8` callings (adding `preliator_warden`, `tithe_marksman`, `rite_weaver`, `false_light_alchemist`, `ophite_binder`), `10` new traits, `104` talents across `24` trees (`13` per calling), `ward_sigil` + `snare` tactical features, and compact Android-readable origin/calling pills while reusing `stamina`/`resonance`/`poise`.

### Measured Balance (M6.3 held-out soak, `tools/soak.gd --seeds=2 --salt=heldout`, `128` runs)

| Scope | Wins / Runs | Mean Turns | Notes |
|---|---:|---:|---|
| Overall | `88 / 128` (`69%`) | `918` | All `64` origin×calling pairs sampled (`2` seeds each) |
| Callings | — | — | `Alchemist 15/16`, `Warden 14/16`, `Knight 12/16`, `Assassin 12/16`, `Arbalester 12/16`, `Occultist 11/16`, `Ophite Binder 9/16`, `Rite Cantor 3/16` |
| Origins | — | — | `human 13/16`, `ironbound_ward 12/16`, `unrecorded 12/16`, `ashborn 11/16`, `penitent 11/16`, `cambion 10/16`, `revenant 10/16`, `veilkin 9/16` |

## M6.4 — The Armory and Treasury

M6.4 expands equipment and utility breadth to `165` base items (`26` unique artifacts, `16` Work-vs-Transmute relics, `20` scrolls, `14` projectiles/bombs, `18` potions/poultices, `27` melee, `23` ranged/implements, `22` armor, `22` amulets, `3` keys), `46` procedural affixes, and `12` equipment sets (`subjugation_cap` + `mask_risk` build levers) while keeping existing rarity/BUC/identification rules intact and avoiding save-schema churn.

## M6.5 — People, Institutions and Allegiances

M6.5 populates Terra Tenebrae with `18` recurring characters across `8` two-minded institutions (no single good-versus-evil meter; backing one internal pole shifts standing with opposing members of that institution and alters service access, barter, healing, identification, Way attestations, and Subjugation relief).

## M6.6 — Threads Beneath the Record

M6.6 introduces `24` organic multi-stage threads (`8` drawn deterministically per run matching that seed's active Atlas branches). Threads emerge through NPC dialogue, regional thresholds, Relic draws, and Contracts—offering fulfillment, blood/barter sacrifice, explicit refusal (queuing delayed aftermath events), and abandonment consequences without a forced completionist quest log.

## M6.7 — Dungeon Variety and Emergent Encounters

M6.7 layers `10` composable interior room archetypes onto dungeon chambers (`pillared_hall`, `cross_vault`, `sanctuary_alcove`, `ambush_choke`, `ritual_chamber`, `flooded_cistern`, `archive_stacks`, `gauntlet_corridor`, `settlement_court`, `broken_cloister`) while preserving `100%` flood-fill connectivity, and seeds `4` emergent interactive encounter features (`rune_puzzle`, `abandoned_rite`, `sanctuary_hearth`, `echo_cache`) presenting resource, stealth, Subjugation, and knowledge trade-offs.
