# Abyssal Sovereign — Installation, Save Management & Distribution Guide (`v1.0.0-rc.1`)

Download official pre-release archives and `SHA256SUMS.txt` from the [GitHub Releases page (`v1.0.0-rc.1`)](https://github.com/sophiashadow/Abyssal-Sovereign/releases/tag/v1.0.0-rc.1).  
Abyssal Sovereign runs **100% offline** with zero external network requests, zero telemetry, zero advertising, and zero accounts.

---

## 1. Platform Installation & Launch

### Linux (`x86_64` Portable Tarball)
1. Verify checksums against `SHA256SUMS.txt`:
   ```sh
   sha256sum -c SHA256SUMS.txt --ignore-missing
   ```
2. Extract `abyssal-sovereign-v1.0.0-rc.1-linux-x86_64.tar.gz` into your preferred directory (e.g. `~/.local/opt/abyssal-sovereign`):
   ```sh
   mkdir -p ~/.local/opt/abyssal-sovereign
   tar -xzf abyssal-sovereign-v1.0.0-rc.1-linux-x86_64.tar.gz -C ~/.local/opt/abyssal-sovereign
   cd ~/.local/opt/abyssal-sovereign
   chmod +x abyssal-sovereign.x86_64
   ./abyssal-sovereign.x86_64
   ```
3. **Optional Desktop Integration:**
   Copy the bundled `abyssal-sovereign.desktop` and `icon_512.png` to your XDG desktop directories, updating `Exec=` and `Icon=` to match your chosen install folder:
   ```sh
   mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/512x512/apps
   cp icon_512.png ~/.local/share/icons/hicolor/512x512/apps/abyssal-sovereign.png
   sed "s|@EXEC@|$PWD/abyssal-sovereign.x86_64|g; s|@ICON@|abyssal-sovereign|g" abyssal-sovereign.desktop > ~/.local/share/applications/abyssal-sovereign.desktop
   ```
4. **Uninstall:** Delete the extracted install folder (and `~/.local/share/applications/abyssal-sovereign.desktop` + `abyssal-sovereign.png` if installed). Your saves remain safely in `~/.local/share/godot/app_userdata/Abyssal Sovereign/` unless you explicitly remove them.

### Windows (`x86_64` Portable Zip)
> Note: Windows binary export succeeded on Linux, but **runtime execution on Windows has not yet been tested (`NOT_RUN`)**.

1. Extract `abyssal-sovereign-v1.0.0-rc.1-windows-x86_64.zip` to any writable folder (the PCK data is embedded inside `abyssal-sovereign.exe`).
2. Double-click `abyssal-sovereign.exe` (or run from Command Prompt / PowerShell).
3. **Uninstall:** Delete the extracted folder. Saves remain in `%APPDATA%\Godot\app_userdata\Abyssal Sovereign\` unless explicitly deleted.

### Android (`ARMv7` / `ARM64` Debug APK)
> Note: `abyssal-sovereign-v1.0.0-rc.1-android-debug.apk` is signed with a debug key. **Physical Android installation, touch play, and suspend/resume have not yet been tested (`NOT_RUN`).**

1. **Sideload via ADB or file manager:**
   ```sh
   adb install abyssal-sovereign-v1.0.0-rc.1-android-debug.apk
   ```
   (Or copy the APK to the device and allow "Install unknown apps" when prompted.)
2. **Release Keystore Signing (External Owner Action Only):**
   Do **not** store release keystores inside the git repository. When ready to publish signed Android releases, create or point Godot's export preset outside the repo:
   ```sh
   keytool -genkey -v -keystore /secure/path/abyssal-sovereign-release.jks -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```
   Configure `release/keystore` and credentials via local Godot Editor Export settings (`export_presets.cfg` must never commit keystore paths/passwords) and sign/verify externally with `apksigner sign` + `apksigner verify --verbose`.
3. **Uninstall:** Uninstall "Abyssal Sovereign" from Android App Info / Settings. App-private saves are removed by Android on uninstall unless backed up first.

### Web (Offline HTML5 / PWA Zip)
> Note: Web export succeeded, but **browser runtime and IndexedDB save persistence have not yet been tested (`NOT_RUN`)**.

1. Extract `abyssal-sovereign-v1.0.0-rc.1-web.zip` into a directory and serve it over HTTP/HTTPS (browsers restrict WebAssembly/PWA loading on `file://` URLs):
   ```sh
   python3 -m http.server 8080
   ```
2. Open `http://localhost:8080/index.html` in a modern WebGL2-capable browser. PWA manifest icons (`144x144`, `180x180`, `512x512`) support home-screen installation and offline caching once loaded over HTTPS or `localhost`.
3. **Uninstall / Clear Local Data:** Clear site data / IndexedDB storage for the origin in browser settings.

---

## 2. Save Locations, Backup & Upgrade Compatibility

All runtime files live under Godot's `user://` directory — **separate from the game executable folder**, so upgrading or reinstalling never overwrites saves or settings:

| Platform | Default `user://` Directory |
|---|---|
| **Linux** | `$XDG_DATA_HOME/godot/app_userdata/Abyssal Sovereign/` (usually `~/.local/share/godot/app_userdata/Abyssal Sovereign/`) |
| **Windows** | `%APPDATA%\Godot\app_userdata\Abyssal Sovereign\` |
| **Android** | App-internal storage (`org.veneficalux.abyssalsovereign`) |
| **Web** | Browser IndexedDB (`/userfs`) |

Files stored in `user://`:
- `world.sav` (active run state, Save Version `12`)
- `settings.cfg` (display, audio, accessibility, controls, hints — persists independently across permadeath)
- `codex.json` (persistent discovery/ending records)

### Backup, Recovery & Upgrades
- **Backup:** Copy `settings.cfg`, `codex.json`, and `world.sav` from the OS `user://` folder while the game is closed. Note that **permadeath** deletes `world.sav` upon death or victory.
- **Recovery / Corrupt Save Handling:** If a save file cannot be parsed or fails structural checks, the game rejects corruption safely rather than overwriting `settings.cfg` or `codex.json`. Restore a backed-up `world.sav` if needed, or start a new descent.
- **Upgrade Compatibility (`v1`–`v12`):** `SaveIO` (`World.SAVE_VERSION := 12`) preserves automatic migration paths from save versions `1` through `12`. Replacing the portable binary keeps all existing `user://` files compatible.

---

## 3. Offline Operation Guarantee

- Zero telemetry, analytics SDKs, crash-upload endpoints, or advertising libraries.
- All sprite atlases, woodcut emblems, audio assets, localized narrative strings, and game tables load strictly from embedded/packaged local resources (`res://`).
