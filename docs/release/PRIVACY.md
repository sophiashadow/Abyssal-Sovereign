# Abyssal Sovereign — Privacy Policy (`v1.0.0-rc.1`)

**Effective Scope:** Standalone release packages for Linux, Windows, Android, and Web (`v1.0.0-rc.1`).

## Summary
**Abyssal Sovereign collects zero personal data, makes zero network connections, contains zero analytics or crash-reporting SDKs, serves zero advertising, and requires zero accounts.**

## Data Stored Locally on Your Device
All persistence remains exclusively inside your operating system's application user directory (`user://`, detailed in `docs/INSTALL.md`):
- `world.sav` — Local single-player run state (automatically deleted on permadeath or victory).
- `settings.cfg` — Display, input keybinding, audio volume, and accessibility preferences.
- `codex.json` — Discovered species, relics, threats, and completed endings.

## Permissions & Network Activity
- The desktop and Web builds request no external network endpoints.
- The Android build is compiled as an offline single-player application (`Internet` permission is not used by game code, and no external SDKs or remote services are initialized).

## Data Deletion
Deleting the OS `user://` folder (or uninstalling the Android app / clearing site IndexedDB data in a Web browser) permanently removes all local saves and settings. Because no data is ever transmitted off-device, there is no server-side data to request or purge.
