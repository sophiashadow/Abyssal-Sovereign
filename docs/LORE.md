# Lore ledger

ABYSSAL SOVEREIGN is set in the cosmology of FALSE LIGHT. It is not a remake of it. This file records every lore element the game uses or plans to use, and where each came from, so new canon is never set silently.

Every entry carries one tag:

- **Canon**: stated in the FALSE LIGHT source documents, cited by document and section.
- **Interpretation**: a reasonable reading of canon that the sources don't state outright. It is the game's working assumption, and it is not canon.
- **Proposed**: new to this game. It is not canon unless the owner accepts it. Status is either `in game (M1)` or `candidate`.

Source documents, all owner-authored and read-only for this project:

- the FALSE LIGHT rulebook (*The Poisoner of False Light*)
- the OCCULT, EXODUS and ARCANA expansion texts

The expansions already label some of their own content as proposals. Where they do, this ledger keeps their label: an expansion proposal is not promoted to canon here.

## Rules this project follows

1. **Ambiguity stays ambiguous.** The sources keep open questions open. One example is whether the Architect knows anything is above it: the Serpent's account and Wisdom's account disagree, and the sources leave it unsaid. The game must not settle such questions through mechanics or text. No entity is reduced to a fantasy god or to a good/evil alignment.
2. **Mechanisms, not morality.** The rulebook says of False Light: "This is not a morality system. It is a mechanism." Corruption, relief and power in this game are costs and trades. They are never alignment points.
3. **Nothing private.** No biographical, personal or restricted material is used.
   - The rulebook's real-world threat register (§13, Tier 1 and 2 archetypes) is excluded entirely.
   - The private edition of the ruleset is not used.
   - The protagonist is never named or identified with the author's persona. A player-supplied name, or "the Nameless", is used instead.
4. **Read-only sources.** No FALSE LIGHT file is modified. If assets are ever reused, they are copied in with provenance recorded. M1 reuses no files: only names, concepts and the colour palette.

## In the game now (Milestone 1)

