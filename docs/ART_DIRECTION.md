# Art Direction Codex — ABYSSAL SOVEREIGN

*Giving form to Terra Tenebrae.*

---

## 1. Visual Identity & Aesthetic Pillars

ABYSSAL SOVEREIGN manifests the cosmology of **Terra Tenebrae** as a Gnostic, occult-medieval subterranean world. It is **not** a generic high-fantasy dungeon crawler with skulls and brimstone. Every visual element should look like a recovered liturgical blueprint, an audit ledger etched in iron, or a damp catacomb beneath an armed church.

1. **Oppressive, Subterranean, and Sacred:** Thick masonry, cramped catacombs, iron grates, tallow light, and monumental geometry that dwarfs the individual.
2. **Intellectually Esoteric over Generically Demonic:** Symbols draw from ecclesiastical architecture, alchemical diagrams, geometric seals, chains, astrolabes, balances, and illuminated manuscripts rather than cartoonish gore or horned devils.
3. **Corrupted Authority:** The Dominion of the Preliator and the Architect's order look *measured, numbered, stamped, and gilded*—porphyry, brass, counterfeit gold, and ruled parchment—while the Eye / Unwritten Margin cuts across them in cold silver and Witness magenta.
4. **Tactical Clarity First:** Background masonry stays low-saturation and matte so actors, hazards, portals, and interactable sites read immediately at 24px–48px on both desktop monitors and midrange Android phones.

---

## 2. Foundational Palette & Functional Meanings

All UI and sprite palettes derive from eight foundational tones (preserving the read-only FALSE LIGHT visual register in `docs/LORE.md`):

| Token | Name | Hex | Primary Role |
|---|---|---|---|
| `VOID` | Void black | `#080609` | Unexplored abyss, background ground, deep shadow silhouettes |
| `IRON` | Weathered iron | `#52515c` | Structural walls, grates, shackles, Dominion armor, secondary frames |
| `PORPHYRY` | Dark porphyry | `#2d1a2e` / `#4b2749` | Panel surfaces, imperial stone, Choir vestments, shadow glaze |
| `GOLD` | Tarnished gold | `#b79555` | Stairs, thresholds, brass instruments, active borders, rare glints |
| `FALSE_SUN` | Counterfeit sun | `#f2c35c` | False Light status, solar glare, targeting reticles, high alerts |
| `IVORY` | Parchment ivory | `#eee5d3` / `#d3bea0` | Primary body typography, bone masonry, ledger paper, readable text |
| `LUX` | Witness magenta | `#e0008f` | The Eye, Masks, esoteric seams, ritual circles, metaphysical pressure |
| `SILVER` | Cold silver | `#b8c4d0` | Moon-sphere stone, Ophite steel, rime accents, neutral glyphs |
| `BLOOD` | Restrained blood-red | `#a62639` / `#ff4d6d` | Wounds, sealed Unwritten Door, hostile threat, dangerous traps |

### Functional Color Assignments & Non-Color Signifiers

**Rule:** Danger, friendliness, enemy rank, interactability, and metaphysical pressure **must never rely on color alone**. Every functional state pairs hue with a geometric shape, silhouette, or badge:

| State / Category | Color Cue | Mandatory Non-Color Signifier |
|---|---|---|
| **Player Avatar** | Ivory + Calling trim | Centered full-height silhouette + faint cold-silver ground ring |
| **Hostile Enemy** | Blood / Amber / Gold | Corner targeting brackets (`L`-corners at bottom) when visible; distinct monster silhouette |
| **Elite Enemy** | Mutation hue + Gold | Top-right geometric **crown/chevron badge** + dashed aura corners |
| **Named Boss / Guardian** | Crimson / Witness Magenta | **Double-aureole octagonal seal frame** beneath sprite + larger silhouette (`26–28px` height) |
| **Friendly / Neutral NPC** | Sage (`#78bea7`) + Ivory | **Diamond halo marker** (`◇`) above-right + hooded/cloaked upright posture |
| **Interactable Site** | Gold / Magenta / Sage | Elevated pedestal/altar/lectern silhouette + subtle corner pip when unused |
| **Environmental Hazard** | Fire/Ice/Void/Radiant tint | Distinct surface pattern: embers = broken diagonal sparks; rime = crystalline lattice; miasma = dotted wisps; solar glare = geometric ray cross |
| **Revealed Trap** | Blood (`#ff4d6d`) | Sharp jagged caltrop/jaw teeth (`^` geometry) when armed; flat broken bar when disarmed |
| **Metaphysical Pressure** | Witness Magenta (`#e0008f`) | Subjugation segmented pip bar (`0..limit`); Mask badge (`Bare`/`Nyx`/`Eris`/`Lilith`/`Venefica`) with unique icon |

