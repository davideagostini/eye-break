#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_NAME="EyeBreak"
VOLUME_NAME="Eye Break"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_ROOT="$BUILD_DIR/dmg"
DMG_STAGE="$DMG_ROOT/$VOLUME_NAME"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

"$ROOT_DIR/scripts/build.sh"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_STAGE" "$DIST_DIR"
cp -R "$APP_DIR" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Built: $DMG_PATH"
