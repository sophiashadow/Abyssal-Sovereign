#!/usr/bin/env bash
# Build all four platform targets and stage portable RC packages + SHA256SUMS.
# Usage: tools/package_rc.sh [version_tag]   (default: v1.0.0-rc.1)
set -eu
cd "$(dirname "$0")/.."

VERSION="${1:-v1.0.0-rc.1}"
PREFIX="abyssal-sovereign-$VERSION"
OUT_DIR="build/release"
STAGE="build/_rc_stage"

echo "==> 1. Exporting Linux, Windows, Web, Android"
./tools/export.sh all

APK="build/android/abyssal-sovereign-debug.apk"
[ -f "$APK" ] || { echo "FAIL: missing APK $APK" >&2; exit 1; }

echo "==> 2. Checking APK contents for leaked development files"
APK_LIST="$(unzip -l "$APK")"
if printf '%s\n' "$APK_LIST" | grep -qE 'assets/(balance|docs|content/lore|tests|tools|release)/|assets/[^ ]*\.md|\.git/'; then
  echo "FAIL: internal development files leaked into APK:" >&2
  printf '%s\n' "$APK_LIST" | grep -E 'assets/(balance|docs|content/lore|tests|tools|release)/|assets/[^ ]*\.md|\.git/' >&2
  exit 1
fi
for req in "assets/content/core/species.json" "assets/content/presentation/soundtrack_manifest.json" "assets/assets/icons/icon_512.png"; do
  printf '%s\n' "$APK_LIST" | grep -q "$req" || { echo "FAIL: missing $req in APK" >&2; exit 1; }
done
echo "APK hygiene check passed."

echo "==> 3. Staging portable packages in $OUT_DIR"
rm -rf "$OUT_DIR" "$STAGE"
mkdir -p "$OUT_DIR" "$STAGE"

copy_docs() {
  local dest="$1"
  cp docs/INSTALL.md "$dest/INSTALL.txt"
  [ -f docs/release/RELEASE_NOTES.md ] && cp docs/release/RELEASE_NOTES.md "$dest/RELEASE_NOTES.txt" || true
  [ -f docs/release/PRIVACY.md ] && cp docs/release/PRIVACY.md "$dest/PRIVACY.txt" || true
  [ -f docs/release/CREDITS_AND_LICENSES.md ] && cp docs/release/CREDITS_AND_LICENSES.md "$dest/CREDITS_AND_LICENSES.txt" || true
  if grep -rnE '/(home|Users)/[^/ ]+' "$dest"/*.txt >/dev/null 2>&1; then
    echo "FAIL: private home path detected in staged release text files ($dest)" >&2
    grep -rnE '/(home|Users)/[^/ ]+' "$dest"/*.txt >&2
    exit 1
  fi
}

# Linux portable tarball
LINUX_DIR="$STAGE/$PREFIX-linux-x86_64"
mkdir -p "$LINUX_DIR"
cp build/linux/abyssal-sovereign.x86_64 "$LINUX_DIR/"
chmod +x "$LINUX_DIR/abyssal-sovereign.x86_64"
cp assets/icons/icon_512.png "$LINUX_DIR/icon_512.png"
cat > "$LINUX_DIR/abyssal-sovereign.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Abyssal Sovereign
Comment=An original traditional roguelike set beneath Terra Tenebrae.
Exec=@EXEC@
Icon=@ICON@
Terminal=false
Categories=Game;RolePlaying;
EOF
copy_docs "$LINUX_DIR"
tar -C "$STAGE" -czf "$OUT_DIR/$PREFIX-linux-x86_64.tar.gz" "$PREFIX-linux-x86_64"

# Windows portable zip
WIN_DIR="$STAGE/$PREFIX-windows-x86_64"
mkdir -p "$WIN_DIR"
cp build/windows/abyssal-sovereign.exe "$WIN_DIR/"
copy_docs "$WIN_DIR"
(cd "$STAGE" && zip -qr "../release/$PREFIX-windows-x86_64.zip" "$PREFIX-windows-x86_64")

# Web offline zip
WEB_DIR="$STAGE/$PREFIX-web"
mkdir -p "$WEB_DIR"
cp -R build/web/. "$WEB_DIR/"
copy_docs "$WEB_DIR"
(cd "$STAGE" && zip -qr "../release/$PREFIX-web.zip" "$PREFIX-web")

# Android APK
cp "$APK" "$OUT_DIR/$PREFIX-android-debug.apk"

# Clean staging & verify archive zero-leak
rm -rf "$STAGE"
if tar -tzf "$OUT_DIR/$PREFIX-linux-x86_64.tar.gz" | grep -qE '(^|/)(balance|docs|content/lore|tests|tools)/|\.git/'; then
  echo "FAIL: internal directory leaked into Linux tarball" >&2; exit 1
fi
for z in "$OUT_DIR/$PREFIX-windows-x86_64.zip" "$OUT_DIR/$PREFIX-web.zip"; do
  if unzip -l "$z" | grep -qE '(balance|content/lore|tests|tools)/|\.git/'; then
    echo "FAIL: internal directory leaked into $z" >&2; exit 1
  fi
done

echo "==> 4. Writing and verifying SHA256SUMS.txt"
(cd "$OUT_DIR" && sha256sum "$PREFIX-"* > SHA256SUMS.txt && sha256sum -c SHA256SUMS.txt)
ls -lh "$OUT_DIR"