### Accessibility Color Modes (`GameSettings.color_mode` & `high_contrast`)

- **Standard:** Default Terra Tenebrae palette above.
- **Deuteranopia / Protanopia Safe:** Shifts Sage (`#78bea7`) -> Sky Cyan (`#6ec6ff`) and Blood (`#ff4d6d`) -> Vermilion Orange (`#ff7a33`) so friendly vs. hostile vs. safe never relies on red-green separation.
- **Tritanopia Safe:** Shifts Miasma/Void (`#8f7ae0`) -> Magenta (`#e0008f`) and Rime (`#6ec6ff`) -> Pale Cyan (`#9ff0ff`), pairing with Gold/Amber (`#f2c35c`) vs. Deep Rose.
- **High Contrast (`high_contrast = true`):** Raises background panel border brightness (`#8a7a66` -> `#d3bea0`), boosts unexplored/remembered floor contrast (`remembered()` darkening reduced from `0.62` to `0.45`), and draws 1px dark outlines around all sprites and UI labels.

---

## 3. Tile Grid, Proportions & Iconography

- **Base Tile Grid:** **32×32 pixels** native crisp pixel art (`TEXTURE_FILTER_NEAREST`), integer-scaled (`1x`, `2x`, `1.5x` fallback on dense mobile screens) or configurable via `GameSettings.tile_sizes` (`16, 20, 24, 28, 32, 40, 48, 64`).
- **Sprite Proportions (inside 32×32):**
  - **Floor tiles:** Full `32×32` matte texture; 4 deterministic cosmetic variants per Sphere to break tiling repetition without visual noise.
  - **Wall tiles:** `32×32` top-down 3/4 liturgical block (`10px` upper cap + `22px` front face with mortar, niche, or relief) so walls read unambiguously as impassable mass.
  - **Characters & Humanoid Enemies:** `22–26px` tall, `14–20px` wide, grounded on a `1px` dark contact shadow at `y=29`. Heads occupy ~25–30% height for clear silhouette readability at `24px` scale.
  - **Bosses & Guardians:** `26–30px` tall, `20–26px` wide, distinct silhouette + octagonal seal base.
  - **Items:** `18–22px` centered silhouette with `1px` void outline so ground drops pop off floor tiles.
  - **UI & Status Iconography:** **16×16 pixel** crisp woodcut/alchemical glyphs (Masks, Eight Chains, statuses, 24 talent tree schools, 8 institutions, HUD actions).
  - **Portraits & Emblems:** **64×64 pixel** woodcut/engraving emblems for Title crest, Seven Spheres, Eight Institutions, Two Ways, Unwritten Door, Apotheosis, and Named Losses.

---

## 4. Typography & UI Spacing Hierarchy

- **Font Strategy:** Crisp legible default/monospace fallback with strict hierarchical scaling (`_fs(mult)` driven by `GameSettings.text_scale()`):
  - **Display / Screen Titles:** `2.0x–2.3x` base (`28–34px` at `1.0x`), Parchment Ivory or Witness Magenta, uppercase/letter-spaced header framing.
  - **Section / Card Headers:** `1.15x–1.3x` base, Tarnished Gold (`#b79555`).
  - **Body / Combat Log / Tooltips:** `1.0x` base (`15–16px` readable on phone and laptop), high-contrast Ivory (`#eee5d3`) and Dim Record (`#a89d8c`).
  - **Micro-Badges / Shortcut Hints:** `0.85x` base (`12–13px`), enclosed in pill borders.
