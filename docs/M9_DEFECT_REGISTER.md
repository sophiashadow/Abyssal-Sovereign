# Milestone 9 Prioritized Defect Register (M9.0 Production Audit)

Audited at M8 completion commit `15a98d0` against M8 screenshots (`docs/screenshots/m8/`), exported APK (`build/android/abyssal-sovereign-debug.apk`), benchmark outputs (`tools/m8_perf_bench.gd`), audio/asset manifests, and source code.

## Severity Definitions
- **P0:** Data loss, crashes, progression blockers, or security/packaging leaks.
- **P1:** Major gameplay, usability, or layout failures.
- **P2:** Noticeable quality, polish, audio, or presentation defects.
- **P3:** Optional improvements and owner-gated external sign-offs.

---

## Active Register

| ID | Sev | Area | Finding & Evidence | Target | Status |
|---|---|---|---|---|---|
| **P0-1** | **P0** | Packaging / Security | `export_presets.cfg` uses `include_filter="*.json"` without excluding `balance/*` or `content/lore/*`. `unzip -l build/android/abyssal-sovereign-debug.apk` confirms 11 internal `assets/balance/*.json` files and `assets/content/lore/world_manifest.json` are bundled into exported builds. | M9.8 | Resolved (all 4 presets exclude `balance/*`, `docs/*`, `content/lore/*`, `release/*`, `tests/*`, `tools/*`, `*.md`; APK & archives verified leak-free) |
| **P1-1** | **P1** | UI / Modals | `src/ui/main.gd:1876` (`_show_atlas`) and `1937` (`_show_people`) insert wrapped `Label` nodes into `HBoxContainer` without `SIZE_EXPAND_FILL`, crushing text into a 1-character-wide vertical column (observed in `docs/screenshots/m8/desktop/23_atlas.png`). | M9.2 | Resolved |
| **P1-2** | **P1** | Mobile UX | In `docs/screenshots/m8/mobile_portrait/04_game.png`, `13_game_touch.png`, and `desktop/13_game_touch.png`, verbose HUD stats push action buttons and the 3×3 touch D-pad below the scroll fold, and default portrait tiles look small amid large margins. | M9.2 | Resolved (portrait dock + `Stats ▾` drawer) |
| **P1-3** | **P1** | Modals / Back | `docs/screenshots/m8/mobile_portrait/11_settings.png` overflows viewport height with `Done`/`Close` scrolled offscreen; `NOTIFICATION_WM_GO_BACK_REQUEST` misses `Screen.END` and `TITLE` sub-screens (`Settings`/`Codex`). | M9.2 | Resolved (sticky `[×]` header + internal scroll + Back routing) |
| **P1-4** | **P1** | Performance | `m8_perf_bench.gd` measured 100-frame tile lookup at `1587.41 ms` vs `142.46 ms` for glyphs (11× overhead) because `AssetRegistry.tile_region()` / `_region_entry()` rebuild strings and allocate Dictionaries/Rect2s per tile per frame. | M9.1 | Resolved (`230.21 ms`, 6.9× faster) |
| **P1-5** | **P1** | UI / Smoke | `docs/screenshots/m8/*/01_title.png` captured solid black frames due to frame-0 screenshot timing in `tools/ui_smoke.gd`; Title footer text still says `"M8 Incarnation"`. | M9.2 / M9.4 | Resolved (`01_title.png` fixed in M9.2; `v1.0.0-rc.1` footer in M9.4) |
| **P1-6** | **P1** | Narrative / UI | `src/ui/main.gd:966` reads `mdef.get("desc", "Guardian of the Seal.")` on Boss Sighting banners instead of `"description"` (all 15 bosses use `"description"`) and passes empty emblem `""` instead of `"boss_seal"`. | M9.4 | Resolved |
| **P2-1** | **P2** | Art / Lighting | `avatars.png`, `monsters.png`, `npcs.png`, `items.png`, and `emblems.png` rely on minimal geometric placeholders and repeated emblem templates; `MapView._draw_lighting_tile` draws a hard square 3×3 `draw_rect` around the player. | M9.1 | Resolved (`provisional_m9_asset` + radial lighting) |
| **P2-2** | **P2** | Game Feel | Missing explicit on-screen `Use` button, Aim Mode (`Next`/`Confirm`/`Cancel`), Look Mode (`Done`), and Auto (`Stop`) touch bars; NPC `Speak & ask counsel` closes the modal immediately; Inventory lacks inline `[▲]`/`[▼]`/`[✦]`/`[☠]` comparison tags. | M9.3 | Resolved |
| **P2-3** | **P2** | Narrative Copy | `difficulty.json` Exile description contains dev meta-text (`"every earlier version shipped with"`); `species.json` duplicates `Traits.describe()` verbatim; `_describe_choice()` repeats duplicate items instead of grouping (`2×`); `_show_end()` prints `"1 floors visited"` and `"Apoth 0"`; `narrative_frames.json` repeats `"damp"` twice on Sphere 1. | M9.4 | Resolved |
| **P2-4** | **P2** | Audio Mastering | `tools/gen_audio.py` generates 22.05 kHz `-q:a 1` audio without RMS normalization; `AudioManager.set_paused(false)` unmutes Master even when `vol_master <= 0.001`; Sphere ambience cuts abruptly rather than crossfading; 5 generated SFX (`discovery`, `identify`, `contract_sign`, `seal_break`, `ui_confirm`) are unwired. | M9.5 | Resolved (44.1kHz RMS-mastered, crossfade ambience, cooldowns, all 24 SFX wired) |
| **P2-5** | **P2** | Distribution | `README.md` still advertises `v0.5-dev`; `project.godot` and `export_presets.cfg` lack application/PWA/Android launcher icons and `1.0.0-rc.1` version metadata; no portable release packaging/checksum script exists. | M9.8 / M9.9 | Open |
| **P3-1** | **P3** | External Gates | Human playtest (`docs/PLAYTEST.md`), Windows runtime, Web IndexedDB persistence, physical Android device install/touch/suspend, owner release keystore, VENEFICA LUX soundtrack stems, and Canon promotion review remain `NOT_RUN` / owner-gated. | M9.7 / M9.10 | Tracked |
