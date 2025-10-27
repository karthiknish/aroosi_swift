#!/bin/bash

# Flutter Environment Setup Script for Native iOS
# This script configures the native iOS app to use the same environment as the Flutter app

set -e

echo "🔄 Setting up Flutter environment configuration for Native iOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_PROJECT_ROOT="$(cd "$PROJECT_ROOT/../../aroosi_flutter" && pwd)"
ENV_FILE="$PROJECT_ROOT/Sources/Resources/App.env"
FLUTTER_ENV_FILE="$FLUTTER_PROJECT_ROOT/.env"

echo -e "${BLUE}Project Root:${NC} $PROJECT_ROOT"
echo -e "${BLUE}Flutter Project:${NC} $FLUTTER_PROJECT_ROOT"
echo -e "${BLUE}Environment File:${NC} $ENV_FILE"
echo ""

# Check if Flutter project exists
if [ ! -d "$FLUTTER_PROJECT_ROOT" ]; then
    echo -e "${RED}❌ Flutter project not found at $FLUTTER_PROJECT_ROOT${NC}"
    exit 1
fi

# Check if Flutter .env file exists
if [ ! -f "$FLUTTER_ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Flutter .env file not found at $FLUTTER_ENV_FILE${NC}"
    echo "Creating environment file from Flutter configuration..."
    
    # Create basic environment file based on Flutter defaults
    cat > "$ENV_FILE" << 'EOF'
# Environment configuration synced from Flutter app
ENVIRONMENT=production
API_BASE_URL=

# Firebase configuration (aligned with Flutter)
FIREBASE_STORAGE_BUCKET=aroosi-ios.firebasestorage.app
FIREBASE_IOS_PROJECT_ID=aroosi-ios
FIREBASE_IOS_BUNDLE_ID=com.aroosi.mobile
FIREBASE_IOS_MEASUREMENT_ID=G-LW4V9JBD39

# Subscription settings (from Flutter)
SUBSCRIPTIONS_ENABLED=false

# Apple Sign In / Google configuration
GOOGLE_WEB_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=

# Firebase iOS configuration (provided securely at build time)
FIREBASE_IOS_GOOGLE_APP_ID=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_GCM_SENDER_ID=

# App identifiers
IOS_APP_IDENTIFIER=

# Premium subscription
SUBSCRIPTION_STATUS_PATH=/users/me/subscription
SUBSCRIPTION_MANAGE_URL=https://www.aroosi.app/account/subscription

# Onboarding fallback content
ONBOARDING_TITLE=Discover curated matches
ONBOARDING_TAGLINE=Thoughtful introductions rooted in shared values.
ONBOARDING_CTA=Get Started
ONBOARDING_HERO_URL=
EOF
    
    echo -e "${GREEN}✅ Created environment file with Flutter defaults${NC}"
else
    echo -e "${GREEN}✅ Found Flutter .env file${NC}"
    
    # Read Flutter environment variables
    echo "📖 Reading Flutter environment configuration..."
    
    # Extract key environment variables from Flutter .env
    FLUTTER_ENV=$(grep -E "^(ENVIRONMENT|API_BASE_URL|FIREBASE_STORAGE_BUCKET|SUBSCRIPTIONS_ENABLED)" "$FLUTTER_ENV_FILE" || true)
    
    echo -e "${BLUE}Flutter Environment:${NC}"
    echo "$FLUTTER_ENV"
    echo ""
    
    # Backup existing environment file
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}⚠️  Backed up existing environment file${NC}"
    fi
    
    # Create new environment file with Flutter values
    cat > "$ENV_FILE" << EOF
# Environment configuration synced from Flutter app
# Generated on $(date)

# Core environment (from Flutter)
$FLUTTER_ENV

# Firebase configuration (aligned with Flutter)
FIREBASE_STORAGE_BUCKET=aroosi-ios.firebasestorage.app
FIREBASE_IOS_PROJECT_ID=aroosi-ios
FIREBASE_IOS_BUNDLE_ID=com.aroosi.mobile
FIREBASE_IOS_MEASUREMENT_ID=G-LW4V9JBD39

# Apple Sign In / Google configuration
GOOGLE_WEB_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=

# Firebase iOS configuration (provided securely at build time)
FIREBASE_IOS_GOOGLE_APP_ID=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_GCM_SENDER_ID=

# App identifiers
IOS_APP_IDENTIFIER=

# Premium subscription
SUBSCRIPTION_STATUS_PATH=/users/me/subscription
SUBSCRIPTION_MANAGE_URL=https://www.aroosi.app/account/subscription

# Onboarding fallback content
ONBOARDING_TITLE=Discover curated matches
ONBOARDING_TAGLINE=Thoughtful introductions rooted in shared values.
ONBOARDING_CTA=Get Started
ONBOARDING_HERO_URL=
EOF
    
    echo -e "${GREEN}✅ Updated environment file with Flutter configuration${NC}"
fi

echo ""
echo -e "${BLUE}📋 Environment Configuration Summary:${NC}"
echo "=================================="

# Display current configuration
if [ -f "$ENV_FILE" ]; then
    echo "Environment: $(grep "^ENVIRONMENT=" "$ENV_FILE" | cut -d'=' -f2)"
    echo "API Base URL: $(grep "^API_BASE_URL=" "$ENV_FILE" | cut -d'=' -f2)"
    echo "Storage Bucket: $(grep "^FIREBASE_STORAGE_BUCKET=" "$ENV_FILE" | cut -d'=' -f2)"
    echo "Subscriptions: $(grep "^SUBSCRIPTIONS_ENABLED=" "$ENV_FILE" | cut -d'=' -f2)"
    echo "Firebase Project: $(grep "^FIREBASE_IOS_PROJECT_ID=" "$ENV_FILE" | cut -d'=' -f2)"
    echo "Bundle ID: $(grep "^FIREBASE_IOS_BUNDLE_ID=" "$ENV_FILE" | cut -d'=' -f2)"
else
    echo -e "${RED}❌ Environment file not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the environment file: $ENV_FILE"
echo "2. Update any missing values (Google client IDs, Firebase config, etc.)"
echo "3. Build and test the app"
echo ""
echo -e "${YELLOW}Note: Firebase configuration values should be provided securely at build time${NC}"
echo "      through Xcode build settings or secure CI/CD environment variables."