- **Spacing & Touch Ergonomics:**
  - `8px` modular grid (`4px` tight gap, `8px` standard padding, `12px` card margin, `16px` panel inset).
  - Minimum touch target height: **`48px`** on mobile/touch mode (`40px` desktop), `48×48px` minimum D-pad cells, `>= 6px` separation between destructive and safe actions.
  - Safe-area margin helper reserves screen insets on notched mobile displays.
  - **Progressive Disclosure:** The main dungeon HUD displays vital state immediately (HP bar, Resource bar, Level, Sphere/Region, Subjugation meter, Mask/Risk, active Contract, visible hostile count, compact status chips), while full attribute tables, equipment comparison, Atlas, Threads, Institutions, and Codex live in single-tap/single-key overlays.

---

## 5. Lighting, Fog of War & Animation Conventions

- **Visibility States:**
  1. **Unexplored:** Pure `VOID` (`#080609`).
  2. **Explored, Out of FOV (Remembered):** Desaturated and darkened (`0.38` luminance; `0.55` in High Contrast). Dynamic actors are never shown in remembered fog; static terrain, stairs, and discovered features remain legible.
  3. **Visible (In FOV):** Full palette, with subtle radial distance falloff at the outer edge of `sight` radius so the light pool feels lantern-lit rather than harsh.
  4. **Optional Decorative Lighting (`settings.decorative_lighting`):** Subtle radial warm tallow-candle glow around player, hearths, altars, and solar glare tiles (`additive/alpha <= 0.14`—never obscures tile silhouettes).
- **Animation & Feedback Rules (M8.6):**
  - Snappy roguelike pacing: **60–140ms** for movement glides and melee slashes, **120–180ms** for projectiles, spell bursts, and floating combat numbers.
  - Input is **never blocked** by cosmetic animations; subsequent turns snap cleanly.
  - Zero continuous strobe or full-screen white flashes; flash intensity is capped and user-configurable (`0.0..1.0`), and `reduced_motion` disables shakes, particles, and camera offsets entirely.

---

## 6. Asset Naming & Provenance Conventions

- **Directory Layout:**
  - `assets/tiles/sphere_<1..7>_<name>.png` — 32×32 Sphere environmental atlases.
  - `assets/sprites/avatars.png` — 32×32 Origin bases, Calling garments, and Mask overlays.
  - `assets/sprites/monsters.png` — 32×32 enemy archetypes, 15 bosses, and elite badges.
  - `assets/sprites/npcs.png` — 32×32 recurring NPCs.
  - `assets/sprites/items.png` — 32×32 gear categories, relics, artifacts, and BUC/rarity frames.
  - `assets/sprites/icons.png` — 16×16 UI, status, school, institution, and chain icons.
  - `assets/portraits/emblems.png` — 64×64 woodcut emblems.
  - `assets/audio/sfx/*.ogg`, `assets/audio/ambience/*.ogg`, `assets/audio/music/*.ogg` — Offline Vorbis audio.
- **Provenance Manifest (`content/presentation/asset_provenance.json`):**
  Every asset records: `asset_id`, `path`, `source`, `author_or_method`, `license_status`, `approval_status` (`provisional_m8_asset`, `placeholder_liturgical_temp`, or `owner_approved`), `associated_entities`, and `modification_history`. No external music or artwork is ever claimed without verified rights.

---

## 7. Vertical-Slice Reference Treatment: Moon — The Ossuary Warrens

Before expanding to Spheres 2–7, the **Ossuary Warrens (Depth 1, Moon)** establishes the visual benchmark:

- **Floor & Masonry:** Cold charcoal-slate flagstones (`#1c1820`, `#241f29`) flecked with pale bone-dust mortar and hairline fractures; damp masonry walls (`#4c4654` cap, `#352f3b` face) inset with small skull-ossuary niches and faded chalk tally marks.
- **Atmosphere & Lighting:** Cool moonlight-silver (`#b8c4d0`) cast along stairs and shrines contrasted against dim warm tallow (`#b79555`) around altars and hearths.
- **Architecture & Props:** Descending stairs carved like a narrow spiral ledger-well lit in tarnished gold; the Unwritten Door sealed in black iron and blood-wax (`#a62639`); shallow cistern water in cold slate-blue (`#384c61`) with pale ripple highlights; ash embers glowing dull orange-amber in cracked grates.
- **Tactical Readability Check:** On the Warrens slate floor, an ivory/gold player sprite, blood-bracketed *warren rat* or *catalogued dead*, sage-diamond *NPC*, and gold *healing salve* separate instantly even at `24px` tile scale or with colorblind filtering enabled.
