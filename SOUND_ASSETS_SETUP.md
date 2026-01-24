# Sound Assets Setup Guide

This document explains how to set up sound assets for the Tenner Grid iOS app.

## Overview

The app uses four sound effects for user feedback:
1. **click.mp3** - General button taps and UI interactions
2. **error.mp3** - Invalid moves or constraint violations
3. **success.mp3** - Puzzle completion and achievements
4. **button_tap.mp3** - Secondary action button sounds

## Current Status

✅ Sound asset directory created: `TennerGrid/TennerGrid/Resources/Sounds/`
✅ Placeholder .mp3 files created
✅ `SoundAsset` enum created for type-safe sound management
⏳ Actual audio files need to be added (placeholders are empty files)
⏳ Files need to be added to Xcode project

## Step 1: Obtain or Create Sound Files

### Option A: Use Free Sound Libraries
- Visit [freesound.org](https://freesound.org)
- Visit [zapsplat.com](https://zapsplat.com)
- Search for: "button click", "error beep", "success chime", "tap"
- Download royalty-free sounds matching the descriptions in `Resources/Sounds/README.md`

### Option B: Create Your Own
- Use GarageBand (Mac/iOS)
- Use Audacity (free, cross-platform)
- Record or synthesize simple sound effects

### Sound Specifications
- **Format**: MP3 (preferred) or convert to MP3
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128 kbps
- **Channels**: Mono (reduces file size)
- **Duration**:
  - click/button_tap: 50-100ms
  - error: 200-300ms
  - success: 500-1000ms

## Step 2: Replace Placeholder Files

1. Navigate to `TennerGrid/TennerGrid/Resources/Sounds/`
2. Replace the empty placeholder files with your actual sound files
3. Ensure filenames match exactly:
   - `click.mp3`
   - `error.mp3`
   - `success.mp3`
   - `button_tap.mp3`

## Step 3: Add Files to Xcode Project

### Method 1: Drag and Drop (Recommended)
1. Open `TennerGrid.xcodeproj` in Xcode
2. In Project Navigator, locate the `Resources` folder
3. Open Finder and navigate to `TennerGrid/TennerGrid/Resources/Sounds/`
4. Drag the `Sounds` folder into Xcode's `Resources` folder
5. In the dialog that appears:
   - ✅ Check "Create groups" (not "Create folder references")
   - ✅ Check "TennerGrid" target
   - ❌ Uncheck "Copy items if needed" (files are already in correct location)
6. Click "Finish"

### Method 2: Add Files Menu
1. Open `TennerGrid.xcodeproj` in Xcode
2. Select the `Resources` folder in Project Navigator
3. Go to File → Add Files to "TennerGrid"...
4. Navigate to `TennerGrid/TennerGrid/Resources/Sounds/`
5. Select all `.mp3` files
6. Ensure settings:
   - ❌ Uncheck "Copy items if needed"
   - ✅ Select "Create groups"
   - ✅ Add to target: TennerGrid
7. Click "Add"

## Step 4: Verify Files Are Bundled

1. In Xcode, select the TennerGrid project in Project Navigator
2. Select the "TennerGrid" target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Verify all four .mp3 files are listed:
   - click.mp3
   - error.mp3
   - success.mp3
   - button_tap.mp3

If files are missing, click the "+" button and add them manually.

## Step 5: Test Sound Assets

### In Code
```swift
// In any View or ViewModel
import SwiftUI

// Test that assets exist
let missingAssets = SoundAsset.validateAssets()
if missingAssets.isEmpty {
    print("✅ All sound assets found!")
} else {
    print("❌ Missing sound assets: \(missingAssets)")
}

// Test individual asset
if let clickURL = SoundAsset.click.url {
    print("✅ click.mp3 found at: \(clickURL)")
} else {
    print("❌ click.mp3 not found")
}
```

### Build and Run
1. Build the project (⌘+B)
2. Run on simulator or device (⌘+R)
3. Once `SoundManager` is implemented, sounds will play during gameplay

## Step 6: Legal Compliance

If using third-party sounds:
1. Create a `LICENSES.txt` file in `Resources/`
2. List each sound file with its source and license
3. Example format:

```
Sound Assets Licenses
=====================

click.mp3
- Source: freesound.org/people/username/sounds/123456
- License: CC0 1.0 Universal (Public Domain)
- Author: Username

error.mp3
- Source: zapsplat.com
- License: Standard License
- Author: Zapsplat

success.mp3
- Source: Original work
- License: Created by [Your Name]
- Author: [Your Name]

button_tap.mp3
- Source: freesound.org/people/username/sounds/789012
- License: CC BY 3.0
- Author: Username
- Attribution: "Sound by Username (freesound.org)"
```

## Troubleshooting

### "Sound file not found" errors
- Verify files are in `Copy Bundle Resources` in Build Phases
- Clean build folder: Product → Clean Build Folder (⌘+Shift+K)
- Delete derived data: Xcode → Preferences → Locations → Derived Data → Delete
- Rebuild project

### Sounds don't play
- Check that files are actual audio files (not 0 bytes)
- Verify `SoundManager` is properly implemented
- Check that sound effects setting is enabled
- Test on device (simulator audio can be unreliable)

### Build errors about missing resources
- Verify files are added to the correct target
- Check file paths in Build Phases
- Ensure files are in the project directory, not outside

## Next Steps

After completing this setup:
1. ✅ Mark task "Add sound assets" as complete
2. ➡️ Proceed to implement `SoundManager` service
3. ➡️ Implement sound playback methods
4. ➡️ Integrate sounds with game actions

## Resources

- [Apple Developer - Playing Audio](https://developer.apple.com/documentation/avfoundation/audio_playback_recording_and_processing)
- [Free Sound Effects](https://freesound.org)
- [Zapsplat](https://zapsplat.com)
- [Audio Conversion Tools](https://cloudconvert.com/mp3-converter)
