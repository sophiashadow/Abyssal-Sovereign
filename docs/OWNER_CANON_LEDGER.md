# Owner Canon Review Ledger

**Purpose:** `AGENTS.md` and `docs/LORE.md` mandate that no `Proposed` entity or mythological interpretation be silently promoted to shared `FALSE LIGHT` **Canon** without explicit owner authorization, and that deliberate theological ambiguity remain unsettled. This ledger lists every `Proposed` or provisional item currently in Abyssal Sovereign (`v1.0.0-rc.1`) for owner review.

---

## 1. Deliberate Ambiguities Preserved (No Decision Requested)
- Whether Rex Mundi ("the Architect") knows anything exists above it (`Serpent's account` vs. `Wisdom's account` vs. `the Unsaid`).
- Whether the *Unwritten Door* opens into genuine exterior freedom or another uncatalogued layer of geometry.
- Whether the *Way of Return* and *The Serpent's Way* ultimately converge or exclude one another; both remain playable without declaring either solely true.

---

## 2. Proposed Game Elements Requiring Owner Canon Verdict

| Category | Count | Items / Scope | Current Tag | Owner Decision Needed |
|---|---:|---|---|---|
| **M6.3 Origins** | 5 | `ashborn` (Ash-Marked), `veilkin` (Veil-Touched), `ironbound_ward` (Iron-Vowed), `unrecorded` (Unrecorded), `penitent` (Debt-Sworn) | `Proposed` | Accept as `Canon` / keep game-local `Proposed` / rename |
| **M6.3 Callings** | 5 | `preliator_warden` (Bastion Warden), `tithe_marksman` (Tithe Arbalester), `rite_weaver` (Rite Cantor), `false_light_alchemist` (Seam Alchemist), `ophite_binder` (Ophite Binder) | `Proposed` | Accept as `Canon` / keep game-local `Proposed` / rename |
| **M6.1 Regional Sub-Floors** | 21 | `day_house_cellars`, `back_courts_undercroft`, `shut_chapel_crypt`, `tithe_road_tunnels`, `unrecorded_market_seams`, `archive_stair_annex`, `hidden_assembly_catacomb`, `processional_underway`, `sun_house_furnaces`, `closed_stacks_vault`, `censer_foundry`, `velvet_ossuary`, `gilded_cloister`, `audit_cisterns`, `preliator_garrison`, `seal_foundry_deep`, `debts_cathedral`, `ophite_seam_hollow`, `unwritten_margin`, `cage_oubliette`, `witness_hermitage` | `Canon-derived` / `Proposed` | Confirm underground placement beneath PR #300 districts (`docs/LORE.md` §M6.1) |
| **M6.2 Named Bosses & Bestiary** | 15 bosses / 76 archetypes | 12 M6.2 regional bosses (`alley_rat_matriarch`, `chapel_penitent_warden`, `archivist_severin`, `master_smelter_prosay`, `cantor_helios_prime`, `marshal_krell`, `binder_malakor`, `commander_voss`, `decreer_octavius`, `forge_warden_cyrus`, `jailer_of_the_seventh`, plus M4/M5 `vault_enumerator`, `choir_cantor_prime`, `iron_auditor`, `preliator_sentinel`) | `Proposed` | Confirm names & roles remain game-local or promote selected bosses |
| **M6.4 Relics & Unique Artifacts** | 10 relics / 22 artifacts | 10 Proposed relics (*Penitent's Brass Scourge* .. *Pocket Mirror of the Eye*) + 22 Proposed artifacts (including PR #300-named gear like *Stitcher's Iron Awl*, *Hesper's Procession Crossbow*, *Mirande's Silent Pendant*) | `Proposed` | Confirm PR #300 character relic bindings (`content/lore/world_manifest.json`) |
| **M6.5 People & Institutions** | 18 NPCs / 8 factions | 12 PR #300 characters (*Uc*..*Odo*) + 6 underground characters (*Sister Vesper*..*Warden Tomas*); 5 PR #300 institutions + 3 subterranean institutions (*Day-House Almoners*, *Mute Cantors*, *Witnesses of the Seam*) | `Proposed` | Confirm character voices, two-pole splits, and whether PR #300 entities promote |
| **M6.6 World Threads** | 24 | Procedural multi-stage quest threads (`the_unrecorded_tally` .. `clean_flagstones_at_saturn`) | `Proposed` | Confirm tone and non-moralizing outcomes |
| **M7.8 Descent Profiles** | 4 | `Initiate`, `Exile`, `Adversary`, `Sovereign` (`content/core/difficulty.json`) | `Provisional` | Finalize profile names and parameter balance after human playtest |
| **M8.9 Presentation Frames** | 12 frames | `content/presentation/narrative_frames.json` (`frame.*` loc keys) | `Canon-derived` | Confirm banner prose preserves ambiguity |
| **M8.8 Soundtrack Contexts** | 16 titles | `content/presentation/soundtrack_manifest.json` (`Litany of the Unwritten Door`, etc.) | `placeholder_liturgical_temp` | Approve titles / supply VENEFICA LUX studio recordings |

---

## 3. Excluded Material Audit (Verified Absent)
Per `docs/LORE.md`:
- FALSE LIGHT Rulebook §13 Tier 1 & Tier 2 real-world threat register: **Excluded**.
- Private edition ruleset, persona documents, biographical details, and voice files: **Excluded**.
- Exported builds (`export_presets.cfg`) exclude `content/lore/world_manifest.json`, `balance/*`, `docs/*`, `tests/*`, and `tools/*`.
