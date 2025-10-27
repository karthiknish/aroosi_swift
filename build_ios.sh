#!/bin/bash

# Aroosi iOS Build Script
# This script builds the Aroosi iOS app with the native assets fix applied

echo "🚀 Building Aroosi iOS App (iPhone-only)..."
echo "📱 Device Family: iPhone only"
echo "🔧 Build Type: $1"
echo "🔧 Native Assets: Disabled (Flutter 3.35.4 fix)"

case "$1" in
    "debug")
        echo "🔨 Building Debug..."
        flutter build ios --debug --no-codesign --dart-define=FLUTTER_NATIVE_ASSETS=false
        ;;
    "profile")
        echo "🔨 Building Profile (Production Recommended)..."
        flutter build ios --profile --no-codesign --dart-define=FLUTTER_NATIVE_ASSETS=false
        ;;
    "release")
        echo "⚠️  Release build not recommended due to Flutter 3.35.4 bug"
        echo "🔨 Building Release with workaround..."
        flutter build ios --release --no-codesign --dart-define=FLUTTER_NATIVE_ASSETS=false
        ;;
    *)
        echo "Usage: $0 {debug|profile|release}"
        echo "Recommended: ./build_ios.sh profile"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo "✅ Build Successful!"
    echo "📁 Build location: build/ios/iphoneos/Runner.app"
    echo "🍎 Next steps: Open ios/Runner.xcworkspace in Xcode to archive and upload to App Store"
else
    echo "❌ Build Failed!"
    exit 1
fi