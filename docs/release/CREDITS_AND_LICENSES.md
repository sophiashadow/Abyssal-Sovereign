# Abyssal Sovereign — Credits, Licenses & Asset Provenance (`v1.0.0-rc.1`)

## Game Design, Simulation & Engineering
- **Project:** *Abyssal Sovereign* (Original Traditional Roguelike set beneath Terra Tenebrae)
- **Repository Content & Source:** All simulation logic (`src/core/`, `src/content/`, `src/gen/`, `src/sim/`, `src/persistence/`), UI (`src/ui/`), narrative copy (`content/presentation/`, `content/core/`), and build/verification generators (`tools/`) are original to this project unless noted below.

## Engine & Third-Party Software Notices

### Godot Engine (`4.7.2.stable`)
Abyssal Sovereign is built with **Godot Engine** (GL Compatibility renderer), distributed under the **MIT License**:

> Copyright (c) 2014-present Godot Engine contributors.  
> Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.  
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:  
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.  
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Additional third-party components bundled within Godot runtime export templates retain their respective permissive licenses as documented upstream by Godot Engine (`COPYRIGHT.txt`).

## Visual & Audio Asset Provenance
No third-party copyrighted artwork, fonts, sound effects, or music recordings were imported into this release candidate.

| Asset Class | Current Provenance Tag | Authoring Method | Release Status |
|---|---|---|---|
| **Sprite Atlases & Icons (`13` atlases, `24` woodcut emblems, `7` launcher icons)** | `provisional_m9_asset` | Deterministic procedural generation via `tools/gen_sprites.py` (Python + Pillow + NumPy) | Upgraded for RC1 readability; commissioned replacement targets documented in `docs/ASSET_BACKLOG.md` |
| **Combat, Interface & Narrative SFX (`24` `.ogg` files)** | `provisional_m9_asset` | Procedural synthesis & 44.1 kHz RMS mastering via `tools/gen_audio.py` + `ffmpeg` | Active RC1 audio (`content/presentation/soundtrack_manifest.json`) |
| **Sphere Ambience Loops (`7` `.ogg` loops)** | `provisional_m9_asset` | Procedural 8s seamless noise/harmonic bed synthesis + circular mastering via `tools/gen_audio.py` | Active RC1 audio (`content/presentation/soundtrack_manifest.json`) |
| **Music Stems (`16` `.ogg` context stems)** | `placeholder_liturgical_temp` | Procedural 12s modal harmonic stems mastered at `-19 dBFS` RMS | Temporary placeholders awaiting owner-approved original VENEFICA LUX recordings (`soundtrack_manifest.json`) |

All audio, image, and metadata contracts are machine-verified by `tests/test_m8_assets.gd`, `tests/test_m8_audio.gd`, and `docs/ASSET_REGISTRY.md`.
