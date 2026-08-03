#!/bin/bash

# Exit on error
set -e

# Change directory to the repository root
cd "$(dirname "$0")"

echo "🏗️ Building Netflix for macOS (Release build)..."
# Build a clean Release binary into a local build folder
xcodebuild -scheme Netflix -configuration Release -derivedDataPath ./build -destination 'platform=macOS' clean build > /dev/null

echo "📦 Packaging custom branded DMG..."
# Cleanup old DMG
rm -f ~/Desktop/Netflix.dmg

# Deep code sign app bundle and embedded frameworks (Sparkle) with ad-hoc signature
echo "🔐 Deep signing app bundle and embedded frameworks..."
codesign --force --deep --sign - "./build/Build/Products/Release/Netflix.app"

# Create temp source directory for packaging
mkdir -p ./build/dmg_temp
cp -R "./build/Build/Products/Release/Netflix.app" ./build/dmg_temp/

# Build the custom styled DMG
create-dmg \
  --volname "Netflix" \
  --volicon "./NetflixMac/Resources/DmgVolumeIcon.icns" \
  --background "./NetflixMac/Resources/dmg_background.jpg" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 90 \
  --icon "Netflix.app" 150 200 \
  --app-drop-link 450 200 \
  --hide-extension "Netflix.app" \
  ~/Desktop/Netflix.dmg \
  ./build/dmg_temp/

echo "🏷️ Setting custom Desktop icon for the DMG file..."
# Apply the custom disk icon to the .dmg file itself
swift -e 'import Cocoa; let img = NSImage(contentsOfFile: "./NetflixMac/Resources/DmgVolumeIcon.icns"); NSWorkspace.shared.setIcon(img, forFile: "/Users/shibin_tmz/Desktop/Netflix.dmg", options: [])'

echo "🔏 Signing DMG package with Sparkle EdDSA key..."
if [ -f "/tmp/sparkle_tools/bin/sign_update" ]; then
    /tmp/sparkle_tools/bin/sign_update ~/Desktop/Netflix.dmg
fi

echo "🧹 Cleaning up build caches..."
rm -rf ./build

echo "✅ Branded DMG successfully generated on Desktop!"
