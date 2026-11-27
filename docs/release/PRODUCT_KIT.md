# Abyssal Sovereign (`v1.0.0-rc.1`) — Product & Press Kit

## Tagline
**Descend the Seven Spheres. Bind the Seals. Pay the Cost of Illumination.**

## Elevator Pitch
**Abyssal Sovereign** is an original turn-based traditional roguelike crafted in Godot 4.7.2. Beneath the fallen city of Terra Tenebrae, players choose from 8 Origins and 8 Callings (`64` pairings), master `104` talents and `16` interactive Relics, sign perilous occult Contracts, and descend `28` procedural floors across Seven Planetary Spheres — playable live in either pixel-art **Tiles** mode or classic **Glyph** mode, completely offline with permadeath.

## Overview
- **Genre:** Turn-based Traditional Roguelike / Dark Occult Fantasy
- **Version:** `v1.0.0-rc.1` (Release Candidate)
- **Platforms:** Linux (`x86_64`), Windows (`x86_64`), Android (`ARMv7`/`ARM64`), Web (`HTML5`/`PWA`)
- **Distribution Model:** Standalone offline packages; zero DRM, zero accounts, zero analytics, zero ads, zero IAP.

## Feature Highlights
- **True Deterministic Simulation:** Turn-based grid tactics, seeded generation, `SAVE_VERSION := 12` with `v1`–`v12` save compatibility, and strict separation of rules from UI.
- **Deep Archetype Variety:** `8` Origins, `8` Callings, `104` talents across `24` trees, plus dynamic Veil/Mask stances under False Light pressure.
- **Seven Distinct Spheres:** Moon, Mercury, Venus, Sun, Mars, Jupiter, and Saturn — each with distinct visual tilesets, ambient soundscapes, elemental hazards, side branches, and Sphere bosses (`15` bosses/guardians across `86` monsters).
- **Tactical Equipment & Relics:** `165` base items, `46` affixes, `12` sets, `26` named artifacts, inline `[▲]/[▼]/[?]/[☠]` comparison indicators, and `16` Relics supporting repeatable Work and irreversible Transmutation.
- **Meaningful Consequences:** `18` NPCs, `8` competing institutions, `24` narrative threads, binding Contracts with explicit penalties, and four distinct Victory paths.
- **Desktop & Mobile-First Design:** Purpose-built portrait touch layout (collapsible `Stats ▾` drawer, 3×3 D-pad, contextual action highlights, Aim/Look/Auto touch bars, left-handed flip, Android Back routing) alongside full Vi-key/Arrow/Numpad/Mouse desktop controls.
- **Accessibility First:** Real-time Tiles <-> Glyph toggle, colorblind palettes (`Deutan/Protan`, `Tritan`), `High Contrast`, text & tile scaling, camera zoom, `Reduced Motion`, `Instant Actions`, optional narrative framing banners, and full sound-off playability across 6 volume buses.

## Packaged Sizes (Measured at `v1.0.0-rc.1`) & System Guidance

- **Measured RC Package Sizes:**
  - Linux (`x86_64` portable `.tar.gz`): ~29 MB
  - Windows (`x86_64` portable `.zip`): ~38 MB
  - Web (`.zip`): ~11 MB
  - Android (`debug .apk`): ~57 MB
- **Minimum Runtime Requirements (Architecture Estimate — external Windows/Android/Web runtimes `NOT_RUN`):**
  - OpenGL ES 3.0 / GL Compatibility GPU or WebGL2 browser
  - ~150 MB free disk storage after extraction; ~512 MB available RAM

## Visual Showcase (`docs/screenshots/m9/`)

Captured via automated `tools/ui_smoke.gd` at Desktop (`1280x720`), Mobile Landscape (`2340x1080`), and Mobile Portrait (`720x1280`):
- `docs/screenshots/m9/comparison/` — Before/After M8 -> M9 sprite & boss comparison sheets (`sheet_1_terrain_env.png` through `sheet_4_lighting_icons.png`)
- `01_title.png` — Main Title & Descent backdrop
- `04_game.png` — In-game Tiles exploration & radial lantern glow
- `13_game_touch.png` — Touch D-pad, mode highlights, and collapsible HUD
- `23_atlas.png` — Seven Spheres Atlas with woodcut institutional emblems
- `38_death.png` — Named loss / Run summary overlay

## Content Advisory
Contains stylized dark-occult and liturgical themes, textual depictions of violence/penance, permanent character death (save deletion on run end), and configurable screen flash / shake (both adjustable down to `0.0` / off in Settings). Contains zero microtransactions, zero loot boxes, and zero online chat.
