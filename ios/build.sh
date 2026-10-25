#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ Compilando la app web…"
pnpm build

echo "→ Preparando recursos de iOS…"
mkdir -p ios/Resources
rm -rf ios/Resources/dist
cp -R dist ios/Resources/dist

echo "→ Generando el proyecto Xcode…"
xcodegen generate --spec ios/project.yml

DESTINO="${1:-generic/platform=iOS Simulator}"
echo "→ Compilando para ${DESTINO}…"
xcodebuild -project ios/Transi.xcodeproj -scheme Transi -configuration Debug \
  -destination "$DESTINO" -derivedDataPath ios/build build

echo "✓ Compilación lista. Para instalar en un iPhone hace falta seleccionar tu equipo y firma en Xcode."
