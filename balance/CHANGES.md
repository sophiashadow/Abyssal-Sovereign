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
