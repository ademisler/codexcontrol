#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/Build/CodexGauge.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/CodexGauge" "$MACOS_DIR/CodexGauge"
cp "$ROOT_DIR/Support/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
