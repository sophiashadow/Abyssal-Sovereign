# Human playtest plan (M7.9)

**Status: no human playtest has been run.** Every win rate in this repository is bot play on fixed seeds. It measures reachability and rough balance, not enjoyment, comprehension or feel. This document says what a person needs to check and how to record it. It reports no results.

Reports are local. Keep them outside the repository (a private folder or notes app) and send the owner only what they choose to share. A report must not hold legal identity, contact details or anything about the tester beyond a nickname. Copy the template at the end for each session.

## Build under test

Record the commit (`git rev-parse --short HEAD`) or the exported build name. Export success is not a runtime check: say which platform actually ran.

| Platform | Command or artifact | What it proves |
|---|---|---|
| Desktop, Linux or Windows | `tools/export.sh` outputs, or `godot --path .` | keyboard path, shortcuts, window sizes |
| Web | web export served locally | touch and mouse, save in browser storage |
| Android | debug APK | touch controls, text scale, resume after the app is backgrounded |

## Coverage matrix

Aim for the first column in every row before repeating a cell. A cell is covered when one honest run reached a death or an ending, not when a bot did.

| Axis | Values | Why a person is needed |
|---|---|---|
| Profile | Initiate, Exile, Adversary, Sovereign | profile feel cannot be read from bot wins; names are provisional |
| Origin | Human, Cambion, Veil-Touched, Unrecorded (first pass), then Revenant, Ash-Marked, Iron-Vowed, Debt-Sworn | Veil-Touched trails under bots; a human may use its trap and secret-door sight |
| Calling | Fallen Knight, Occultist, Assassin, Bastion Warden, Tithe Arbalester, Rite Cantor, Seam Alchemist, Ophite Binder | Ophite Binder and Rite Cantor depend on learning the signature tree |
| Platform | desktop keyboard, touch (web or Android) | M7.7 automation and shortcuts need both |
| Experience | first-time player, returning player | onboarding hints are for the first group |

Minimum useful first round: 8 sessions. Two first-time players on Initiate and Exile, two returning players on Adversary and Sovereign, at least one session on touch, and both Ophite Binder and Rite Cantor among the callings.

## What to look for

Write what happened and what you did, not only a rating. A rating without the moment behind it cannot be acted on.

1. **Onboarding (M7.8).** Did the calling hint make the first talent choice obvious? Did you turn hints off, and when? Did any hint arrive at a bad moment or repeat itself? Could you tell what each profile changes before choosing?
2. **Descent warning (M7.3, M7.7).** On the Sphere Gate screen, did the under-level advisory change what you did? Did you feel nagged or blocked? (It is advisory and never blocks.)
3. **Auto-explore and rest.** Where did it stop that you wanted it to continue, and where did it continue that you wanted it to stop? Did any stop reason read unclearly? Did it ever walk you into something the game should have warned about?
4. **Travel and navigation.** Was the Atlas travel and thread navigation enough to avoid backtracking pain after accepting a thread?
5. **Inventory and comparison.** Could you find, sort and compare gear quickly on touch? Was the cursed or unidentified warning understandable?
6. **Shortcuts.** Did the defaults feel right? Did rebinding work? (Threads is T and Codex is Z; they were unreachable before M7.7.)
7. **Sphere identity.** For each Sphere you reached: what did it feel like it was about, in your words, before reading any lore? Do the seven read as different places or as the same floor with new names? This is not instrumented anywhere else.
8. **Metaphysical choices.** Before each Sphere Gate method, contract, relic Work or Transmute, Return or Serpent decision: did you understand the cost and direction? After the ending, did it match what you expected your choices to mean?
9. **Fairness of deaths.** For each death, was the cause readable at the moment it became unavoidable? Name the last decision you would change.
10. **Pace.** Where did you want to stop playing, and why?

## Defect severity

| Level | Meaning |
|---|---|
| Blocker | crash, corrupt or unloadable save, unwinnable state, lost progress |
| Major | wrong rule, wrong text that misleads a decision, unusable control on a supported platform |
| Minor | readability, wording, awkward flow |
| Idea | not a defect |

For any blocker, keep the seed, the profile and the build, and note the turn count: with those a run can be replayed exactly.

## What counts as a result

- A statement about feel needs two independent sessions before it changes a design decision.
- A bot win rate never confirms a human experience, and a human loss never proves a balance fault: record it and compare against the bot data in `balance/` only after the report is written.
- Keep the first impression and the post-run reflection separate; players rewrite the first once they know the ending.

## Report template (copy per session; keep local)

```
Date:
Build (commit or export name):
Platform and input (keyboard, touch, both):
Tester nickname and experience (first-time or returning):

Profile:
Origin / calling:
Seed (shown on the pause screen):
Hints on? (yes, turned off at turn N, no):
Session length and stop reason:

Outcome (death with cause, ending name, abandoned):
Deepest Sphere reached:
Level at the first Sphere Gate and your choice there:
Threads taken / settled:
Contract signed, kept or broken:
Relic Work or Transmute used:

Onboarding notes:
Descent warning notes:
Automation notes (where it stopped, where it should have):
Navigation and inventory notes:
Sphere identity (one sentence per Sphere reached, in your words):
Choice clarity (decisions you did not understand):
Deaths: last decision you would change:

Defects (severity, steps, seed):
Ideas:
```
