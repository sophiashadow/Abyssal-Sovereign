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
- **Saves.** One slot (`save_version` 3, with `v1 → v2 → v3` migration), written atomically. It is deleted on death or victory.

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

Milestones 1–4 implemented Masks as stances, the Seven Spheres with Sphere Gates, the two Ways as victory families, the first two Eight Chains abilities, the Apotheosis guard ("By Decree"), Relics (Work or Transmute), and Named losses. Remaining mythology candidates for future depth include the remaining six Eight Chains abilities, rites/covenants between Spheres, and item identification. Each needs owner review before shipping.

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