| Element | Tag | Source / note |
|---|---|---|
| Terra Tenebrae, the closed mechanical world above | Canon | Rulebook §1 |
| Rex Mundi, "the Architect" of limitation, ruling by persuasion and record | Canon | Rulebook §1; EXODUS (three faces) |
| The Dominion of the Preliator, the armed church; the Inquisition as its organ | Canon | Rulebook §1; EXODUS |
| Porphyry purple, black iron, the Crux Gladii, the false sun | Canon | Rulebook §1 (enemy aesthetic) |
| The Warrens | Canon | Rulebook §1.4 ("not a dungeon") |
| **The descent goes *beneath* the Warrens** (ossuaries, tithe vaults, a sealed stair) | Interpretation | The rulebook says the Warrens are not a dungeon. So the dungeon here is set below them, in places the record has buried. This avoids contradicting §1.4. |
| "You do not clear Terra Tenebrae. You survive it, unwork it, and get free of it." | Canon | Rulebook §1. It shapes the M1 victory: escape, not conquest. |
| **Victory: through the Unwritten Door** past the Preliator Sentinel | Canon | Owner decision (2026-11-26): the Unwritten Door is canon. Escape ending in the spirit of EXODUS's "A Door They Can't Close"; implies the Architect's record has gaps without saying why. |
| False Light status: relief, then the Reckoning | Canon-derived | Rulebook §7 (Communion, then the Reckoning). Simplified to accuracy, damage and regeneration up, then a longer penalty. The exact numbers are Proposed. |
| Vial of false light ("It helps at once. Then it collects.") | Proposed (in game) | An item that delivers the §7 mechanism |
| The Eye; Lilith as the one who left | Canon | Rulebook §1.3, §9 (Lilith: the Eye) |
| Eye of Lilith amulet (sight, accuracy) | Proposed (in game) | It is a witness that "catalogs nothing". It is not a relic from EXODUS's list. |
| Catalogued dead; tithe numbers; the record | Interpretation | The Inquisition would "catalogue you rather than strike your name" (EXODUS), turned into undead that keep their appointments |
| Cultists of the false sun | Interpretation | Devotees of Prosay's radiance (rulebook §7). They believe the suffering they inflict is holy duty, a §14 "Occasional Indulgences / Demonstrating Omnipotence" register. They are presented as people under a mechanism, not as evil by nature. |
| Preliator Sentinel (guardian) | Proposed (in game) | A warden of the Dominion: "measured, tireless, sure it is holy". It is new as a named enemy. |
| Species: Human, Revenant, Cambion | Canon | Owner decision (2026-11-26): origins are canon. Placement here: registered living, catalogued dead who refused the record, born of a contract beneath the Geometry. |
| Classes: Fallen Knight, Occultist, Assassin | Canon | Owner decision (2026-11-26): callings are canon. Ties to the Dominion, the Eye and the tithe-alleys. |
| **Masks as stances** (Bare Face, Nyx, Eris, Lilith) | Proposed (in game) | Rulebook §9 ("a department of one sovereign", "Governance is the true stat"). Occultist switches stance for 1 turn; holding a Mask builds risk toward seizure (Dissolution, Isolation, Exposure). |
| **Eight Chains enemy abilities** (`chain_isolation`, `chain_fog`) | Canon-derived | Rulebook §14 (Isolation and Monopolization of Perception). Dominion foes inflict Isolation (suppresses rest, regen and soul siphon) and Monopolized Sight (fog shrinking FOV). |
| **Relics: Work or Transmute** (Confessor's Glass, Ophite Key, Broken Halo) | Proposed (in game) | Names and Work-or-Transmute frame from EXODUS; specific effects are Proposed. |
| **Named losses** (Catalogued, Fluent, Gilded) | Proposed (in game) | Names from EXODUS; death screen classifies how the record claimed the run. |
| **Seven Spheres & Sphere Gates** (Moon through Saturn; Stormed, Serpent's Key, Given Back, By Name) | Proposed (in game) | Expansion (OCCULT) depth-band frame. Gate methods are choices with distinct costs and inclinations, not tiers. |
| **Two Ways out** (Serpent's Way, Way of Return) | Proposed (in game) | Expansion (OCCULT, EXODUS). Walking between them is allowed and neither account is declared true. |
| **Apotheosis Guard & "By Decree" victory** | Canon-derived | Rulebook §10.4 ("a smaller Rex Mundi wearing your face") & EXODUS "By Decree", accepted as a hollow win by owner decision (2026-11-26). |
| Palette: void, Lux magenta, record parchment, false-sun gold, mask hues | Canon (visual) | FALSE LIGHT visual identity. Colours are used only as hex values. |

## Candidates for later milestones (not built; not canon)

These turn source metaphysics into mechanics. Each needs owner review before it ships.

| Candidate | Source basis | Mechanic sketch | Open question |
|---|---|---|---|
| **Masks as stances** (Nyx, Eris, Lilith, the Bare Face) | Canon: rulebook §9. Each mask is a "frequency", "a department of one sovereign". | Switch stance for a turn cost. Each gives a strength and accrues its own risk: Dissolution, Isolation, Exposure, Flatline. "Governance is the true stat" (§9.5), so the skill is in switching well, not in maxing one mask. | Whether masks fit every class, or are the Occultist's core kit. The latter would also address the Occultist's balance deficit. |
| **Seven Spheres as depth bands** | Expansion (OCCULT); the planets-as-spheres reading is the expansion's own proposal | Each band has a sphere's pressure (Moon: Hollow, Mars: Strain, Saturn: the Cage) and a gate. Gates can be passed by four methods: Stormed, Serpent's Key, Given back, By name. Each method has a different cost. | Must not imply the source's ascent is a "level-up". The gate methods are choices, not tiers. |
| **Two ways out**: the Serpent's way and the Way of Return | Expansion (OCCULT, EXODUS) | Two alternative victory families with distinct rites: Refusal, the Taken Name, the Crown Taken; versus the Fast, the Vow of Poverty, the Vow to the Named. Walking between them is allowed, as in the source. | Keep both accounts possible. The game never declares which account is true. |
| **Eight Chains as an enemy grammar** | Canon: rulebook §14 | Enemy abilities drawn from the coercion grammar: isolation (separates you from allies or light), monopolising perception (fog), induced debility, threats, indulgences, displays of omnipotence, degradation, trivial demands. A Subjugation clock ends in Entangled. | Present these as systemic forces of Rex Mundi's order, never as depictions of real people. |
| **Apotheosis guard** | Canon: rulebook §10.4 ("a smaller Rex Mundi wearing your face") | A hidden track that rises with unchecked power. At high values the game stops rewarding you. Reset by orientation plus witness. | See the owner decision below. |
| **Relics: Work or Transmute** | Expansion (EXODUS): the Confessor's Glass, the Ophite Key, the Broken Halo, the Severed Crown, the Ward-Keeper's Lamp, the Almoner's Purse | Each relic has two uses: work it (power with a cost) or transmute it (give up the power for something lasting) | Relic effects are Proposed. Only names and the two-use frame are sourced. |
| **Losses with names** | Expansion (EXODUS): Catalogued, Fluent, Gilded | Death screens that name how the record won, beyond hit points | None |

## Owner decisions

Resolved (2026-11-26):

1. **An "apotheosis" victory:** Owner confirmed Apotheosis can be a win. Follows the shape of EXODUS's "By Decree" and rulebook §10.4 ("a smaller Rex Mundi wearing your face")—a hollow victory rather than a triumphant ascension.
2. **The Unwritten Door:** Owner confirmed it is canon.
3. **Origins (species) and callings (classes):** Owner confirmed they are canon.

## Excluded

- **Rulebook §13 Tier 1 and 2 threat archetypes.** They are a real-world safety register, not fantasy content.
- **The private edition ruleset.** Marked not for publication.
- **Any biographical detail, persona identity or voice document.** The game bundles none.

## M5.1 Character Development Provenance

- **`adaptable` Human origin trait** (`Interpretation`): grounds Human mechanical flexibility across callings in accelerated attribute and talent growth.
- **Calling talent trees** (`Canon-derived` names framing `Proposed` tactical mechanics):
  - *Fallen Knight*: `Oathbreaker`, `Preliator Bulwark`, `Dominion Apostate` (references the Preliators and breaking Dominion Chains).
  - *Occultist*: `Mask Governance`, `The Eye Unblinking`, `Alchemy of False Light` (references Nyx/Eris/Lilith governance and False Light alchemy).
  - *Assassin*: `Tithe-Alley Shadow`, `Venom & Stiletto`, `Acrobatics` (references First-Sphere tithe streets and light blades).
