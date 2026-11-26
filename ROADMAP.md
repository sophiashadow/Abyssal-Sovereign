# Roadmap

## Milestone 0: foundations (done 2026-11-26)

Project, layering, content schema and validator, seeded RNG, test runner, and docs.

## Milestone 1: playable vertical slice (done 2026-11-26, Linux)

Everything in the M1 brief is implemented. The automated evidence is the headless suite, the soak and the UI smoke. All of it was run on Linux in a container under Xvfb. No human playtest has happened yet.

### Known defects and limits

- **Occultist balance:** weakest calling. Held-out bot win rate is 13%, against 60% for the Knight. Fix it with a kit (see M2), not stats.
- **Ranged play:** there are no ranged attacks, spells or doors (other than the sealed one), and there is no item identification.
- **Saves:** no save migration code yet. Only v1 exists.
- **Platforms:** no export presets and no builds for any platform. Android, Windows and Web are untested.
- **Typography and accessibility:** the glyph font is the engine default (proportional, centred per cell). A dedicated monospace font needs a license check first. There is no colour-blind palette option and no screen-reader support.

## Milestone 2: the mythology as mechanics (done 2026-11-26)

1. **Masks as stances** (`mask_stances` on Occultist: Bare Face, Nyx, Eris, Lilith; `SAVE_VERSION` 2).
2. **Eight Chains enemy abilities** (`chain_isolation` on cultist of the false sun, `chain_fog` / `perception_fog` on Preliator Sentinel).
3. **Relics, worked or transmuted** (*Confessor's Glass*, *Ophite Key*, *Broken Halo*).
4. **Named losses** (Catalogued, Fluent, Gilded) on the death screen.

Owner decisions resolved 2026-11-26 (see [docs/LORE.md](docs/LORE.md)): Apotheosis ("By Decree") can be a win; the Unwritten Door, origins, and callings are canon.

## Milestone 3: platforms (presets & local builds done 2026-11-26)

1. **Linux export preset and build:** Done (`build/linux/abyssal-sovereign.x86_64`, verified launching cleanly).
2. **Android debug APK:** Done (`build/android/abyssal-sovereign-debug.apk`, aligned & debug-signed; physical device test `NOT_RUN`).
3. **Release signing:** Needs a keystore the owner creates and keeps outside the repo.
4. **Windows and Web exports:** Done (`build/windows/abyssal-sovereign.exe`, `build/web/index.html`; Windows runtime and Web browser `user://` persistence `NOT_RUN`).

## Milestone 4: depth

More floors (the Seven Spheres as depth bands with gates), the two Ways as victory families, and the Apotheosis guard.
