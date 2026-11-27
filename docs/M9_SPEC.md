# Milestone 9 Specification — The Ascension Pass (`v1.0.0-rc.1`)

**Target Release Candidate:** `v1.0.0-rc.1` (pending owner authorization)  
**Reference Checkpoint:** M8 completion commit `15a98d0`  
**Theme:** *From Incarnation to Sovereignty — production quality, artistic distinction, mobile-first ergonomics, narrative coherence, audio mastering, and distribution readiness.*

---

## 1. Mission & Non-Negotiable Baseline

M9 transforms the M8 graphical alpha into a polished, independently distributable release candidate worthy of comparison with established traditional roguelikes without indiscriminate content expansion.

### Preserved Baseline
- **8 Origins** and **8 Callings** (`64` pairs)
- **104 Talents** across **24 Talent Trees**
- **28 Floors** across **Seven Spheres** (7 spine + 21 regional sub-floors)
- **86 Monster Entries** (`76` archetypes + `15` named bosses/guardians)
- **165 Base Items**, **46 Affixes**, **12 Equipment Sets**, **26 Artifacts**, **16 Relics**
- **18 Recurring NPCs**, **8 Two-Minded Institutions**, **24 Narrative Threads**
- **4 Descent Profiles** (`Initiate`, `Exile`, `Adversary`, `Sovereign`)
- **Dual Rendering** (`Tiles 32×32` and `Classic Glyph`), **13 Graphical Atlases**, **47 Audio Assets**
- **Save Compatibility:** `World.SAVE_VERSION := 12`, backward-compatible v1–v12 migrations, strict permadeath
- **Strict Layer Isolation:** `src/core/`, `src/content/`, `src/gen/`, `src/sim/`, and `src/persistence/` stay free of `Node`, input, rendering, and frame-time dependencies

### Boundaries & Operating Rules
1. **Zero indiscriminate content expansion** or unapproved major mechanics.
2. **Offline & private by design:** No mandatory accounts, ads, telemetry, analytics, subscriptions, or cloud dependencies.
3. **Asset & provenance integrity:** Never bundle unauthorized music/art, private paths, credentials, keystores, or unpublished source material. Keep placeholder liturgical music honestly tagged `placeholder_liturgical_temp` until VENEFICA LUX owner stems arrive.
4. **Honest verification:** Never fabricate human playtesting, Windows runtime, Web persistence, physical Android hardware, or legal/licensing sign-off.
5. **No unauthorized distribution:** Prepare packages locally without pushing, merging, tagging, or publishing.

---

## 2. Submilestone Architecture (M9.0–M9.10)

| Submilestone | Objective | Key Deliverables & Verification |
|---|---|---|
| **M9.0** | Production Audit | `docs/M9_SPEC.md`, prioritized `docs/M9_DEFECT_REGISTER.md` (P0–P3) |
| **M9.1** | Artistic Mastery | Elevated shaded 32×32 sprites/tiles/bosses/relics, 24 bespoke 64×64 woodcut emblems, smooth radial lighting, `AssetRegistry` lookup caching, app icons, M8-vs-M9 comparison sheets, `docs/ASSET_BACKLOG.md` |
| **M9.2** | Mobile-First Experience | Zero-scroll portrait HUD + fixed touch dock, collapsible stats, sticky-header bounded modals, fixed `HBoxContainer` label wrapping, complete Back/Esc handling, updated `ui_smoke.gd` bounds checks |
| **M9.3** | Interaction & Game Feel | Context-sensitive action highlights, explicit `Use` button, Aim/Look/Auto touch mode bars, seamless NPC/merchant modal flow, inventory comparison badges, melee lunge + outlined popups |
| **M9.4** | Narrative & Atmospheric Polish | Boss banner `description` + `boss_seal` fix, deduplicated origin/calling copy, grouped starting gear, `v1.0.0-rc.1` footer, pluralized End summary, `docs/OWNER_CANON_LEDGER.md` |
| **M9.5** | Soundtrack & Audio Mastering | 44.1 kHz RMS-normalized/peak-limited mastering (`tools/gen_audio.py`), 8s ambience + 12s liturgical loops, `set_paused()` mute fix, dual-deck ambience crossfade, SFX cooldowns, wired 5 unused SFX |
| **M9.6** | Final Gameplay Integrity | Fresh dev-salt (`m9dev_*`) audits + fresh claimed validation soak (`m9_rc1_validation`), `balance/CHANGES.md`, `DESIGN.md` |
| **M9.7** | Human Playtest & Accessibility Gate | External playtest package in `docs/PLAYTEST.md` (install, controls, guidance, bug template, 9-axis questionnaire; zero fabricated results) |
| **M9.8** | Distribution Architecture | Clean `export_presets.cfg` exclusions (no `balance/`, `content/lore/`, `docs/`), `project.godot` version & icons, `tools/package_rc.sh`, `docs/INSTALL.md`, portable archives + `SHA256SUMS.txt` |
| **M9.9** | Product Identity & Release Materials | Updated `README.md`, `docs/release/{PRODUCT_KIT,RELEASE_NOTES,PRIVACY,CREDITS_AND_LICENSES}.md` |
| **M9.10** | Release Candidate Gate | Full test suite, `m8_smoke.gd`, 3-viewport RC1 screenshots, `m8_perf_bench.gd`, package leak audit, `docs/M9_REPORT.md`, `docs/RELEASE_CHECKLIST.md`, updated `ROADMAP.md` & `docs/HANDOFF.md` |

---

## 3. Release Candidate Acceptance Criteria

Abyssal Sovereign (`v1.0.0-rc.1`) is verified as an engineering release candidate when all automated checks pass and zero known P0 or engineering-resolvable P1 defects remain. Final public release additionally requires explicit owner sign-off on:
1. Graphical presentation & art direction approval.
2. Physical hardware playtesting on Android, Windows, and Web IndexedDB.
3. Actual human playtest rounds (`docs/PLAYTEST.md`).
4. Owner-controlled external Android release keystore signing.
5. Authorization / swap of VENEFICA LUX soundtrack stems (`content/presentation/soundtrack_manifest.json`) and final Canon promotion review (`docs/OWNER_CANON_LEDGER.md`).
6. Explicit owner authorization to publish or distribute.
