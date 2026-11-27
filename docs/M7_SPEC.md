# M7 Specification: The Refinement Pass (Tempering the Abyss)

Reference checkpoint: M6 internal alpha, commit `14cb4a8`. M7 adds no major content. It measures what exists, repairs what is broken or dominated, reduces friction, and prepares human playtesting. Complexity has to earn its place through meaningful decisions.

## Non-negotiables

Deterministic simulation (resumed-run test stays green), offline operation, permadeath, save migration for any save-shape change (`World.SAVE_VERSION` bump, migration, test), lore provenance (every new lore element gets a `docs/LORE.md` row; nothing Proposed is promoted without owner authorization), other repositories untouched, no force-push, no publish or release, no remote push for M7 without separate owner authorization. M8 does not start without authorization.

## Evidence rules

- Automated bot results measure bot play, not human play. They are labelled as such everywhere.
- Development seeds and validation seeds are separate namespaces. A validation salt is claimed once in `balance/validation_ledger.txt` (`tools/m7_soak.gd --claim`) and may then be used for exactly one final measurement; the tool refuses a dev run on any ledger salt and a validation run on an unclaimed one. `m6_final_validation`, `heldout` and `balance` are recorded as historical. M6 numbers are a baseline for comparison, never an optimization target.
- Every balance change records: the finding, the dev-seed evidence, the change, and the dev-seed re-measure. Validation seeds are only spent at the end (M7.10).
- A calling or origin is not changed to equalise win rates. It is changed when the evidence shows a defect (dead talent, broken interaction, unavoidable lethal sequence, bot-only artefact) or a missing viable route.
- A check that did not run is reported `NOT_RUN`. Export success is not runtime verification.

## M7.1 The Instrumented Abyss

Deliverables: `src/sim/telemetry.gd` (local observer), policy bots in `tests/policy_player.gd` on top of `tests/auto_player.gd`, `tools/m7_soak.gd` (sharded runner, JSONL), `tools/m7_report.gd` (aggregator, adaptive-sampling suspects), `balance/` datasets, tests in `tests/test_m7_tools.gd`.

**Telemetry.** `World.telemetry` is null in normal play, is never saved, never read by the simulation and never touches an Rng. A test runs the same seed with and without it and requires an identical end state. It records, per run: damage taken by source and type, damage dealt, kills (monster, elite, boss), floor entries with turn, level and HP, talents learned and used, equipment equipped (slot, template, rarity), consumables used, interactions by kind, contract signed/fulfilled/broken, thread accepted/settled/refused/abandoned, relic worked/transmuted, Sphere Gate method, Chain hits, Entanglement, victory ending, and on death a snapshot: cause, depth, level, burst size, healing carried, statuses, named loss and a triage classification (`unavoidable_burst`, `no_healing_available`, `healing_unused_or_too_slow`, `underlevelled`, `false_light_window`, `entangled`, `attrition`). Nothing is sent anywhere.

