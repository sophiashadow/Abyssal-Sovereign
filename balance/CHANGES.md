# M7 balance and content change ledger

Every row: finding, dev-seed evidence, change, dev-seed re-measure. All numbers are bot play on dev seeds (salt `m7dev`), not human play. Validation seeds are untouched until M7.10. Reproduce a measurement with `tools/m7_run.sh TAG --seeds=N --policies=... --species=...`; raw JSONL is local-only, summaries are in `balance/`.

## M7.2-1 Veil-Touched and Unrecorded early durability

- **Finding.** Veil-Touched trailed every other origin in M6 (15/24), b1 and the o0 probe. Unrecorded was second-lowest. Both start with might 0 and base HP 3; might is worth +2 max HP and +1 damage each, so they have the thinnest early HP of the eight origins and die at depth 2 in casters (ophite_binder and rite_weaver account for 23 of 40 Veil-Touched d2 deaths in o1). Radiant is about 20% of damage taken for every origin, and Veil-Touched's -25% radiant stacks with the Nyx mask to -50%; its +35% void resist covers about 4% of the damage it takes.
- **Dev evidence (o0).** 768 runs: origins veilkin, unrecorded, human, cambion x 8 callings x policies baseline, aggressive, defensive, specialist x 6 seeds. Wins: cambion 154/192 (80%), human 150/192 (78%), unrecorded 127/192 (66%), veilkin 108/192 (56%).
- **Change.** `content/core/species.json`: Veil-Touched base HP 3 to 5 and radiant resist -25 to -10 (void +35 and every other value unchanged); Unrecorded base HP 3 to 4 (parity with Human).
- **Re-measure (o1, identical seeds).** Controls unchanged (cambion 154/192, human 150/192), so the comparison is clean. Veil-Touched 118/192 (61%), +10 wins; Unrecorded 130/192 (68%), +3 wins, within noise at this n. Veil-Touched d2 deaths 43 to 40, so durability alone does not explain its d2 deaths.
- **Verdict.** Modest, reversible, not aimed at equalising win rates: Veil-Touched stays the weakest origin under generic bot play. Not repeated or escalated. Whether a residual gap is intended is an owner/human-playtest question (M7.9): Veil-Touched is the "see the hidden" origin (inference, untested): its trap and secret-door detection may matter more to a human than to a bot.

## M7.2-2 Unused active talents: no defect

