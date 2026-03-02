#!/bin/bash
# macOS Xcode Project Setup Script
# Creates Xcode App Target from Swift Package for TestFlight Release

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== aiPresents App - Xcode Setup Script ===${NC}"
echo ""
echo "This script will guide you through creating an Xcode App Target"
echo "for TestFlight release from the existing Swift Package."
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode not found. Please install Xcode 16.4+ from App Store"
    exit 1
fi

echo -e "${YELLOW}=== STEP 1: Create Xcode Project ===${NC}"
echo ""
echo "Run these commands in Terminal:"
echo ""
echo "1. Navigate to project directory:"
echo "   cd /path/to/ai-presents-app-ios"
echo ""
echo "2. Create Xcode project with App Target:"
echo "   # This will create aiPresentsApp.xcodeproj"
echo ""
echo "3. Open in Xcode:"
echo "   open aiPresentsApp.xcodeproj"
echo ""

echo -e "${YELLOW}=== STEP 2: Configure App Target ===${NC}"
echo ""
echo "In Xcode:"
echo ""
echo "1. File → New → Target → iOS → App"
echo "   - Product Name: aiPresentsApp"
echo "   - Bundle Identifier: com.hendrikgrueger.aiPresentsApp"
echo "   - Language: Swift"
echo "   - Interface: SwiftUI"
echo "   - Use Core Data: ✗ (we use SwiftData)"
echo "   - Include Tests: ✓"
echo ""
echo "2. Link Swift Package to App Target:"
echo "   - Select aiPresentsApp target"
echo "   - Build Phases → Link Binary With Libraries"
echo "   - Add aiPresentsApp from Package"
echo ""

echo -e "${YELLOW}=== STEP 3: Add App Icon & Assets ===${NC}"
echo ""
echo "1. Create Assets.xcassets:"
echo "   - File → New → File → Asset Catalog"
echo "   - Add AppIcon set"
echo "   - Add icons: 1024x1024 (App Store), 60x60@2x, 60x60@3x"
echo "   - Design reference: APP_ICON.md"
echo ""
echo "2. Add Launch Screen:"
echo "   - File → New → File → Launch Screen"
echo "   - Simple design with app name"
echo ""

echo -e "${YELLOW}=== STEP 4: Configure Signing ===${NC}"
echo ""
echo "1. Select aiPresentsApp target"
echo "2. Signing & Capabilities"
echo "3. Team: [Select your Apple Developer Team]"
echo "4. Bundle Identifier: com.hendrikgrueger.aiPresentsApp"
echo "5. Add Capabilities:"
echo "   - Contacts (Privacy - Contacts Usage Description)"
echo "   - Push Notifications"
echo "   - iCloud (CloudKit)"
echo "   - In-App Purchase (if needed later)"
echo ""

echo -e "${YELLOW}=== STEP 5: Copy Info.plist Configuration ===${NC}"
echo ""
echo "1. Open App/Info.plist in project"
echo "2. Copy permissions descriptions to your Xcode target's Info.plist:"
echo "   - NSContactsUsageDescription"
echo "   - NSUserNotificationsUsageDescription"
echo "   - NSUbiquitousContainersUsageDescription"
echo ""

echo -e "${YELLOW}=== STEP 6: Test Local Build ===${NC}"
echo ""
echo "1. Product → Run (or Cmd+R)"
echo "2. Test on iPhone Simulator"
echo "3. Verify all features work"
echo "4. Product → Test (or Cmd+U) to run tests"
echo ""

echo -e "${YELLOW}=== STEP 7: Prepare for TestFlight ===${NC}"
echo ""
echo "1. Set version to 0.2.0 in target settings"
echo "2. Enable automatic build numbering"
echo "3. Run: ./scripts/macos-testflight-build.sh"
echo ""

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "After completing these steps:"
echo "1. Review TESTFLIGHT.md checklist"
echo "2. Run the TestFlight build script"
echo "3. Upload to App Store Connect"
echo ""
echo "Need help? See DEVELOPMENT.md or create an issue on GitHub"
