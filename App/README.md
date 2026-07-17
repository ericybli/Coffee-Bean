# Coffee Bean — iOS app

SwiftUI app for iOS 18+ (runs on iOS 26 devices). Consumes the pure-logic
[`CoffeeBeanCore`](../Sources/CoffeeBeanCore) package for all engine/math.

The Xcode project is **generated from `project.yml` by [XcodeGen](https://github.com/yonyz/XcodeGen)** — it is not committed. Regenerate it after pulling or editing `project.yml`.

## Build & run

```bash
# 1. Generate the Xcode project (once, and after any project.yml change)
cd App
xcodegen generate

# 2a. Open in Xcode and press ⌘R
open CoffeeBean.xcodeproj

# 2b. …or build + run headless in a simulator
xcodebuild -project CoffeeBean.xcodeproj -scheme CoffeeBean \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

xcrun simctl bootstatus "iPhone 16 Pro Max" -b
xcrun simctl install "iPhone 16 Pro Max" \
  "$(xcodebuild -project CoffeeBean.xcodeproj -scheme CoffeeBean -showBuildSettings 2>/dev/null | awk -F' = ' '/ CODESIGNING_FOLDER_PATH /{print $2}')"
xcrun simctl launch "iPhone 16 Pro Max" com.ericybli.coffeebean
```

## Structure

```
App/
  project.yml                 # XcodeGen spec (target, deps, capabilities, Info.plist keys)
  CoffeeBean/
    CoffeeBeanApp.swift        # @main App entry
    DesignSystem/Theme.swift   # dark-first color tokens (warm amber accent)
    Navigation/RootTabView.swift   # Food · Water · Body · Train IA
    Features/
      Shared/                  # ScreenScaffold, ComingSoon
      Food/  Water/  Body/  Train/   # per-tab screens
```

## Notes
- Deployment target **iOS 18** (installed SDK is 18.4); runs on iOS 26 devices (forward compatible).
- Signing is disabled for simulator builds. Running on a physical device / enabling HealthKit + CloudKit needs an Apple Developer team + entitlements (added when those features land).
