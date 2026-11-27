# Asset Registry & Provenance Specification

ABYSSAL SOVEREIGN separates simulation identifiers (`content/core/*.json`) from presentation assets (`assets/`). The mapping lives in `content/presentation/asset_registry.json` and provenance metadata lives in `content/presentation/asset_provenance.json`.

## Architecture

- **`src/ui/asset_registry.gd` (`AssetRegistry`):** Presentation-only `RefCounted` loader. Never imported or read by `src/core/`, `src/content/`, `src/gen/`, `src/sim/`, or `src/persistence/`.
- **Graceful Fallback:** Any missing atlas file, broken region, or unmapped content ID returns `{}` / `null` and falls back to classic glyph rendering (`MapView._glyph`) or silence without errors.
- **Registry Sections:**
  - `atlases`: Maps atlas IDs (`sphere_1_moon`..`sphere_7_saturn`, `avatars`, `monsters`, `npcs`, `items`, `icons`, `emblems`) to `res://assets/...` PNGs, cell size, and pixel dimensions.
  - `tiles`: `s<1..7>:<tile_id>[:variant]` -> 32×32 floor/wall variants, stairs, doors, portals, water, sanctuary floor, iron grate, and hazards.
  - `features`: `s<1..7>:<kind>:<ready|used>` -> altars, shrines, ritual circles, vaults, debt-brokers, lecterns, trial bells, secret doors, traps, wards, and emergent sites.
  - `avatars`: `origin:<species_id>` (8 origins), `calling:<class_id>` (8 callings), and `mask:<mask_id>` (`bare_face`, `nyx`, `eris`, `lilith`, `lux_venefica`) composited in layers.
  - `monsters`: All 86 bestiary IDs (including bespoke 32×32 sprites for all 15 bosses/guardians) plus `tag:<tag>` family silhouettes.
  - `npcs`: All 18 recurring NPCs.
  - `items`: All 165 base items (bespoke sprites for all 16 EXODUS/Proposed relics and distinct visual treatments for all 26 unique artifacts, plus category silhouettes for weapons, ranged, armor, amulets, consumables, scrolls, projectiles, and keys).
  - `statuses`: 16×16 status icons for all 51 statuses.
  - `icons`: 16×16 icons for 24 talent trees (`tree:<name>`), 8 elite mutations (`elite:<name>`), Eight Chains (`chain:<tag>`), 4 Divine Contracts (`contract:<id>`), and UI badges.
  - `emblems`: 64×64 woodcut emblems (`title_crest`, `sphere_1`..`sphere_7`, `faction:<id>` for all 8 institutions, `boss_seal`, `way_serpent`, `way_return`, `unwritten_door`, `by_decree`, `loss_catalogued`, `loss_fluent`, `loss_gilded`).

## Provenance Schema (`content/presentation/asset_provenance.json`)

Every file in `assets/` must have an entry recording:

- `asset_id`: Stable identifier.
- `path`: Resource path (`res://assets/...`).
- `source`: Origin of the asset.
- `author_or_method`: Creator or deterministic generator command.
- `license_status`: Verified license or internal placeholder status (`project-original-cc0-equivalent`, `project-original-placeholder`).
- `approval_status`: `provisional_m8_asset`, `provisional_m9_asset`, `placeholder_liturgical_temp`, or `owner_approved`.
- `associated_entities`: Content IDs or subsystems mapped to this asset.
- `modification_history`: Ordered audit log of edits.

## Replacing Provisional Assets

To swap in owner-approved hand-crafted pixel art, illustrations, or VENEFICA LUX audio:
1. Place the approved asset under `assets/...` without altering `content/core/*.json` IDs.
2. Update the corresponding atlas rect or path in `content/presentation/asset_registry.json` (or `soundtrack_manifest.json` for music).
3. Update `content/presentation/asset_provenance.json` with verified `source`, `license_status`, and `approval_status: "owner_approved"`.
4. Run `./tools/test.sh test_m8_assets` and `./.tools/godot --headless --path . --import` to confirm zero missing references or out-of-bounds rects.
