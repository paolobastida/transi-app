#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP="dist-mac/Transi.app"
ICONSET="$(mktemp -d)/Transi.iconset"

if [[ "${SKIP_TYPECHECK:-0}" == "1" ]]; then
  echo "→ Compilando frontend (sin typecheck)…"
  pnpm exec vite build
else
  echo "→ Compilando frontend…"
  pnpm build
fi

echo "→ Armando bundle nativo…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -R dist "$APP/Contents/Resources/dist"
cp macos/Info.plist "$APP/Contents/Info.plist"

mkdir -p "$ICONSET"
icon() {
  local size="$1"
  local name="$2"
  sips -z "$size" "$size" public/icono-512.png --out "$ICONSET/$name" >/dev/null
}
icon 16 icon_16x16.png
icon 32 icon_16x16@2x.png
icon 32 icon_32x32.png
icon 64 icon_32x32@2x.png
icon 128 icon_128x128.png
icon 256 icon_128x128@2x.png
icon 256 icon_256x256.png
icon 512 icon_256x256@2x.png
icon 512 icon_512x512.png
icon 1024 icon_512x512@2x.png
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Transi.icns"

echo "→ Compilando app Swift…"
swiftc -O -parse-as-library \
  -framework Cocoa \
  -framework WebKit \
  -framework Network \
  -framework UserNotifications \
  macos/Transi.swift \
  macos/Recordatorios.swift \
  -o "$APP/Contents/MacOS/Transi"

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ Listo: $APP"
echo "  Abrila con: open $APP"
