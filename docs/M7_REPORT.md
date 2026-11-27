# Milestone 7 report: the Refinement Pass ("Tempering the Abyss")

Reference checkpoint: M6, commit `14cb4a8`. Branch `ccr-4b7d6997-36eyn5`, draft PR #1. Nothing here is merged, released or published.

**Bot results are bot play, not human play.** Every win rate below comes from fixed-rule policies on fixed seeds. They measure reachability and rough balance. They say nothing about enjoyment, comprehension or feel. No human playtest has been run (see `docs/PLAYTEST.md`).

## Summary

| Sub-milestone | Result | Evidence |
|---|---|---|
| M7.1 Instrumented Abyss | Local telemetry, eight policies, soak and report tools, seed ledger | `tests/test_m7_tools.gd`, `balance/validation_ledger.txt` |
| M7.2 Origins and callings | Veil-Touched base HP 3 to 5 and radiant resist -25 to -10; Unrecorded base HP 3 to 4. Unused talents verified, not dead | `balance/CHANGES.md` M7.2, `tests/test_m7_talents.gd` |
| M7.3 Combat | No stat change. Depth-2 spike answered with an advisory warning, not a nerf | CHANGES M7.3 |
| M7.4 Economy | No change. Work versus Transmute costs pinned by test | `tests/test_m7_relics.gd` |
| M7.5 Sphere rhythm | Measured; pacing even; backtracking answered with navigation, not content | CHANGES M7.5 |
| M7.6 Coherence | Contract `the_taken_name` was unreachable by bots; bots fixed, not the game | CHANGES M7.6 |
| M7.7 Agency and QoL | Safe auto-explore, interruptible rest, travel, compare, sort/filter/search, log filters, shortcuts, confirmations, advisories | `tests/test_m7_assist.gd`, `tests/test_m7_settings.gd`, UI smoke |
| M7.8 Profiles and onboarding | Initiate, Exile, Adversary, Sovereign (names provisional); save v12; optional hints | `tests/test_m7_difficulty.gd`, `tests/test_m7_hints.gd` |
| M7.9 Playtest plan | Matrix and local report template; no results claimed | `docs/PLAYTEST.md` |
| M7.10 Final gate | Below | below |

No major content was added. The one new content kind is the profile table (`content/core/difficulty.json`), and one field, `signature_tree`, on callings.

## What changed in play

- **Safety-first automation.** Auto-explore, rest and travel stop for a hostile in view, a dangerous status, health under 35%, unexpected HP loss, hazards, revealed traps and anything that needs a decision. They never use a feature, sign a contract, or cross a new Sphere Gate. Any key press interrupts. Travel only goes over floors already visited, so it cannot spoil the Atlas.
- **Information at the point of choice.** The Sphere Gate screen shows advisory lines (never a gate). The recommended-level hint is evidence-based for depth 2 only (level 3 from M7.3 data); no claim is made for other depths. Equipment comparison shows nothing numeric for unidentified gear.
- **A latent defect fixed.** The Threads (J) and Codex (K) keys were shadowed by the movement keys and never worked. Defaults are now T and Z, and rebinding refuses movement and reserved keys.
- **Profiles.** Foes per floor, squad tightness, elites, items, healing-loot weight and starting salves change. No stat multiplier exists anywhere in the profile table. Permadeath is identical. Exile is neutral and generates exactly what earlier versions did. The profile is saved with the run (`SAVE_VERSION` 12, v11 saves load as Exile, unknown ids are refused) and recorded in run history.

## Final gate (M7.10)

### Tests (commit `d5c13cf` and later; no code changed after it)

| Check | Result |
|---|---|
| `tools/test.sh` | 190 tests, 190 passed, 0 failed, 4323 checks, 110.6 s |
| Save migration (v1 to v12) and round trip | in the suite, passing (`tests/test_save.gd`, `test_m7_difficulty.gd`) |
| Deterministic replay, resumed run equals straight run | in the suite, passing (`test_resumed_run_matches_uninterrupted_run`) |
| Reachability (no dead content) | in the suite, passing (`tests/test_reachability.gd`) |
| UI smoke (`xvfb-run ... tools/ui_smoke.gd`) | 39 steps, 0 failures, including profile choice, hint, auto-explore, shortcut rebinding |
| CI | NOT_RUN. There is no CI; local results only |

