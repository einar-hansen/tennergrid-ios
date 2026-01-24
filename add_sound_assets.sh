#!/bin/bash

# Script to add sound assets to Xcode project
# This script helps ensure sound files are properly included in the app bundle

set -e

SOUNDS_DIR="TennerGrid/TennerGrid/Resources/Sounds"
PROJECT_FILE="TennerGrid.xcodeproj/project.pbxproj"

echo "Adding sound assets to Xcode project..."

# Check if sound files exist
if [ ! -d "$SOUNDS_DIR" ]; then
    echo "Error: Sounds directory not found at $SOUNDS_DIR"
    exit 1
fi

# List sound files
echo "Found sound files:"
ls -1 "$SOUNDS_DIR"/*.mp3 2>/dev/null || echo "No .mp3 files found"

echo ""
echo "To add these files to your Xcode project:"
echo "1. Open TennerGrid.xcodeproj in Xcode"
echo "2. Select the TennerGrid folder in the Project Navigator"
echo "3. Right-click and select 'Add Files to TennerGrid...'"
echo "4. Navigate to TennerGrid/Resources/Sounds"
echo "5. Select all .mp3 files"
echo "6. Ensure 'Copy items if needed' is UNCHECKED (files are already in the right place)"
echo "7. Ensure 'Create groups' is selected"
echo "8. Ensure 'TennerGrid' target is checked"
echo "9. Click Add"
echo ""
echo "Alternatively, drag the Sounds folder from Finder directly into the"
echo "Xcode Project Navigator under Resources."
echo ""
echo "After adding, verify the files appear in:"
echo "  Build Phases → Copy Bundle Resources"

exit 0
