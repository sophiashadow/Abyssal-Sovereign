# Roadmap

## Milestone 0: foundations (done 2026-11-26)

Project, layering, content schema and validator, seeded RNG, test runner, and docs.

## Milestone 1: playable vertical slice (done 2026-11-26, Linux)

Everything in the M1 brief is implemented. The automated evidence is the headless suite, the soak and the UI smoke. All of it was run on Linux in a container under Xvfb. No human playtest has happened yet.

### Known defects and limits

- **Occultist balance:** weakest calling. Held-out bot win rate is 13%, against 60% for the Knight. Fix it with a kit (see M2), not stats.
- **Monster pursuit:** awake monsters always know where the player is, so there is no losing pursuers. Add last-known-position tracking.
- **Ranged play:** there are no ranged attacks, spells or doors (other than the sealed one), and there is no item identification.
- **Saves:** no save migration code yet. Only v1 exists.
- **Platforms:** no export presets and no builds for any platform. Android, Windows and Web are untested.
- **Typography and accessibility:** the glyph font is the engine default (proportional, centred per cell). A dedicated monospace font needs a license check first. There is no colour-blind palette option and no screen-reader support.
- **Starting position:** the player starts on the up stairs, and the `@` hides the `<` until they move.

## Milestone 2: the mythology as mechanics (proposed, needs owner review)

Use the candidates in [docs/LORE.md](docs/LORE.md), in this order:

1. **Masks as stances.** This also gives the Occultist its kit.
2. **Eight Chains enemy abilities.** Two or three, starting with Isolation and Monopolization of Perception, which maps to fog.
3. **Relics, worked or transmuted.**
4. **Named losses** (Catalogued, Fluent, Gilded) on the death screen.

Owner decisions are needed first: the apotheosis or "By Decree" ending, and the lore placement for species and classes.

## Milestone 3: platforms

1. **Linux export preset and build.**
2. **Android debug APK.** Needs Godot export templates and the Android SDK; SDK license acceptance is an owner decision. Then a device test of touch, back button and autosave on kill.
3. **Release signing.** Needs a keystore the owner creates and keeps outside the repo.
4. **Windows and Web exports.** Web needs a check of `user://` persistence.

## Milestone 4: depth

More floors (the Seven Spheres as depth bands with gates), the two Ways as victory families, and the Apotheosis guard.