Commits after `d5c13cf` change only `docs/`, `balance/` and the validation ledger, so the suite and smoke results describe the shipped code. Re-run both before any merge.

### Validation soak (fresh salt `m7_final_validation`, claimed once, now spent)

Command: `tools/m7_run.sh v7_exile --set=validation --salt=m7_final_validation --seeds=2 --policies=baseline,explorer,narrative,specialist`. 512 runs: all 64 origin and calling pairs x 4 policies x 2 seeds, Exile profile. Raw data is local-only (`balance/raw/`); summaries are `balance/v7_exile_summary.md` and `.json`.

| | Wins | Rate |
|---|---:|---:|
| All runs | 369 / 512 | 72.1% |
| Deaths | 52 | 10.2% |
| Ran out of actions (unfinished) | 91 | 17.8% |

By policy: baseline 90/128, explorer 93/128, narrative 82/128, specialist 104/128. By origin: Revenant 51/64, Iron-Vowed 50/64, Human 49/64, Unrecorded 49/64, Cambion 47/64, Ash-Marked 44/64, Debt-Sworn 44/64, Veil-Touched 35/64. By calling: Seam Alchemist 58, Bastion Warden 55, Fallen Knight 50, Ophite Binder 46, Rite Cantor 44, Tithe Arbalester 41, Occultist 37, Assassin 38 (each of 64). Death depth: d1 3, d2 19, d3 9, d4 7, d5 8, d6 4, d7 2. Top causes: The Vault Enumerator 8, ghoul 6, cultist of the false sun 5, Iron Auditor 4, bleeding 4. Endings reached: Serpent 180, Unwritten 119, Return 63, By Decree 7.

**What this does and does not show.**

- *Fact:* the validation salt confirms the game is winnable by every origin and calling and that early (depth 2) deaths remain the largest single cluster, driven by the Vault Enumerator, as in the dev data.
- *Fact:* the numbers are not comparable with the M6.10 figure (75% on 192 runs of one policy). The policy mix differs, so `m6_final_validation` stays a historical reference and nothing was tuned toward it.
- *Fact:* 91 of 512 runs are unfinished, mostly narrative (44) and explorer (33) bots that exhausted the action budget. Occultist and Assassin show 17 and 18 unfinished runs against 9 deaths each; Veil-Touched shows 22 unfinished against 7 deaths. Their lower win rates are therefore mostly unfinished runs, not combat losses.
- *Inference, not tested:* the unfinished runs probably reflect bot behaviour (mask handling and detection-driven wandering), not game difficulty. The reason was not diagnosed.
- *Fact:* the M7.2 Veil-Touched durability change raised its dev win rate from 56% to 61% on identical seeds. On the validation salt Veil-Touched is still the lowest origin (55%), so the change did not close the gap. Whether a residual gap is acceptable is an owner decision, informed by human play.
- No change was made after seeing this salt, so it remains a clean measurement.

### Profiles on the same seeds (dev salt `m7dev`, not validation)

| Profile | Wins / 192 | Deaths | Unfinished |
|---|---:|---:|---:|
| Initiate | 156 (81%) | 19 | 17 |
| Exile | 144 (75%) | 18 | 30 |
| Adversary | 135 (70%) | 26 | 31 |
| Sovereign | 129 (67%) | 34 | 29 |

The order is as intended and deaths nearly double from Exile to Sovereign. Adjacent profiles are within noise (one standard error is about 3 points); only the ends are separated. Whether Initiate is gentle enough or Sovereign demanding enough is for human players to judge.

### Exports (local; Android is debug-signed)

Export templates for Godot 4.7.2 were fetched from the official release and checked against the published SHA-512 before use.

