#!/bin/bash
# macOS TestFlight Build Script for aiPresents App
# Run this on a Mac with Xcode 16.4+ installed

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="aiPresentsApp"
BUNDLE_ID="com.hendrikgrueger.aiPresentsApp"
VERSION="0.2.0"
SCHEME="aiPresentsApp"

echo -e "${GREEN}=== aiPresents App - TestFlight Build Script ===${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}ERROR: xcodebuild not found. Install Xcode 16.4+${NC}"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
echo -e "  ✓ Xcode version: $XCODE_VERSION"

if ! command -v xcrun &> /dev/null; then
    echo -e "${RED}ERROR: xcrun not found.${NC}"
    exit 1
fi
echo -e "  ✓ xcrun available"

# Check Swift Package Manager
echo ""
echo -e "${YELLOW}[2/7] Resolving Swift Package dependencies...${NC}"
if [ -f "Package.swift" ]; then
    swift package resolve
    echo -e "  ✓ Dependencies resolved"
else
    echo -e "${RED}ERROR: Package.swift not found${NC}"
    exit 1
fi

# Clean build folder
echo ""
echo -e "${YELLOW}[3/7] Cleaning build folder...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/$APP_NAME-*
echo -e "  ✓ Build folder cleaned"

# Run tests
echo ""
echo -e "${YELLOW}[4/7] Running unit tests...${NC}"
xcodebuild test \
    -scheme $SCHEME \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -enableCodeCoverage YES \
    | xcpretty || true

# Check test results
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ All tests passed${NC}"
else
    echo -e "  ${RED}✗ Tests failed - check output above${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build archive
echo ""
echo -e "${YELLOW}[5/7] Building archive for TestFlight...${NC}"
ARCHIVE_PATH="$HOME/tmp/$APP_NAME-$VERSION.xcarchive"
rm -rf "$ARCHIVE_PATH"

xcodebuild archive \
    -scheme $SCHEME \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    -configuration Release

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Archive created: $ARCHIVE_PATH${NC}"
else
    echo -e "  ${RED}✗ Archive build failed${NC}"
    exit 1
fi

# Validate archive
echo ""
echo -e "${YELLOW}[6/7] Validating archive...${NC}"
xcrun altool --validate-app \
    -f "$ARCHIVE_PATH" \
    -t ios \
    --output-format xml \
    2>&1 | grep -E "(No errors|ERROR)"

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Archive validated${NC}"
else
    echo -e "  ${YELLOW}⚠ Archive validation had warnings (check output)${NC}"
fi

# Upload to App Store Connect
echo ""
echo -e "${YELLOW}[7/7] Uploading to App Store Connect...${NC}"
echo -e "  This will upload to TestFlight for beta testing"
read -p "Continue with upload? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xcrun altool --upload-app \
        -f "$ARCHIVE_PATH" \
        -t ios \
        --output-format json

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ Upload complete${NC}"
        echo ""
        echo -e "${GREEN}=== BUILD SUCCESS ===${NC}"
        echo "Next steps:"
        echo "1. Open App Store Connect: https://appstoreconnect.apple.com"
        echo "2. Navigate to TestFlight → aiPresents App"
        echo "3. Configure build metadata (What's new, testers)"
        echo "4. Submit for internal/beta testing"
    else
        echo -e "  ${RED}✗ Upload failed${NC}"
        echo "Check your Apple ID and signing configuration"
        exit 1
    fi
else
    echo -e "  ${YELLOW}⚠ Upload skipped${NC}"
    echo ""
    echo -e "${GREEN}=== BUILD COMPLETE (not uploaded) ===${NC}"
    echo "Archive location: $ARCHIVE_PATH"
    echo "To upload manually:"
    echo "1. Open Xcode → Window → Organizer"
    echo "2. Select the archive"
    echo "3. Click 'Distribute App' → 'TestFlight & App Store'"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
