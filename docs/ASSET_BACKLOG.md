# Asset Production Backlog (M9.1)

**Status:** M9.1 elevated all 13 procedural atlases (32×32 tiles, features, layered player avatars, 86 monsters + 15 bosses, 18 NPCs, 165 items + 16 relics + 26 artifacts, 16×16 icons, 24 64×64 woodcut emblems) and generated the 7 application/adaptive icon assets under `assets/icons/`. All visual assets remain deterministically generated in-repo by `tools/gen_sprites.py` and are honestly tagged `provisional_m9_asset` in `content/presentation/asset_provenance.json` pending owner artistic review.

If the owner elects to replace specific procedural sprites with bespoke hand-painted pixel art or commissioned illustrations, use the backlog specification below without altering `content/core/*.json` IDs.

---

## Priority Artwork Replacement Tiers

### Tier 1 — Signature Visual Anchors (Highest Player Visibility)
| Asset Group | Stable IDs | Target Size | Art Direction Notes |
|---|---|---|---|
| **Title Crest & App Icon** | `emblems:title_crest`, `assets/icons/icon_512.png`, `adaptive_fg.png` | `64×64` emblem / `512×512` icon | Crowned Witness Eye over crossed iron keys & octagonal seal in `PORPHYRY`, `GOLD`, `LUX`, `IVORY`. |
| **Ending & Named Loss Emblems** | `way_serpent`, `way_return`, `unwritten_door`, `by_decree`, `loss_catalogued`, `loss_fluent`, `loss_gilded` | `64×64` woodcut | High-contrast ecclesiastical woodcut style; `VOID` background, `1px` crisp rim, symbolic clarity over clutter. |
| **Seven Sphere Seals** | `sphere_1`..`sphere_7` | `64×64` woodcut | Planetary-alchemical emblems matching Moon (ossuary), Mercury (scales), Venus (chalice), Sun (eclipsed sun), Mars (anvil/chains), Jupiter (imperial decree), Saturn (sealed door). |
| **15 Named Bosses & Guardians** | `preliator_sentinel`, `vault_enumerator`, `choir_cantor_prime`, `iron_auditor`, `alley_rat_matriarch`, + 10 regional bosses | `32×32` (`26–30px` tall) | Distinct non-generic silhouettes grounded on octagonal seal pedestals; crisp `VOID` outline. |

### Tier 2 — Core Gameplay Readability
| Asset Group | Stable IDs | Target Size | Art Direction Notes |
|---|---|---|---|
| **8 Origins, 8 Callings, 5 Masks** | `origin:*`, `calling:*`, `mask:*` | `32×32` layered | Origin provides body/head/cloak; Calling overlays weapon/garment trim cleanly without occluding head; Mask overlays face (`nyx`, `eris`, `lilith`, `lux_venefica`). |
| **16 EXODUS / Proposed Relics** | `confessors_glass`, `ophite_key`, `broken_halo`, `severed_crown`, etc. | `32×32` (`20–24px` icon) | Immediately recognizable sacred/cursed artifacts on dark dungeon stone. |
| **18 Recurring NPCs** | `uc_the_stitcher`..`warden_tomas` | `32×32` | Upright cloaked/habited figures with institution-colored vestments and signature hand props. |
| **Seven Sphere Tile Atlases** | `assets/tiles/sphere_1_moon.png`..`sphere_7_saturn.png` | `256×256` (`8×8` grid of `32×32`) | Matte low-saturation floors (`4` variants) + 3/4 liturgical walls (`4` variants) + stairs, doors, portals, water, sanctuary, grate, 4 hazards, and 14 features (ready/used pairs). |

### Tier 3 — Extended Catalog Polish
| Asset Group | Stable IDs | Target Size | Art Direction Notes |
|---|---|---|---|
| **Remaining Monster Archetypes** | `monsters.json` non-boss entries (`71`) | `32×32` | Family-coherent silhouettes with individual gear/posture variation. |
| **8 Institution Emblems** | `faction:*` (`8` entries) | `64×64` | Two-pole heraldic seals echoing internal institutional splits. |
| **Promotional Key Art** | External store capsule / itch.io banner (optional) | `1920×1080` / `630×500` | Outside runtime bundle unless explicitly commissioned; never fabricate or import unauthorized art. |

---

## Drop-In Integration Workflow
1. Replace the target cell in the corresponding atlas PNG (`assets/tiles/`, `assets/sprites/`, `assets/portraits/`) or point `content/presentation/asset_registry.json` at a new sheet/rect.
2. Update `content/presentation/asset_provenance.json` with verified `source`, `author_or_method`, `license_status`, and `approval_status: "owner_approved"`.
3. Validate bounds, 100% ID coverage, and provenance completeness with:
   ```sh
   ./tools/test.sh test_m8_assets
   ./tools/test.sh test_m8_renderer
   ```
