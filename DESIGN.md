# Design

## Pillars

1. **A traditional roguelike.** Turn-based on a grid, with permadeath, procedural floors, and readable deterministic rules. Every number the player meets is in the content files or this document.
2. **Escape, not conquest.** "You do not clear Terra Tenebrae. You survive it, unwork it, and get free of it." (FALSE LIGHT rulebook §1). A win is a way *out*.
3. **Metaphysics as mechanism.** Relief that collects later, power that turns on its holder, a record that catalogues you. These are trades with costs, never alignment points.
4. **Ambiguity is preserved.** Mechanics never settle what the sources leave open. See [docs/LORE.md](docs/LORE.md).
5. **Phone-first, keyboard-complete.** Every action is reachable by tap and by key. Nothing depends on hover. Text and tiles scale.

## Milestone 1 rules (implemented)

- **Turns.** Time-based. A normal action costs 100. Speed scales the cost (`cost × 100 / speed`). The lowest `(next_time, id)` acts next, and the player wins ties. Statuses tick at the start of the bearer's turn.
- **Combat.**
  - Hit chance: `70 + 5 × (accuracy − evasion)`, clamped to 5–95%.
  - Crit chance: 5% plus weapon and modifiers. A crit rolls the damage dice twice.
  - Damage: `dice + might + damage mods − defense`, minimum 1.
- **Awareness.** An unaware monster that can see you notices with 60% chance per turn. Monsters that are awake pursue you along a shared distance map.
- **Progression.** The XP needed to reach level *L* is `15 · n(n+1)/2`, where *n* = *L* − 1. Each level adds class plus species HP. Odd levels add +1 accuracy.
- **Recovery.** 1 HP every 6 turns (Revenants every 12). Rest waits until full or until an enemy is in view.
- **Inventory.** 16 slots; stackables share a slot. Equipment slots are weapon, armor and amulet.
- **Floors.**
  - Three floors: the Ossuary Warrens, the Tithe Vaults and the Sealed Stair, with rising monster mix and density.
  - The last floor has the Preliator Sentinel guarding the Unwritten Door. Killing it opens the door, and stepping through wins.
  - Floors persist, and the stairs go both ways.
- **Saves.** One slot, written atomically. It is deleted on death or victory.

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

Known imbalance: the Occultist improved from 8/60 to 15/60 held-out wins with Masks as stances (against 37/60 for the Knight), and the bot only uses Eris/Bare Face. Further M2/M4 kits (rites, relics) will round out the gap.

## Where the mythology goes next

See the candidates table in [docs/LORE.md](docs/LORE.md): Masks as stances, the Seven Spheres as depth bands with gates, the two Ways as alternative victories, the Eight Chains as an enemy ability grammar, the Apotheosis guard, and relics that can be worked or transmuted. None of these are built. Each needs owner review first.
