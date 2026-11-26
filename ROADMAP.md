# Roadmap

## Milestone 0: foundations (done 2026-11-26)

Project, layering, content schema and validator, seeded RNG, test runner, and docs.

## Milestone 1: playable vertical slice (done 2026-11-26, Linux)

Everything in the M1 brief is implemented. The automated evidence is the headless suite, the soak and the UI smoke. All of it was run on Linux in a container under Xvfb. No human playtest has happened yet.

### Known defects and limits

- **Occultist & Assassin balance (7 Spheres):** Fallen Knight leads in bot soak runs (`49/60` vs. `17/60` Assassin and `6/60` Occultist on 7 floors), as the soak bot does not kite, exploit Nyx/Lilith tactics, or work relics.
- **Ranged play:** there are no ranged attacks, spells or doors (other than the sealed one), and there is no item identification.
- **Typography and accessibility:** the glyph font is the engine default (proportional, centred per cell). A dedicated monospace font needs a license check first. There is no colour-blind palette option and no screen-reader support.
- **Unverified runtimes:** Windows runtime, Web browser `user://` persistence, physical Android device install/touch/kill-save test, and Android release signing are `NOT_RUN`.

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

## Milestone 4: depth (done 2026-11-26)

1. **Seven Spheres** (Moon through Saturn, depths 1–7) with **Sphere Gates** (`Stormed`, `Serpent's Key`, `Given Back`, `By Name`) and deeper Dominion enemies (`Inquisition Cantor`, `Tithe Inquisitor`).
2. **Two Ways** (`The Serpent's Way`, `The Way of Return`) as alternative victory families.
3. **Apotheosis guard** and the hollow **"By Decree"** victory.

## Milestone 5.1: character development (done 2026-11-26)

1. **Talent trees & progression:** 3 talent trees per calling (`27` talents total in `content/core/talents.json`) with active and passive abilities, prerequisites, and tier/level gates.
2. **Attribute allocation:** Players gain attribute points on odd levels and talent points every level from 2; `Might` increases max HP (`+2/pt`), `Agility` increases crit chance (`+2%/pt`), and `Will` scales Occultist abilities and healing.
3. **Class resources & cooldowns:** `Stamina` (Fallen Knight), `Resonance` (Occultist), and `Poise` (Assassin), with tactical active cooldowns and Build (`c`) / Act (`a` / `1`–`6`) UI panels.
4. **Species differentiation:** Humans gain `adaptable` (extra attribute points at levels 2/5 and talent points at levels 3/6); Revenants ignore `bleeding` and gain `Braced` on `deathless` triggers; Cambions pay `-1` HP when working Relics and deal `+2` damage with active talents while at `>= 2` `infernal_blood`.

## Milestone 5.2: combat depth (done 2026-11-26)

1. **Ranged & occult arsenal:** Added `ranged` weapon slot, thrown `projectile` items/flasks (including AoE splash), and `scroll` spells (`phase_step`, piercing `abyssal_lance`, `cinder_ward`), with line-of-fire blocking (`Grid.line`) and interactive Aim Mode (`f` / `Fire` + trajectory highlight).
2. **Damage types & resistances:** `physical`, `fire`, `cold`, `radiant`, and `void` damage with innate species/mask/gear/status resistances and vulnerabilities.
3. **Tactical movement & status synergies:** Added `Vanguard Charge`, `Veil Step`, and `Crippling Shot` (total `30` talents) plus emergent status combos (`Thermal Shock`, `Scalding Steam`, `Cauterize`, `Hemorrhage`, and `False Light` Void fracture).
4. **Enemy specials, elites & bosses:** Added `ossuary_arbalest`, `cinder_acolyte`, `ossuary_wight`, monster specials (`solar_bolt`, `cinder_bolt`, `grave_chill`, `void_bolt`, `iron_shackle`, `judgment_nova`, `warren_pounce`, `leech_bite`), deterministic elites (`Ashen`, `Rime-bound`, `Apostate`, `Ironbound`), Sphere 3/5 mid-bosses (`Choir Cantor Prime`, `Iron Auditor`), and `SAVE_VERSION := 5`.
5. **Next (M5.3–M5.5):** Equipment & discovery (affixes, rarity/uniques, unidentified gear & potions, blessed/cursed items, sets), dungeon ecology, and Eight Chains / metaphysical depth.
