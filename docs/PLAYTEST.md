# Abyssal Sovereign — External Human Playtest & Accessibility Guide (`v1.0.0-rc.1`)

**Status: No human playtest has been run.**
No human participant has yet played M5, M6, M7, M8, or M9 (`v1.0.0-rc.1`). All runtime balance figures in `balance/` and `docs/M9_REPORT.md` come from deterministic automated bot policies (`baseline`, `explorer`, `narrative`, `specialist`) and simulated viewports (`tools/ui_smoke.gd`). Human playtesting is required before tuning difficulty profiles, finalizing the D2 Vault Enumerator curve, replacing provisional sprites (`provisional_m9_asset`) or temporary liturgical music (`placeholder_liturgical_temp`), or promoting release builds beyond `v1.0.0-rc.1`.

---

## 1. Downloads, Platform Support & Installation (`v1.0.0-rc.1`)

Download pre-release builds and `SHA256SUMS.txt` from [**GitHub Releases (`v1.0.0-rc.1`)**](https://github.com/sophiashadow/Abyssal-Sovereign/releases/tag/v1.0.0-rc.1).

| Platform | Package / Binary | Verification Status | Launch & Install |
|---|---|---|---|
| **Linux (x86_64)** | `abyssal-sovereign-v1.0.0-rc.1-linux-x86_64.tar.gz` | Automated binary smoke passed (`DISPLAY=:0 --quit-after 30`) | Extract tarball, `chmod +x abyssal-sovereign.x86_64`, run `./abyssal-sovereign.x86_64` (optional `.desktop` + `icon_512.png` included) |
| **Windows (x86_64)** | `abyssal-sovereign-v1.0.0-rc.1-windows-x86_64.zip` | Exported only — runtime **`NOT_RUN`** on Windows | Extract zip to any folder and launch `abyssal-sovereign.exe` |
| **Android (ARMv7 / ARM64)** | `abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` | APK exported & verified leak-free; physical device install **`NOT_RUN`** | Enable "Install unknown apps" / sideload debug APK via `adb install abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` |
| **Web (HTML5 / PWA)** | `abyssal-sovereign-v1.0.0-rc.1-web.zip` | Exported only — browser & IndexedDB runtime **`NOT_RUN`** | Extract zip and serve over local HTTP (e.g. `python3 -m http.server 8080`), then open `http://localhost:8080/index.html` (avoid `file://`) |

Full install, uninstall, OS save locations, and upgrade notes live in `docs/INSTALL.md`.

---

## 2. Core Controls

### Desktop (Keyboard + Mouse)
Rebindable shortcuts can be customized in **Settings -> Shortcuts**. Movement, wait, stairs, talent hotkeys `1–6`, and `Esc` are fixed.

| Action | Default Keys | Notes |
|---|---|---|
| Move / Bump-Attack (8 directions) | Arrow keys, `h/j/k/l/y/u/b/n` (Vi-keys), or Numpad `1–4, 6–9` | Orthogonal & diagonal |
| Wait 1 Turn | `.`, `Space`, or Numpad `5` | Passes one turn |
| Pick Up Item (`Get`) | `g` | Picks up floor item; button highlights when standing on loot |
| Inventory (`Bag`) | `i` | Equip, use, drop, compare (`[▲]`/`[▼]`), identify (`[?]`), relic work |
| Rest (`Rest`) | `r` | Rests safely until healed or interrupted by danger |
| Auto-Explore (`Auto`) | `o` | Explores unexplored tiles cleanly; stops on foe, loot, or threat |
| Look / Examine (`Look`) | `x` | Move cursor or click/tap any visible tile to inspect foe/feature/status |
| Character & Talents (`Build`) | `c` | Spend trait/talent points (`[▲]` when points available) |
| Active Abilities (`Act`) | `a` (or `1–6`) | Cast learned active abilities |
| Fire Ranged / Throw (`Fire`) | `f` | Enter Aim Mode (`Tab`/click target, `Enter` confirm, `Esc` cancel) |
| Search Nearby (`Srch`) | `s` | Searches adjacent tiles for hidden traps/caches |
| Use / Interact (`Use`) | `e` | Open vaults/gates, read caches, speak with NPCs, trade, witness shrines |
| Descend / Ascend (`Stairs`) | Click/tap `Stairs` (or floor stair prompt) | Traverse stairs when standing on stairs (`>`, `<`) |
| Masks (Mask-stance callings) | `m` | Switch active Mask stance; highlights when False Light risk is high |
| World Atlas / People / Threads / Codex | `Tab` / `p` / `t` / `z` | Track Seven Spheres, NPCs/institutions, narrative threads, codex |
| Log Filter / Pause / Back | `q` / `Esc` | Cycle log filter; `Esc` closes modals, cancels modes, or opens Pause |

### Mobile / Touch Interface
- **Portrait Layout:** Fixed zero-scroll layout with compact top vital bar + collapsible `Stats ▾` drawer, ~70% player-centered map viewport, compact log strip, and fixed bottom touch dock (3×3 D-pad + action grid). Enable **Left-Handed** in Settings to mirror the D-pad and action grid.
- **Contextual Mode Bars:** When aiming (`Fire` or targeted ability), looking (`Look`), or auto-exploring (`Auto`/`Travel`), an explicit bottom bar surfaces **Next / Confirm / Cancel**, **Done Looking**, or **Stop** without needing a keyboard.
- **Android Back Button:** Closes active overlays, cancels Look/Aim mode, stops Auto-Explore/Travel, or opens the Pause menu cleanly.
- **Map Gestures:** Tap any visible floor tile to travel, tap an adjacent foe to bump-attack, or tap a chest/stairs/NPC directly.

---

## 3. New-Player Tactical Guide

1. **Read Combat Pacing:** Enemies act on deterministic turns. If two foes flank a hallway, retreat to a one-tile chokepoint (`h/j/k/l` or D-pad) before fighting.
2. **Respect Lantern & False Light (`LUZ`):** Your Lantern illuminates the dark and wards off threats, but False Light builds metaphysical risk across deeper Spheres (and enables stronger Mask stances). Watch status badges and inspect unfamiliar enemies with `Look` (`x`).
3. **Inspect Unknown Loot (`[?]`):** Items marked `[?]` in `Bag` have unverified effects until identified (Scroll of Identify, `i`), and `[▲]` / `[▼]` indicators compare equipment stats directly against what you wear. Watch for `[☠]` cursed tags.
4. **Use Relics Early, Transmute Intentionally:** Relics provide active Work charges (`Bag` -> Work) every floor/rest cycle — do not hoard charges when facing Sphere Guardians (especially **The Vault Enumerator** on Depth 2). Transmutation consumes a relic permanently for a durable boon and prompts confirmation when *Confirm destructive choices* is enabled.
5. **Witness Contracts & Threads (`p`, `t`):** Speaking with NPCs (`Use` / `e`) lets you accept quests, buy supplies, or pledge aid repeatedly inside one dialogue modal. Contracts carry explicit obligations and consequences — read both Terms and Breaking Penalty before signing.
6. **Check `Build` & `Rest` Highlights:** `Rest` tints green when safe & wounded; `Build` and `Stairs` highlight amber when talent points await or you stand over stairs.

---

## 4. Known Limitations (`v1.0.0-rc.1`)

- **Provisional Art (`provisional_m9_asset`):** Procedural pixel-art atlases were upgraded in M9.1 with silhouettes, radial lantern lighting, 15 bosses, and 24 woodcut emblems, but signature art assets have not yet been replaced by external commissioned illustrations (tracked in `docs/ASSET_BACKLOG.md`).
- **Temporary Music Stems (`placeholder_liturgical_temp`):** 16 loopable ambient/music stems are procedural temporary compositions mastered in M9.5 alongside procedural SFX; approved original recordings are awaiting owner handoff.
- **Pending Platform Runtimes:** Linux headless and X11 smoke checks passed; Windows desktop runtime, Web browser IndexedDB persistence, and physical Android hardware touch/background-suspend behavior are **`NOT_RUN`**.
- **Debug Android Signing:** `abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` uses a development debug keystore; store distribution requires external owner keystore signing (`docs/INSTALL.md`).
- **Lore & Balance Finalization Pending Review:** `docs/OWNER_CANON_LEDGER.md` lists open Canon/naming decisions, and M9.6 flags Depth 2 Vault Enumerator spikes plus early Occultist / Ophite Binder frailty for human difficulty feedback.

---

## 5. Bug-Reporting Instructions

When filing a playtest bug report or feedback note on [**GitHub Issues**](https://github.com/sophiashadow/Abyssal-Sovereign/issues), please include:

1. **Version & Package:** e.g. `v1.0.0-rc.1 (Linux portable)` or `(Android debug APK)`
2. **Seed & Descent Setup:** Run Seed (shown in HUD / Character sheet / Death summary), Difficulty Profile (`Initiate` / `Exile` / `Adversary` / `Sovereign`), Origin & Calling
3. **Where It Happened:** Sphere & Floor depth (e.g. `Depth 2 — Mercury`), Turn count, Mode (`Tiles` or `Glyph`, Portrait/Landscape resolution)
4. **Steps to Reproduce:** What action/button/key was pressed right before the issue
5. **Attachments (no personal info required):** Screenshot + relevant save file (`world.sav` / `settings.cfg` from the OS user folder listed in `docs/INSTALL.md`) and console log if on desktop.

---

## 6. Playtest & Accessibility Coverage Matrix

Automated smoke tests verified layout geometry (`39 steps, 0 failures`) on simulated `1280x720`, `2340x1080`, and `720x1280` viewports, plus unit checks for audio mute, lunges, and color/contrast transforms. Human testers should cover every row below and mark **Pass / Issue**:

| Category | Test Focus |
|---|---|
| **Origins & Callings** | At least 3 distinct pairings including frail casters (**Veil-Touched / Occultist**, **Ophite Binder**) and martial builds (**Human / Preliator Warden**, **Ironbound Ward / Fallen Knight**) |
| **Difficulty Profiles** | First-run learnability on **Initiate** vs standard **Exile** vs pressure on **Adversary / Sovereign** |
| **Input Modalities** | Desktop keyboard (Arrows / Vi / Numpad + rebind check), mouse click-to-move/inspect, mobile touchscreen D-pad, left-handed D-pad swap |
| **Orientations** | Desktop `16:9` window, mobile **Portrait** (`9:16` / `9:20`), mobile **Landscape**, safe-area/notch readability |
| **Visual Modes** | **Tiles** mode vs **Glyph** mode (`Settings -> Render mode`), text scaling (`1.0×`–`1.75×`), camera zoom |
| **Accessibility** | **High Contrast** on/off, **Deutan/Protan**, **Tritan**, **Reduced Motion**, **Instant Actions**, **Narrative Banners** off |
| **Audio States** | Audio enabled (music + Sphere ambience crossfade + SFX balance) vs **100% Silent / Master 0%** play vs app background/focus loss |

---

## 7. Concise Human Playtest Questionnaire

Please score `1` (Poor / Unclear) to `5` (Strong / Natural) and add 1–3 sentences of specifics:

1. **Learnability:** How quickly did you understand movement, Wait/Rest, identification, Lantern risk, and Contracts on your first run?
2. **Enjoyment:** Did combat, exploration, and Sphere progression feel rewarding enough to start another run after dying?
3. **Tactical Clarity:** Could you distinguish threats, elites, bosses, hazards, and NPCs at a glance in both Tiles and Glyph modes?
4. **Interface Comfort:** Were text sizes, modal scrolling, inventory comparison tags (`[▲]/[▼]/[?]/[☠]`), and touch/desktop controls comfortable without fatigue?
5. **Campaign Pacing:** How did pacing feel across early Spheres (especially Floor 1–2) through mid-campaign? Did any floor feel rushed or overly long?
6. **Narrative Comprehension:** Were Sphere transitions, NPC factions/institutions, Contract terms, and threads intelligible and atmospheric?
7. **Perceived Difficulty:** Did your chosen Profile (**Initiate / Exile / Adversary / Sovereign**) feel fair when you died, or did sudden spikes (e.g. D2 Vault Enumerator) feel unearned?
8. **Replayability:** How distinct did different Origins, Callings, Relics, and Mask stances feel across runs?
9. **Memorable Encounters & Friction:** Name one encounter or moment that stood out positively, and the single worst UI or mechanical friction point you hit.
