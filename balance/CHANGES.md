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
