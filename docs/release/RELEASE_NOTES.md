# Abyssal Sovereign — Release Notes (`v1.0.0-rc.1`)

**Milestone:** M9 — The Ascension Pass (`v1.0.0-rc.1`)  
**Engine:** Godot `4.7.2.stable` (`GL Compatibility`)  
**Save Compatibility:** `SAVE_VERSION := 12` (automatic migration intact for `v1`–`v12`)

---

## Highlights in `v1.0.0-rc.1`

### 1. Mobile-First UX & Responsive Presentation
- **Dedicated Portrait Touch Interface:** Fixed zero-scroll layout with compact top vital bar, collapsible `Stats ▾` drawer, ~70% map viewport, concise log strip, and fixed bottom dock (3×3 D-pad + 4-column action grid, reversible via **Left-Handed** mode).
- **Scrollable Sticky-Header Modals:** All overlays (`Bag`, `Build`, `Settings`, `Atlas`, `People`, `Threads`, `Codex`) keep `[×]` pinned at the top with internal scrolling on compact viewports, plus consistent Android Back / `Esc` navigation (including `End` screen and Title sub-screens).
- **Atlas & People Wrap Fix:** Fixed single-column text crushing in wrapped descriptions (`P1-1`).

### 2. Artistic & Atmospheric Polish
- **Upgraded Procedural Atlases:** Upgraded hero/calling silhouettes, `15` bespoke boss icons on octagonal seals, `18` institution-styled NPC sprites, `16` bespoke relics, `26` artifacts, `24` unique `64×64` woodcut institutional/thread emblems, and launcher/adaptive icon sets (`provisional_m9_asset` pending final external illustrations).
- **Radial Lantern Lighting & Caching:** Replaced square tile lighting with soft concentric radial lantern/hearth glow (`MapView`), and added `AssetRegistry` region/tile caching (`6.9×` faster 100-frame tile preparation in `m8_perf_bench.gd`).

### 3. Tactical Game Feel & Clarity
- **Contextual Highlights & Touch Mode Bars:** `Get`, `Use`, `Stairs`, `Build` (`[▲]`), `Rest` (when safe & wounded), and `Mask` accent dynamically based on live turn state; Aim Mode (`Next` / `Confirm` / `Cancel`), Look Mode (`Done Looking`), and Auto/Travel (`Stop`) surface directly on screen.
- **Streamlined Interactions:** Added inline `[?]` (unidentified), `[✦]` (equipped), `[☠]` (cursed), `[▲]` (upgrade), and `[▼]` (downgrade) inventory badges; seamless NPC counsel and multi-purchase merchant flow inside one modal; explicit confirmation before Forsaking a Contract; directional melee lunge animations (`VfxLayer`) with full **Reduced Motion** & **Instant Actions** support.

### 4. Narrative Refinement & Audio Mastering
- **Narrative Cleanups:** Fixed Boss Sighting banners to display full authored boss descriptions and seals (`P1-6`), cleaned Exile profile & origin copy, grouped starting gear stacks (`2× healing salve`), polished Sphere 1 phrasing, and logged open canon decisions in `docs/OWNER_CANON_LEDGER.md`.
- **44.1 kHz RMS-Mastered Offline Audio:** Upgraded all `47` audio assets to `44.1 kHz` with consistent RMS normalization (`1.1 MB` total), added seamless dual-deck Sphere ambience crossfading, fixed pause/unpause preserving `0%` Master mute, added `45 ms` SFX cooldown + subtle pitch/gain jitter, and wired all `24` SFX cues.

### 5. Clean Distribution & Security Hygiene (`P0-1` Fixed)
- Excluded internal development files (`balance/*`, `docs/*`, `content/lore/*`, `tests/*`, `tools/*`, `release/*`, `*.md`) from all four export presets (`Linux`, `Windows Desktop`, `Web`, `Android`).
- Wired application, Web PWA (`144`/`180`/`512`), and Android adaptive (`192`/`432`) icons plus `1.0.0-rc.1` version metadata (`tools/package_rc.sh`, `docs/INSTALL.md`, `SHA256SUMS.txt`).

---

## Known Release Candidate Caveats

The following gates are **explicitly open** prior to general `v1.0.0` public release:
1. **No Human Playtest Yet:** All gameplay data (`m9_rc1_validation`: `219/256` bot wins, `35` dead, `2` action-capped) reflects automated agents (`docs/PLAYTEST.md`).
2. **External Runtimes `NOT_RUN`:** Linux exports ran and passed smoke checks; Windows desktop execution, Web IndexedDB saves, and physical Android device installation/touch/suspend remain `NOT_RUN`.
3. **Provisional Art & Placeholder Music:** Sprite atlases (`provisional_m9_asset`) and 16 temporary liturgical music stems (`placeholder_liturgical_temp`) await owner-approved final assets; Android APK is debug-signed pending external owner keystore signing.
4. **Canon & Balance Sign-off:** Owner review pending on `docs/OWNER_CANON_LEDGER.md` and Depth 2 / difficulty profile tuning after human playtesting.