- **Finding.** b2 coverage listed 14 active talents no policy ever used.
- **Evidence.** `tests/test_m7_talents.gd` drives each directly (heals, cleanses, chain breaking, repositioning, Philosopher's Loan): all behave as defined, 93 checks.
- **Change.** None to content. The silence is bot behaviour, not dead content. Philosopher's Loan is not a free power: the borrowed False Light expires into 40 turns of Reckoning; it only skips the Apotheosis step.

## M7.3-1 d2 Vault Enumerator spike: pacing, not enemy tuning (no stat change)

- **Finding.** Depth 2 deaths cluster on The Vault Enumerator, the first mandatory spine boss (the depth 1 bosses are in optional branches).
- **Evidence.** Pooled non-random dev runs (b1, b2, o0, o1): death rate at depth 2 by arrival level: level 1: 180 of 1127 (16%); level 2: 109 of 1286 (8%); level 3 to 7: 0 of 563. 105 of the 289 d2 deaths are the Enumerator itself. Thorough policies (explorer, narrative) arrive at level 5 or higher.
- **Decision.** Do not nerf the boss: it only kills characters that skip depth 1. The response is information at the point of choice (a contextual under-level warning on descent, M7.7, advisory only, never a gate) and early healing supply (M7.4 audit).

## M7.2-3 Ophite Binder and Rite Cantor: kit-dependent, not underpowered (no stat change)

- **Finding.** Under generic play Ophite Binder wins 50% and Rite Cantor 36% (pooled aggressive, baseline, defensive, explorer, narrative, preserver; n = 120 and 136). When a policy learns the calling's signature tree and uses its kit (`specialist`), they win 81% and 100% (n = 16 each, b2). Their numbers are fine; their kit is not discoverable: no class definition says what to learn first, and a Cantor who melees with the ritual knife loses.
- **Change.** None to stats. Queued for M7.8 onboarding: a data-driven first-talent hint per calling, taken from the specialist's signature trees.

## M7.3-2 Damage over time and bursts: no defect

- **Evidence (3,036 non-random dev runs).** No run took a single-turn burst of 100% of max HP; zero deaths classify as `unavoidable_burst`. Burning is 14.1% of all damage taken, bleeding 5.0% and 78 deaths (12% of all deaths). 58 of the 78 bleeding deaths are at depth 1 or 2 and 55 had no healing item in the pack; early loot tables already weight `healing_salve` first and every calling starts with 1 or 2 salves.
- **Decision.** Not enemy tuning. The same arrival-level and pack-discipline effect as M7.3-1; the answer is the descent warning (M7.7). Bleeding and Burning are clearable (fire cancels bleeding, water cancels burning, several talents and shelters clear them), so counterplay exists.

## M7.4-1 Healing supply, loot and relics: no change

- Healing supply on depth 1 and 2 is adequate where the player collects items; shortfalls are bots that dive without picking up items.
- **Relic Work versus Transmutation.** Work is temporary, repeatable, keeps the relic and costs +1 Apotheosis and usually HP; Transmute is permanent, consumes the relic and costs +2 Apotheosis and a Serpent step. Repeating a free Work (Almoner's Purse) is self-limiting: Apotheosis 8 stops experience gain. Pinned in `tests/test_m7_relics.gd` (13 checks). Bots never called Work in M7.1 data (the baseline bot transmutes any relic it picks up), so thread goals of kind `work_relic` are exercised by test, not by soak.

## M7.5 Rhythm of the Seven Spheres: measured, no content change

- **Duration (162 winning explorer and narrative runs, game turns per depth).** d1 595, d2 892, d3 617, d4 898, d5 916, d6 979, d7 862 (means). Even pacing; no Sphere is a dead stretch or a wall.
- **Backtracking.** Explorer averages 12.9 floor revisits per run (about 2 per spine floor: branch out and back). Narrative averages 34.0, concentrated on Iron Scriptorium (12.6), Chamber of Decrees (7.8) and False Solar Court (5.7): thread goals point at deep spine floors, so a thread accepted early sends the player back down the Atlas. The remedy is navigation (quest and Atlas travel, M7.7), not content.
- **Sphere identity (Moon survival, Mercury exchange, Venus temptation, Sun revelation, Mars attrition, Jupiter authority, Saturn judgment).** Measured only as duration and revisits here; mechanical identity per Sphere is not instrumented and is left to human playtest (M7.9). Stated as a limit, not a pass.

## M7.6 Metaphysical coherence: audit

- **Sphere Gates.** Four methods, each with a cost and a direction: Stormed (-3 HP, +2 Apotheosis, toward By Decree), Serpent's Key (-2 HP, +1 Apotheosis, Serpent's Way), Given Back (a consumable or 3 HP, Way of Return, -2 Apotheosis), By Name (free, -1 Apotheosis, wakes the nearest foe below). By Name is the cheap neutral option and its cost is positional (an awake foe at the arrival point), which is real at deeper Spheres. No method is strictly dominated once the ending it serves is counted.
- **Contract `the_taken_name`.** 21 broken against 2 fulfilled in b2 because bots always crossed By Name, which its oath forbids. Keepable by design (Serpent's Key and Stormed remain). Bots now cross with the Serpent's Key while it is active. Re-measure (c1, narrative, 128 runs, same seeds as b2): 15 signed in both; broken 12 to 0, fulfilled 2 to 11 (the other 4 unresolved at run end), 18 Serpent's Key crossings; wins 80 to 79 of 128, so keeping the oath is not a power tax the bot notices.
- **Endings (bot-reached, so read as reachability, not preference).** b2 victories: Serpent 145, Unwritten 90, Return 31, By Decree 11. Bots follow fixed rules, so this says each ending is reachable by some route, not which a player would choose. A forced-route check per ending exists from M6.10 (`tests/test_reachability.gd`); human playtest must judge whether the choices read as understandable.

## M7.8 Run profiles: same-seed measurement, no tuning

- **Design.** Initiate, Exile, Adversary, Sovereign (names provisional, owner review pending). Parameters live in `content/core/difficulty.json`: foes per floor, squad tightness, elite count, items per floor, healing-loot weight, starting salves. No stat multipliers; the combat rules and permadeath are identical. Exile is neutral and generates exactly what earlier versions did (`tests/test_m7_difficulty.gd`).
- **Measurement (p8, dev salt `m7dev`, bot play).** 192 runs per profile, identical seeds across profiles: Human and Cambion x 8 callings x baseline, explorer, specialist x 4 seeds. Reproduce: `tools/m7_run.sh p8_PROFILE --seeds=4 --policies=baseline,explorer,specialist --species=human,cambion --profile=PROFILE`.

| Profile | Wins | Deaths | Capped (action limit) | Deaths at depth 1-2 |
|---|---|---|---|---|
| Initiate | 156 (81%) | 19 | 17 | 12 |
| Exile | 144 (75%) | 18 | 30 | 11 |
| Adversary | 135 (70%) | 26 | 31 | 11 |
| Sovereign | 129 (67%) | 34 | 29 | 17 |

- **Reading.** Wins fall monotonically with the profile, 14 points from Initiate to Sovereign, and deaths nearly double from Exile to Sovereign. Adjacent profiles are within noise at this n (one standard error is about 3 points), so only the ends are separated. Capped runs are bots that ran out of actions, not deaths, which is why deaths are the cleaner signal.
- **Not concluded.** Bot play cannot say whether Initiate is gentle enough for a first-time player or Sovereign demanding enough for an experienced one. No profile was tuned against these numbers and no validation salt was spent. Human playtest (docs/PLAYTEST.md) decides the parameters and the names.


## 6. M9.6 Final Gameplay Integrity Audit & Fresh Validation (`m9dev_*`, `m9_rc1_validation`)

No mechanics or stat tables were changed after `m7_final_validation` (`SAVE_VERSION := 12` preserved); M8.0 resolved bot navigation stalls and added Relic Work/Transmutation bot coverage (`tools/m7_soak.gd`, `src/sim/assist.gd`). M9.6 measured profile separation on fresh dev seeds (`m9dev_profiles`), full 64-pair coverage on dev seeds (`m9dev_matrix`), and held-out validation on newly claimed salt `m9_rc1_validation` (`v9_rc1_exile`, 256 runs).

### Dev Profile Separation (`salt=m9dev_profiles`, 32 runs/profile: Human & Cambion × 4 callings × 4 policies)

| Profile | Runs | Wins | Deaths | Capped (turn limit) | Mean Deaths Depth 1–2 | Output |
|---|---:|---:|---:|---:|---:|---|
| Initiate | 32 | 24 (75.0%) | 8 | 0 | 3 | `balance/m9dev_prof_initiate_summary.md` |
| Exile | 32 | 22 (68.8%) | 9 | 1 | 6 | `balance/m9dev_prof_exile_summary.md` |
| Adversary | 32 | 21 (65.6%) | 11 | 0 | 7 | `balance/m9dev_prof_adversary_summary.md` |
| Sovereign | 32 | 18 (56.2%) | 11 | 3 | 6 | `balance/m9dev_prof_sovereign_summary.md` |

### Dev 64-Pair Matrix (`salt=m9dev_matrix`, Exile, 256 runs: 64 pairs × 4 policies)

- **Outcomes:** `211 won (82.4%)`, `39 dead (15.2%)`, `6 capped (2.3%)` — `baseline 38/64 (59.4%)`, `explorer 57/64 (89.1%)`, `narrative 61/64 (95.3%)`, `specialist 55/64 (85.9%)`.
- **Coverage:** `86/86` monsters killed, `28/28` floors visited, `24/24` narrative threads accepted, `suspects: []`.
- **Veil-Touched (`veilkin`):** `24/32 (75.0%)` overall (`explorer 7/8`, `narrative 8/8`, `specialist 6/8`, `baseline 3/8`).
- **Depth 2 Deaths (dev):** `20/39` total deaths occurred at depth 2 (`The Vault Enumerator: 10`).

### Held-Out Validation (`salt=m9_rc1_validation`, Exile, 256 runs: 64 pairs × 4 policies)

Claimed once (`balance/validation_ledger.txt`); nothing was tuned against these runs.

| Policy | Runs | Won | Dead | Capped | Mean Depth | Mean Turns |
|---|---:|---:|---:|---:|---:|---:|
| `baseline` | 64 | 51 (79.7%) | 11 | 2 | 6.47 | 783 |
| `explorer` | 64 | 54 (84.4%) | 10 | 0 | 6.34 | 5005 |
| `narrative` | 64 | 59 (92.2%) | 5 | 0 | 6.73 | 3895 |
| `specialist` | 64 | 55 (85.9%) | 9 | 0 | 6.45 | 652 |
| **Total** | **256** | **219 (85.5%)** | **35** | **2** | — | — |

- **Origins (`v9_rc1_exile`, 32 runs each):** `ashborn 29/32 (90.6%, 3d)`, `ironbound_ward 29/32 (90.6%, 3d)`, `cambion 28/32 (87.5%, 4d)`, `revenant 28/32 (87.5%, 4d)`, `penitent 27/32 (84.4%, 5d)`, `unrecorded 27/32 (84.4%, 5d)`, `human 26/32 (81.2%, 5d, 1c)`, `veilkin 25/32 (78.1%, 6d, 1c)`.
- **Callings (`v9_rc1_exile`, 32 runs each):** `occultist 19/32 (59.4%)` and `ophite_binder 22/32 (68.8%)` had the highest early vulnerability; the other six callings won `75%–100%` per policy (`preliator_warden 31/32`, `false_light_alchemist 31/32`, `assassin 30/32`, `fallen_knight 30/32`, `tithe_marksman 30/32`, `rite_weaver 26/32`).
- **Deaths & Endings:** Deaths across depths `{d1:7, d2:5, d3:9, d4:5, d5:3, d6:2, d7:4}`; classes `{attrition:18, no_healing_available:7, healing_unused_or_too_slow:6, false_light_window:3, underlevelled:1}`. Victories across all four endings (`by_decree:76, unwritten:68, serpent:47, return:28`).
- **Relic Work & Coverage:** `1,534` Relic Work uses + `246` Transmutations; `86/86` monsters killed, `28/28` floors visited, `24/24` threads accepted, `102/104` talents learned (`49/104` active used; remaining 13 active talents not triggered by heuristics).
- **Verdict:** M8.0 bot fixes eliminated nearly all action-cap stalls (`0/192` capped across `explorer`/`narrative`/`specialist`; `2/256` overall vs `91/512` in M7). Profile win rates decrease monotonically (`75.0% -> 68.8% -> 65.6% -> 56.2%`). Veil-Touched performs within normal bot-play variance (`78.1%` vs Human `81.2%`). Two points remain open for human playtesting (`docs/PLAYTEST.md`): whether Depth 2 `The Vault Enumerator` pressure (`10` kills in `m9dev_matrix`, `3` in `v9_rc1_exile`) and Occultist/Ophite Binder early frailty feel fair to human players, and whether `explorer` mean run length (~5,005 turns) reflects exhaustive auto-clearing rather than manual pacing.
