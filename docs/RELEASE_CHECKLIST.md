# Abyssal Sovereign (`v1.0.0-rc.1`) — Release Candidate Checklist

## 1. Automated Engineering & Distribution Gates (Verified & Published on `v1.0.0-rc.1`)

- [x] **M9.0 Production Audit:** `docs/M9_SPEC.md` and `docs/M9_DEFECT_REGISTER.md` authored against M8 baseline (`15a98d0`).
- [x] **P0-1 Packaging Leak Resolved:** `export_presets.cfg` excludes `balance/*,build/*,docs/*,release/*,test-results/*,tests/*,tools/*,content/lore/*,*.md` across Linux, Windows Desktop, Web, and Android; verified zero internal leaks in APK and packages.
- [x] **P1-1 Atlas/People Text Wrap Fixed:** Wrapped descriptions use `SIZE_EXPAND_FILL` (`src/ui/main.gd`).
- [x] **P1-2 Mobile-First Portrait & Touch HUD:** Fixed zero-scroll portrait layout (`Stats ▾` collapsible drawer, ~70% map viewport, 3×3 D-pad + 4-column action grid, left-handed flip) and touch-landscape layout verified.
- [x] **P1-3 Sticky-Header Modals & Back Routing:** Internal scrolling with sticky `[×]`, plus Android Back / `Esc` routing across overlays, Aim/Look/Auto modes, Title sub-screens, and End screen.
- [x] **P1-4 AssetRegistry Cache Performance:** 100-frame tile preparation improved from `1587.41 ms` (M8) to `236.88 ms` (M9.10) — ~6.7× speedup.
- [x] **P1-5 Title Rendering & Version Footer:** Frame-0 capture timing fixed; Title footer displays `v1.0.0-rc.1`.
- [x] **P1-6 Boss Sighting Banners:** Reads `mdef.description` and renders `"boss_seal"` woodcut emblem.
- [x] **M9.1 Artistic Upgrades:** Upgraded 32×32 tilesets, silhouettes, 15 bespoke boss seals, 18 NPCs, 16 relics, 26 artifacts, 24 unique woodcut emblems, 7 launcher/adaptive icons, 4 comparison sheets, `docs/ASSET_BACKLOG.md`, and soft radial lantern lighting.
- [x] **M9.3 Tactical Game Feel:** Dynamic `Get`/`Use`/`Stairs`/`Build`/`Rest`/`Mask` highlights, Aim/Look/Auto touch mode bars, seamless NPC counsel & multi-buy merchant modal, Forsake-contract confirmation, `[?]/[✦]/[☠]/[▲]/[▼]` inventory badges, and directional melee lunges (`VfxLayer`).
- [x] **M9.5 Audio Mastering:** All 47 assets generated at `44.1 kHz` with RMS mastering (`1.1 MB` total), dual-deck Sphere ambience crossfader, `45 ms` SFX cooldown, `set_paused()` unmute-at-zero fix, Dummy-driver playback guard (0 exit leaks), and all 24 SFX cues wired.
- [x] **M9.6 Gameplay Integrity & Fresh Validation:** `384` dev runs (`m9dev_prof_*` + `m9dev_matrix`) and `256` held-out validation runs (`salt=m9_rc1_validation`: `219/256` won `85.5%`, `35` dead, `2` capped; `86/86` monsters, `28/28` floors, `24/24` threads, `1,534` Relic Work, `246` Transmute).
- [x] **M9.8/M9.9 Packaging & Docs:** `project.godot` version & icon, `tools/package_rc.sh`, `tools/verify.sh`, `README.md`, `docs/INSTALL.md`, `docs/PLAYTEST.md`, `docs/release/{PRODUCT_KIT,RELEASE_NOTES,PRIVACY,CREDITS_AND_LICENSES}.md`, `SHA256SUMS.txt` verified.
- [x] **Multi-Viewport UI Smoke & Linux Binary Launch:** `tools/ui_smoke.gd` passed `39 steps, 0 failures` (0 `ERROR:`, 0 exit leaks) at `1280x720`, `2340x1080`, and `720x1280`; Linux portable binary smoke passed cleanly.
- [x] **Zero Private Path Leaks:** Verified no personal home-directory paths exist in tracked public/release documentation.
- [x] **Pushed & Published (`v1.0.0-rc.1` Pre-Release):** Pushed `main` to `origin/main`, pushed annotated tag `v1.0.0-rc.1`, and published the GitHub Pre-Release with all four platform archives + `SHA256SUMS.txt`.

---

## 2. Human, Hardware & Owner Sign-Off Gates (Open — Required Before Final `v1.0.0` Release)

- [ ] **Human Playtest Execution (`docs/PLAYTEST.md`):** Collect external human feedback across accessibility modes, touch portrait/landscape, desktop keyboard/mouse, difficulty profiles (Initiate–Sovereign), Depth 2 Vault Enumerator pressure, and Occultist/Ophite Binder early frailty.
- [ ] **Windows Runtime Verification (`NOT_RUN`):** Execute `abyssal-sovereign.exe` on physical Windows `x86_64`, verifying GL Compatibility rendering, audio buses, and `%APPDATA%` save persistence/recovery.
- [ ] **Web Browser & PWA Verification (`NOT_RUN`):** Serve `abyssal-sovereign-v1.0.0-rc.1-web.zip` over HTTP/HTTPS, verify Chromium/Firefox WebGL2 playback, touch emulation, and IndexedDB save persistence across reloads.
- [ ] **Android Device Verification (`NOT_RUN`):** Install `abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` on physical Android hardware; verify adaptive launcher icons, display cutout/safe areas, back button routing, audio focus, and OS pause/resume autosave.
- [ ] **Release Android Keystore Signing (External):** Create release keystore outside the repo (`docs/INSTALL.md`) and verify signed release APK with `apksigner verify --verbose`.
- [ ] **Original VENEFICA LUX Music Stems:** Replace the 16 `placeholder_liturgical_temp` music stems in `content/presentation/soundtrack_manifest.json` with owner-approved recordings and provenance updates.
- [ ] **Commissioned Key Art Replacement:** Replace `provisional_m9_asset` sprites prioritized in `docs/ASSET_BACKLOG.md` (title crest, bosses, portraits, emblems) if commissioned for `1.0`.
- [ ] **Owner Canon & Legal Sign-Off:** Review open lore items in `docs/OWNER_CANON_LEDGER.md` (`Proposed` M6 entities, difficulty profile names) and approve distribution channels, pricing/license terms, and git push/tag/release authorization.
