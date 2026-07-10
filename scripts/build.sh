#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/EyeBreak.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_FILE="$BUILD_DIR/AppIcon.icns"
ICON_GENERATOR="$BUILD_DIR/generate_icon"
INFO_PLIST="$BUILD_DIR/Info.plist"
VERSION_FILE="$ROOT_DIR/VERSION"
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

cp "$ROOT_DIR/Info.plist" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFO_PLIST"

swiftc \
  "$ROOT_DIR/scripts/generate_icon.swift" \
  -o "$ICON_GENERATOR" \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -framework AppKit

rm -rf "$ICONSET_DIR" "$ICON_FILE"
"$ICON_GENERATOR" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"

swiftc \
  "$ROOT_DIR"/Sources/EyeBreak/*.swift \
  -o "$MACOS_DIR/EyeBreak" \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -framework AppKit \
  -framework CoreGraphics \
  -framework IOKit \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "$INFO_PLIST"

cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
printf "APPL????" > "$CONTENTS_DIR/PkgInfo"
touch "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built: $APP_DIR"
echo "Version: $VERSION ($BUILD_NUMBER)"
