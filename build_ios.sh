#!/bin/bash

set -euo pipefail

# Native SwiftUI iOS build helper
# Usage: ./build_ios.sh [debug|release]

CONFIG_RAW=${1:-release}

case "${CONFIG_RAW,,}" in
    debug)
        CONFIG="Debug"
        ;;
    release|profile)
        CONFIG="Release"
        ;;
    *)
        echo "Unknown build configuration: ${CONFIG_RAW}" >&2
        echo "Usage: $0 [debug|release]" >&2
        exit 1
        ;;
esac

PROJECT_PATH="native_ios/iOSApp/AroosiApp.xcodeproj"
SCHEME="AroosiApp"
DERIVED_DATA="native_ios/DerivedData"

echo "� Building native iOS app"
echo "📦 Scheme: ${SCHEME}"
echo "⚙️  Configuration: ${CONFIG}"

xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIG}" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "${DERIVED_DATA}" \
    clean build

APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIG}-iphoneos/${SCHEME}.app"

if [ -d "${APP_PATH}" ]; then
    echo "✅ Build succeeded"
    echo "📁 Built app: ${APP_PATH}"
else
    echo "⚠️ Build finished but the expected app bundle was not found." >&2
    exit 1
fi