**Policies** (all play through `World`'s public API, all deterministic from `(seed, policy)`):

| policy | question it answers |
|---|---|
| `baseline` | the M6.10 `AutoPlayer`, unchanged; continuity with M6 numbers |
| `aggressive` | does the content punish reckless play fairly; burst deaths |
| `defensive` | are healing, resting and retreating adequate; stalemate and attrition |
| `explorer` | clears floors, takes items and sites, visits both branches per Sphere: is optional content rewarding, safe enough, reachable |
| `preserver` | hoards consumables, rests instead of drinking, no False Light: is consumable economy forcing use |
| `specialist` | learns the calling's signature tree first and uses its active kit: is each calling's identity viable |
| `narrative` | meets NPCs, accepts and pursues threads, signs a contract, pledges, works or transmutes relics, travels the Atlas to thread goals |
| `random` | control: what does uninformed play achieve; guards against a game that plays itself |

Known bot conveniences, stated so results are read correctly: bots know the floor's exit position and read the explored map directly; `explorer` and `narrative` use a per-floor action budget and a stuck blacklist; `narrative` takes every thread it is offered and settles `sacrifice_hp` threads by sacrifice, so thread outcomes measure reachability, not roleplay. Bots do not weigh moral cost, so metaphysical-choice distributions (M7.6) are read as "which choices are viable and what they cost", not "what players prefer".

**Sampling.** Round 1 gives every (origin, calling, policy) the same number of dev seeds. `m7_report --suspects` selects pairs whose pooled non-random win rate sits more than two standard errors from the mean, or that never/always win with n >= 8; round 2 re-runs only those with fresh seed indices (`--seed-from`). The dungeon seed for a (pair, index) is identical across policies, so policies are compared on the same worlds.

**Reproduce.** `tools/m7_run.sh` (shards across cores, writes `balance/raw/*.jsonl`, summarizes into `balance/*_summary.{json,md}`). Raw JSONL is local-only (gitignored); summaries are committed.

Acceptance: telemetry-off equals telemetry-on; baseline policy equals M6 `AutoPlayer`; each policy replays; optional-content coverage is measured (branches, threads settled, contracts, relic work, vaults, secrets); the tooling's tests pass in the full suite.

## M7.2 to M7.6 Findings-driven passes

Each pass starts from M7.1 data, not from opinion. A finding is only actioned when it is a defect, a dead or dominated option, or a missing route; otherwise it is recorded as intended.

- **M7.2 Origins, Callings, Build Identity.** Audit 8 origins, 8 callings, 104 talents, 24 trees. Per calling: viable early game, tactical identity, specialization choices, resource flow, equipment configurations, weaknesses, a credible campaign route. Specific questions: Rite Cantor (`rite_weaver`) durability and Resonance economy; whether Seam Alchemist, Occultist, Bastion Warden and Ash-Marked strength is intended, excessive, or bot competence (compare `specialist` and `random`-adjusted results, not baseline alone). Talents never learned or never used by any policy are dead, dominated or unreachable and are reviewed individually.
- **M7.3 Tactical Combat.** Audit 76 monsters (the content pack lists more ids because it includes uniques), 15 bosses, 8 elite mutations, from death classification and per-source damage. Depth 2 Vault Enumerator mortality is investigated first. Fixes prefer telegraphs, targeting, positioning, ability cooldowns and encounter composition over raw HP/damage. Prevent CC loops, unavoidable lethal sequences and AI dead ends.
- **M7.4 Economy of Survival.** Items (165), affixes (46), sets (12), artifacts (26), relics (16): loot rates, healing supply versus demand, XP curve, merchants, identification and curses, inventory pressure, relic opportunity cost. Look for infinite loops, runaway scaling, obsolete categories, meaningless affixes.
- **M7.5 Rhythm of the Seven Spheres.** Per Sphere a mechanical rhythm over existing content (Moon survival/orientation, Mercury scarcity/exchange/institutional pressure, Venus temptation/dangerous rewards, Sun revelation/deceptive relief, Mars confrontation/attrition, Jupiter authority/consequential commitments, Saturn culmination/judgment). Measure campaign length, backtracking, empty exploration per Sphere. No contradictory canon.
- **M7.6 Metaphysical Coherence.** Masks, Eight Chains, Subjugation/Entanglement, False Light/Reckoning, Relic Work vs Transmutation, divine contracts, institutions, threads, Serpent's Way, Way of Return, Unwritten Door, Apotheosis: every power has a cost, no single dominant path, endings follow understandable decisions.

Each pass lands as separate atomic commits, with a ledger row in `balance/CHANGES.md`.

## M7.7 Player Agency and QoL

Safe auto-explore, interruptible rest, travel to explored locations, target cycling with previews, enemy inspection, equipment comparison, inventory sort/filter/search, talent and status tooltips, configurable shortcuts, combat-log filters, contextual warnings, quest/Atlas navigation, touch-friendly actions, destructive-action confirmation, configurable animation and input pacing. Automation stops for enemies coming into view, traps, hazards, consequential choices and dangerous statuses, and never takes an irreversible narrative or metaphysical decision. Simulation-side helpers (auto-explore step selection, travel, comparison) live in `src/sim` or `src/core` and are unit-tested headless; presentation stays in `src/ui`.

## M7.8 Initiation and Difficulty

Optional contextual onboarding in play. Difficulty profiles: **Initiate / Exile / Adversary / Sovereign** (names proposed, pending owner review). Permadeath is unchanged in every profile. Profiles change encounter, resource and tactical composition first (spawn mix, healing supply, telegraph clarity, rest safety), stat multipliers last, through a single profile table rather than parallel balance systems. The profile is stored in the save and in run history (save-version bump, migration, test). `Exile` is the reference profile that matches current balance.

## M7.9 Human Playtest Preparation

`docs/PLAYTEST.md`: a structured matrix (8 callings, representative origins, early/mid/late, branches, threads/institutions, relics/contracts, alternative victories, keyboard/mouse/touch) and a concise local report template that separates automated evidence from human observation. No playtest is reported unless it happened.

## M7.10 Final Refinement Gate

Full test suite, deterministic replay, save migration, reachability, UI smoke, fresh validation simulation on a newly claimed validation salt, Linux/Windows/Web/Android debug export rebuild, Linux executable and APK checks (export success is not runtime verification). Outputs: `docs/M7_REPORT.md`, updated `DESIGN.md`, `ROADMAP.md`, `docs/HANDOFF.md`, balance datasets with reproducible commands, known defects, human playtest requirements, structured M8 ("The Incarnation Pass") recommendations.

Final acceptance: coherent system interactions; no known critical exploit, progression blocker or save-corruption defect; a credible path per calling; understandable counterplay; optional content exercised by automation; low-friction decisions; difficulty and balance conclusions backed by reproducible evidence; platform builds functional where verified; outstanding human and platform verification documented. Automated victories alone do not establish quality.

## Working agreement

One atomic commit per verified submilestone (or sub-part), `tools/test.sh` green before each, `docs/HANDOFF.md` updated at each stop. Commits stay local until the owner authorizes an M7 push.
