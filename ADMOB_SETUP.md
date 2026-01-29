# AdMob Integration Setup Guide

## Phase 13.1 - AdMob Account Setup
- [x] AdMob Account Created
- [x] App ID Registered: `ca-app-pub-5084681690392665~7594806874`

## Phase 13.2 - Add Google Mobile Ads SDK

### Step 1: Add Swift Package Dependency in Xcode

1. Open `TennerGrid.xcodeproj` in Xcode
2. Select the project in the Project Navigator
3. Select the "TennerGrid" target
4. Go to "Package Dependencies" tab
5. Click the "+" button to add a package
6. Enter the Google Mobile Ads SDK URL:
   ```
   https://github.com/googleads/swift-package-manager-google-mobile-ads.git
   ```
7. Select "Up to Next Major Version" with version `11.0.0` (or latest)
8. Click "Add Package"
9. In the "Add to Target" dialog, make sure "TennerGrid" is checked
10. Click "Add Package"

### Step 2: Configure Info.plist

The AdMob App ID needs to be added to Info.plist. Since this project uses `GENERATE_INFOPLIST_FILE = YES`, we need to add it via build settings:

1. Select the "TennerGrid" target in Xcode
2. Go to the "Info" tab
3. Click the "+" button under "Custom iOS Target Properties"
4. Add key: `GADApplicationIdentifier`
5. Set value: `ca-app-pub-5084681690392665~7594806874`

Alternatively, you can add it to the build settings:
1. Go to Build Settings
2. Search for "Info.plist Values"
3. Add a custom entry:
   - Key: `GADApplicationIdentifier`
   - Value: `ca-app-pub-5084681690392665~7594806874`

### Step 3: Initialize SDK

The Mobile Ads SDK is initialized in `TennerGridApp.swift` on app launch. See the implementation in the app entry point.

### Step 4: Test Installation

Build the project to verify the SDK is properly integrated:
```bash
xcodebuild -scheme TennerGrid -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Ad Unit IDs

For testing, use Google's test ad unit IDs:
- Banner: `ca-app-pub-3940256099942544/2934735716`
- Interstitial: `ca-app-pub-3940256099942544/4411468910`
- Rewarded: `ca-app-pub-3940256099942544/1712485313`

Production ad unit IDs will be created in AdMob console after app review.

### Resources

- [Google Mobile Ads SDK Documentation](https://developers.google.com/admob/ios/quick-start)
- [Swift Package Manager Integration](https://developers.google.com/admob/ios/quick-start#swift_package_manager)
- [AdMob Console](https://apps.admob.com/)
