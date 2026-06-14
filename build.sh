#!/bin/bash
set -e

# Define paths
WORKSPACE_DIR="/Users/farchan/Xcode/sniper"
BUILD_DIR="$WORKSPACE_DIR/.build"
RELEASE_BIN="$BUILD_DIR/release/SuperSniper"
APP_BUNDLE="$WORKSPACE_DIR/bin/SuperSniper.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Building SuperSniper executable in release mode..."
swift build -c release --scratch-path "$BUILD_DIR"

echo "Creating SuperSniper.app directory structure..."
mkdir -p "$MACOS_DIR"

echo "Copying compiled executable..."
cp "$RELEASE_BIN" "$MACOS_DIR/SuperSniper"
chmod +x "$MACOS_DIR/SuperSniper"

echo "Copying Info.plist..."
cp "$WORKSPACE_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Code signing app bundle (ad-hoc) to preserve permissions..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "SuperSniper.app built successfully at $APP_BUNDLE!"
echo "You can run it using: open $APP_BUNDLE"
