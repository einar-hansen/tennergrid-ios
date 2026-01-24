# Sound Assets for Tenner Grid

This directory contains all sound effects used in the Tenner Grid app.

## Required Sound Files

The following sound files are required for the app. Each should be in `.mp3` or `.wav` format, optimized for iOS (small file size, appropriate quality).

### 1. click.mp3
- **Purpose**: General button tap and UI interaction feedback
- **Duration**: 50-100ms
- **Type**: Subtle click or tap sound
- **Usage**: Number pad buttons, toolbar buttons, general UI interactions

### 2. error.mp3
- **Purpose**: Invalid move or constraint violation feedback
- **Duration**: 200-300ms
- **Type**: Error/warning sound (not too harsh)
- **Usage**: When user makes an invalid move, violates game rules

### 3. success.mp3
- **Purpose**: Puzzle completion and achievement unlocks
- **Duration**: 500-1000ms
- **Type**: Pleasant, celebratory sound
- **Usage**: Completing a puzzle, unlocking achievements

### 4. button_tap.mp3
- **Purpose**: Alternative button sound for secondary actions
- **Duration**: 50-100ms
- **Type**: Soft button press
- **Usage**: Settings toggles, menu buttons, non-critical interactions

## Audio Specifications

- **Format**: MP3 (preferred) or WAV
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128 kbps (MP3) or 16-bit (WAV)
- **Channels**: Mono (to reduce file size)
- **Volume**: Normalized to -3dB to prevent clipping

## Adding Sound Files

To add sound files to the project:

1. Export/create each sound file with the exact filename listed above
2. Add the files to this directory
3. In Xcode, select the TennerGrid target
4. Go to Build Phases → Copy Bundle Resources
5. Add the sound files to ensure they're included in the app bundle

## Sound Sources

You can create or obtain sound files from:
- **Free Resources**: freesound.org, zapsplat.com, soundbible.com
- **Paid Resources**: AudioJungle, Pond5
- **Create Your Own**: Using GarageBand, Audacity, or other audio software
- **iOS System Sounds**: Use UIKit system sounds as references

## Testing

After adding sound files:
1. Build the project to ensure files are bundled
2. Test with `SoundManager.shared.play(.click)` etc.
3. Verify sounds respect the user's sound settings toggle
4. Test volume levels are appropriate (not too loud/quiet)

## Legal

Ensure all sound files are:
- Royalty-free, or
- Properly licensed for commercial use, or
- Created by you (original work)

Include license information in `LICENSES.txt` if using third-party sounds.