| Target | Artifact | Status |
|---|---|---|
| Linux | `build/linux/abyssal-sovereign.x86_64` (74 MB) | built; **launched** under a virtual display, 300 frames, exit 0, no errors in output. Gameplay not driven |
| Windows | `build/windows/abyssal-sovereign.exe` (110 MB) | built only; **runtime NOT_RUN** |
| Web | `build/web/index.html` and assets (wasm 40 MB) | built only; browser persistence NOT_RUN |
| Android | `build/android/abyssal-sovereign-debug.apk` (58 MB, SHA-256 `9a1a125d678494188087bd940d842397963bf27f327a61a5122fa8177c0c08c7`) | built; `apksigner verify` passes (v2 and v3), debuggable, 196 files; **install and touch on a device NOT_RUN** |

Export success is not runtime verification. The APK is debug-signed and is not a release.

## Known defects and limits

1. Auto-explore cannot see hidden traps, so it can still walk onto one.
2. The recommended-level hint covers depth 2 only; other depths have no evidence.
3. Sphere mechanical identity (Moon, Mercury, Venus, Sun, Mars, Jupiter, Saturn) is not instrumented. Only duration and revisits were measured.
4. Baseline bots never use Work relics, so Work-relic thread goals are covered by tests, not by soak.
5. Endings from bots measure reachability, not preference. By Decree is rare (7 of 369 wins).
6. 17.8% of validation runs are unfinished; the cause is not diagnosed.
7. Veil-Touched is still the lowest origin in bot play.
8. Profile names and parameters are provisional. Adjacent profiles are not separated by this data.
9. Windows runtime, Web persistence, Android device install and touch, and release signing are all NOT_RUN.
10. Hints and descriptions are English copy in code and content; there is no localisation.

## Human playtest requirements

Before any M8 content or any claim about quality, run a first round from `docs/PLAYTEST.md`: at least eight sessions across all four profiles, first-time and returning players, desktop and touch, and including Ophite Binder and Rite Cantor. The questions that bots cannot answer: whether the calling hint makes the first choice obvious, whether the descent advisory changes decisions without nagging, where automation stops wrongly, whether the seven Spheres feel different, and whether the metaphysical costs are understood before they are paid.

## M8 recommendations (structured; M8 has not been started and needs owner authorization)

| # | Recommendation | Evidence | Cost and risk | Needs |
|---|---|---|---|---|
| 1 | Run the first human playtest round before designing M8 | all balance data above is bot play | owner time; no code risk | owner and testers |
| 2 | Diagnose the 91 unfinished validation runs (Occultist, Assassin, Veil-Touched, narrative and explorer bots) | run cap hit, not deaths | tool work only; risk of tuning the game to a bot fault | none |
| 3 | Settle profile names and parameters after playtest | provisional; adjacent profiles overlap | data-only change | owner decision |
| 4 | Instrument Sphere identity (per-Sphere decisions, resource spend, status mix) | not measured | telemetry only | none |
| 5 | Decide whether Veil-Touched's residual gap is intended | 56% dev, 61% after change, 55% validation | stat change or accept | owner and playtest |
| 6 | Add a Work-relic bot behaviour so thread goals of that kind are exercised by soak | zero Work calls in soak | tool work | none |
| 7 | Verify Windows, Web persistence and a real Android device; create the release keystore outside the repository | NOT_RUN | owner device and key | owner |
| 8 | Consider a hidden-trap detection cue for auto-explore | known limit 1 | design choice, small | owner |

No lore was promoted and no Proposed element was settled in M7; new lore rows needed none.

## Reproducing the data

- Full tests: `tools/test.sh`. One file: `.tools/godot --headless --path . --script res://tests/run_tests.gd -- --only=test_NAME`.
- UI smoke: `xvfb-run -a .tools/godot --path . --audio-driver Dummy --script res://tools/ui_smoke.gd`.
- Dev measurements: `tools/m7_run.sh TAG --seeds=N [--policies=..] [--species=..] [--classes=..] [--profile=..]`. Each change row in `balance/CHANGES.md` names its command.
- Validation: salts are claimed once with `.tools/godot --headless --path . --script res://tools/m7_soak.gd -- --claim --salt=NAME`; `m7_final_validation` is spent.
- Exports: `tools/export.sh all` (needs the 4.7.2 export templates installed).
