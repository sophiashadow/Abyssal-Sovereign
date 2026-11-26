# Portable Worldbuilding Manifest

`content/lore/world_manifest.json` (`schema_version: 1`) exports the shared narrative topology of **FALSE LIGHT / Terra Tenebrae** as constructed for **ABYSSAL SOVEREIGN** without binding sibling projects or prose tools to roguelike combat stats, dice, or UI logic.

## Design Goals

1. **Separation of lore and mechanics:** Narrative entities (`cosmology`, `places`, `institutions`, `people`, `relics`, `threads`, `relationships`) keep pure setting descriptions in `lore` and isolate Abyssal Sovereign ID mappings inside optional `game_ref` objects.
2. **Explicit provenance tagging:** Every world element carries a `provenance` tag:
   - `canon`: Established in approved upstream FALSE LIGHT sources.
   - `canon_derived`: Mechanically or architecturally derived directly from canon organs/motifs (e.g., EXODUS relic names, Eight Chains, Rulebook organs).
   - `interpretation`: Roguelike architectural translation of canon ideas.
   - `proposed`: Original additions or material from unapproved expansions (such as Sovereign-Ops PR #300 characters/factions/locations) that must NOT be promoted to shared canon without owner approval.
3. **Strict exclusion boundaries:** The manifest explicitly records excluded material (`exclusions` array) and forbids any content from private edition rules, Rulebook §13 Tier 1–2 real-world threat archetypes, personal/biographical data, or persona/voice documents.

## Top-Level Sections

| Section | Contents |
|---|---|
| `cosmology` | `spheres` (Seven Spheres), `two_ways`, `masks`, `eight_chains` |
| `places` | All `28` Spine and regional places with `sphere`, `region_kind`, `branch`, `lore`, `provenance`, `game_ref` |
| `institutions` | All `8` two-minded institutions with competing `poles`, `lore`, `provenance`, `game_ref` |
| `people` | All `18` recurring characters linked to `institution_id`, `pole`, and `place_ids` |
| `relics` | All `16` metaphysical Relics (`6` canon-derived EXODUS motifs + `10` proposed) |
| `threads` | All `24` narrative threads linked to `person_id` and `institution_id` |
| `relationships` | Typed graph edges (`leans:<pole>`, `frequents`, `branches_from`) connecting people, institutions, and places |

## Validation

Run `./tools/test.sh test_manifest` (or `./tools/verify.sh`) to verify JSON validity, schema version, provenance enum compliance, internal relationship integrity, valid `ContentDB` `game_ref` bindings, and negative exclusion checks.
