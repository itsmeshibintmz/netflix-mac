#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Desktop/netflix-mac-release}"

: "${SPARKLE_SIGN_UPDATE:?Set SPARKLE_SIGN_UPDATE to the Sparkle sign_update executable}"

for tool in xcodebuild codesign create-dmg swift; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool not found: $tool" >&2
        exit 1
    }
done

if [[ ! -x "$SPARKLE_SIGN_UPDATE" ]]; then
    echo "Sparkle sign_update is not executable: $SPARKLE_SIGN_UPDATE" >&2
    exit 1
fi

BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/netflix-mac-release.XXXXXX")"
trap 'rm -rf -- "$BUILD_ROOT"' EXIT

mkdir -p "$OUTPUT_DIR"
APP_PATH="$BUILD_ROOT/DerivedData/Build/Products/Release/Netflix.app"
STAGING_DIR="$BUILD_ROOT/dmg_temp"
DMG_PATH="$OUTPUT_DIR/Netflix.dmg"
SIGNATURE_PATH="$OUTPUT_DIR/Netflix.dmg.sparkle-signature.txt"
if [[ -e "$DMG_PATH" || -e "$SIGNATURE_PATH" ]]; then
    echo "Refusing to overwrite an existing release artifact in $OUTPUT_DIR" >&2
    exit 1
fi

echo "Building and ad-hoc signing Netflix (not notarized)..."
xcodebuild \
    -project "$ROOT_DIR/NetflixMac.xcodeproj" \
    -scheme Netflix \
    -configuration Release \
    -derivedDataPath "$BUILD_ROOT/DerivedData" \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    DEVELOPMENT_TEAM= \
    clean build

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

DMG_OPTIONS=()
if [[ "${DMG_SKIP_FINDER:-0}" == "1" ]]; then
    DMG_OPTIONS+=(--skip-jenkins)
fi

create-dmg \
    --volname "Netflix" \
    --volicon "$ROOT_DIR/NetflixMac/Resources/DmgVolumeIcon.icns" \
    --background "$ROOT_DIR/NetflixMac/Resources/dmg_background.jpg" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 90 \
    --icon "Netflix.app" 150 200 \
    --app-drop-link 450 200 \
    --hide-extension "Netflix.app" \
    ${DMG_OPTIONS[@]+"${DMG_OPTIONS[@]}"} \
    "$BUILD_ROOT/Netflix.dmg" \
    "$STAGING_DIR/"

echo "Signing the DMG for Sparkle..."
SIGN_ARGS=()
if [[ -n "${SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
    SIGN_ARGS+=(--ed-key-file "$SPARKLE_PRIVATE_KEY_FILE")
fi
if ! SIGNATURE_OUTPUT=$("$SPARKLE_SIGN_UPDATE" ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} "$BUILD_ROOT/Netflix.dmg"); then
    echo "Sparkle signing failed; check the signing key and sign_update output." >&2
    exit 1
fi
SIGNATURE=$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
LENGTH=$(printf '%s\n' "$SIGNATURE_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')
if [[ -z "$SIGNATURE" || "$LENGTH" != "$(stat -f %z "$BUILD_ROOT/Netflix.dmg")" ]]; then
    echo "Sparkle did not return a valid signature and archive length." >&2
    exit 1
fi
PUBLIC_KEY=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$APP_PATH/Contents/Info.plist")
swift "$ROOT_DIR/scripts/verify_update_signature.swift" "$BUILD_ROOT/Netflix.dmg" "$SIGNATURE" "$PUBLIC_KEY"

cp "$BUILD_ROOT/Netflix.dmg" "$DMG_PATH"
printf '%s\n' "$SIGNATURE_OUTPUT" | tee "$SIGNATURE_PATH"

echo "Release artifact for v$VERSION: $DMG_PATH"
echo "Use the Sparkle signature and archive length above when publishing the matching appcast entry."
echo "This ad-hoc-signed release is not notarized; macOS will show a Gatekeeper warning."
