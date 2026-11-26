# Content schema (version 1)

All game content is JSON under a pack directory. The core pack is `content/core/`. The authoritative definition is `src/content/schema.gd`. `tests/test_content.gd` fails if this document stops naming any field or trait listed there.

## File shape

```json
{"schema": "<kind>", "version": 1, "entries": [ { "id": "...", ... } ]}
```

- `schema` is one of the kinds below. `version` must be `1`.
- Ids are lowercase snake_case, unique within a file, and stable: saves and other content refer to them.
- Packs load in order (core first). A later pack that reuses an id replaces the earlier entry, with a warning.
- Unknown fields are ignored with a warning. Every error names the file, entry and field, and validation reports all of them in one pass.
- Packs are data only. There is no scripting in content. A behaviour that needs code is a trait (see below).

## Field types

| Type | Meaning |
|---|---|
| id | lowercase snake_case |
| string | non-empty string |
| text | any string |
| int / number / bool | whole number / any number / true or false |
| dice | `NdS`, `NdS+B`, `NdS-B` or a flat `B` (for example `1d6+1`) |
| glyph | exactly one character |
| color | `#rrggbb` |
| enum | one of the listed values |
| ref:kind | an id defined in that kind |
| list:type | array of that type |
| mods | object of modifier stat → int. Stats: might, agility, will, max_hp, accuracy, evasion, defense, damage, crit, speed, sight |
| attrs | object of attribute → int. Attributes: might, agility, will |
| table:kind | non-empty array of `{"id": ref, "weight": int > 0}` |
| trait | a trait implemented in `src/sim/traits.gd` |

## statuses

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | id | yes | |
| `name` | string | yes | |
| `description` | text | yes | |
| `duration` | int ≥ 1 | yes | turns of the bearer |
| `mods` | mods | no | applied while active |
| `regen` | int | no | HP healed at the start of each of the bearer's turns |
| `on_expire` | ref:statuses | no | status applied when this one ends |
| `color` | color | no | UI tint |

## items

| Field | Type | Req | Notes |
|---|---|---|---|
| `id` | id | yes | |
| `name` | string | yes | |
| `glyph` | glyph | yes | |
| `color` | color | yes | |
| `kind` | enum: weapon, armor, amulet, consumable, relic | yes | slot or use |
| `description` | text | yes | |
| `damage` | dice | weapon | replaces unarmed damage |
| `accuracy` | int | no | weapon accuracy bonus |
| `crit` | int | no | weapon crit chance bonus, % |
| `defense` | int | armor | |
| `evasion` | int | no | armor evasion bonus (may be negative) |
| `mods` | mods | amulet | applied while equipped |
| `effect` | enum: heal, status | consumable | |
| `heal` | dice | if effect heal | |
| `status` | ref:statuses | if effect status | |
| `stackable` | bool | no | identical items share one inventory slot |
| `work_status` | ref:statuses | relic | status granted when worked |
| `work_cost_hp` | int ≥ 0 | no | HP paid to work the relic |
| `work_desc` | text | relic | summary of the work effect |
| `transmute_mods` | mods | relic | permanent stat changes when transmuted |
| `transmute_desc` | text | relic | summary of the transmute effect |

## species

| Field | Type | Req | Notes |
|---|---|---|---|
| `id`, `name`, `description` | | yes | |
| `attributes` | attrs | yes | added to the class's |
| `hp` | int | yes | added to the class's starting HP |
| `hp_per_level` | int | yes | added to the class's per-level HP |
| `xp_mult` | number | no | multiplier on XP gained (default 1) |
| `heal_mult` | number | no | multiplier on healing from items (default 1) |
| `mods` | mods | no | permanent |
| `traits` | list:trait | no | |

## classes

| Field | Type | Req | Notes |
|---|---|---|---|
| `id`, `name`, `description` | | yes | |
| `attributes` | attrs | yes | |
| `hp` | int ≥ 1 | yes | |
| `hp_per_level` | int ≥ 0 | yes | |
| `accuracy`, `evasion` | int | no | base bonuses |
| `starting_equipment` | list:ref:items | yes | equipped at start |
| `starting_items` | list:ref:items | no | carried at start |
| `traits` | list:trait | no | |

## monsters

| Field | Type | Req | Notes |
|---|---|---|---|
| `id`, `name`, `description` | | yes | |
| `glyph`, `color` | | yes | |
| `hp` | int ≥ 1 | yes | |
| `damage` | dice | yes | |
| `accuracy`, `evasion`, `defense` | int | yes | |
| `speed` | int ≥ 10 | yes | 100 is normal; higher acts more often |
| `xp` | int ≥ 0 | yes | awarded on kill |
| `perception` | int ≥ 1 | yes | distance at which it can notice a visible player |
| `tags` | list:string | no | free-form (for example `undead`, `guardian`) |
| `unique` | bool | no | at most one per floor plan |

## floors

| Field | Type | Req | Notes |
|---|---|---|---|
| `id`, `name`, `description` | | yes | |
| `depth` | int ≥ 1 | yes | depths must run 1..N with no gaps |
| `width` ≥ 20, `height` ≥ 15 | int | yes | map size |
| `rooms_min`, `rooms_max` | int ≥ 2 | yes | |
| `monsters_min`, `monsters_max` | int ≥ 0 | yes | |
| `items_min`, `items_max` | int ≥ 0 | yes | |
| `monster_table` | table:monsters | yes | |
| `item_table` | table:items | yes | |
| `exit` | enum: stairs, sealed_door | yes | the deepest floor must be `sealed_door` |
| `guardian` | ref:monsters | if sealed_door | killing it opens the door; stepping through wins |

## Traits

Traits are behaviour implemented in code. Content may only name these:

- `sneak_attack`: attacks on an unaware monster always hit, with +50% crit chance.
- `iron_oath`: +2 defense while below half HP.
- `soul_siphon`: heal 1 + will on each kill.
- `deathless`: once per floor, a killing blow leaves you at 1 HP.
- `infernal_blood`: your blows ignore 1 point of defense.
- `mask_stances`: wear the Masks as stances (Bare Face, Nyx, Eris, Lilith), switching for 1 turn.
