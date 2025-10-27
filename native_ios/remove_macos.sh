#!/bin/bash

echo "🗑️  Removing macOS build configuration..."

# Remove macOS availability attributes from all Swift files
echo "📝 Removing macOS availability attributes..."
find Sources -name "*.swift" -exec sed -i '' 's/@available(iOS [0-9]*, macOS [0-9]*, \*)/@available(iOS \1, *)/g' {} \;
find Sources -name "*.swift" -exec sed -i '' 's/@available(iOS 17, macOS 13, \*)/@available(iOS 17, *)/g' {} \;
find Sources -name "*.swift" -exec sed -i '' 's/@available(iOS 16, macOS 13, \*)/@available(iOS 16, *)/g' {} \;
find Sources -name "*.swift" -exec sed -i '' 's/@available(iOS 15, macOS 12, \*)/@available(iOS 15, *)/g' {} \;
find Sources -name "*.swift" -exec sed -i '' 's/@available(iOS 14, macOS 11, \*)/@available(iOS 14, *)/g' {} \;

# Remove macOS conditional compilation blocks
echo "🔧 Removing macOS conditional compilation..."
find Sources -name "*.swift" -exec sed -i '' '/#if os(macOS)/,/}/d' {} \;

# Remove macOS-only imports
echo "📦 Removing macOS-only imports..."
find Sources -name "*.swift" -exec sed -i '' '/import AppKit/d' {} \;
find Sources -name "*.swift" -exec sed -i '' '/import Cocoa/d' {} \;

# Update platform checks to iOS only
echo "📱 Updating platform checks..."
find Sources -name "*.swift" -exec sed -i '' 's/#if os(iOS) || os(macOS)/#if os(iOS)/g' {} \;
find Sources -name "*.swift" -exec sed -i '' 's/#if os(iOS)/#if os(iOS)/g' {} \;

# Remove macOS-specific framework linking
echo "🔗 Removing macOS frameworks..."
find Sources -name "*.swift" -exec sed -i '' '/\.linkedFramework.*\.when(platforms: \[\.macOS\])/d' {} \;

echo "✅ macOS configuration removed successfully!"
echo "📱 App now builds for iOS only"
