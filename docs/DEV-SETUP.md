# Coffee Bean — Dev Environment Setup

Two layers:
- **`CoffeeBeanCore`** (the logic package) builds/tests with **just the Xcode Command Line Tools** — via `swift test`. **(But your CLT is currently broken — see §0.)**
- **The iOS app** (SwiftUI + SwiftData + HealthKit) needs **full Xcode + the iOS SDK + a Simulator** (§1+).

---

## 0. ⚠️ First: repair your Command Line Tools (currently broken)

Diagnosis on this machine: the CLT **compiler and macOS SDK are mismatched builds** —
compiler `swiftlang-6.0.3.1.10` vs an SDK built with `swiftlang-6.0.3.1.5`. Result:
**every** Swift compile against the SDK fails with *"failed to build module 'Foundation';
this SDK is not supported by the compiler"*, so `swift build` / `swift test` (and even a
plain `swiftc` of a Foundation program) do not work — including `CoffeeBeanCore`.

Fix with **either** option (both need `sudo`):

**Option A (recommended) — install full Xcode and select it.** Self-consistent toolchain
*and* gives the iOS SDK you need for the app anyway:
```bash
# after installing Xcode from the Mac App Store:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

**Option B (quick) — just reinstall the Command Line Tools:**
```bash
sudo rm -rf /Library/Developer/CommandLineTools
sudo xcode-select --install      # accept the GUI prompt; downloads a fresh, matched CLT
```

**Verify the repair** (either option):
```bash
printf 'import Foundation\nprint("ok")\n' > /tmp/t.swift && swiftc /tmp/t.swift -o /tmp/t && /tmp/t   # -> ok
swift build --package-path /Users/eric/own/Coffee-Bean   # -> builds CoffeeBeanCore
swift test  --package-path /Users/eric/own/Coffee-Bean   # -> runs the Core test suite
```
Once those work, the Core plan is fully executable/verifiable here, and Xcode (Option A)
also unblocks the iOS app below.

---

## Full-Xcode setup for the iOS app

You can install Xcode **in the background** while we sort out the Core toolchain.

---

## 1. Install full Xcode (required for the iOS app)

You currently have only Command Line Tools (`xcode-select -p` → `/Library/Developer/CommandLineTools`).

- Install **Xcode** from the **Mac App Store** (search "Xcode", ~12–17 GB) — or specific versions from <https://developer.apple.com/download/all/>.
- The app targets **iOS 26**, so install the **latest Xcode (Xcode 26.x)**, which bundles the iOS 26 SDK.
- After it finishes, point the toolchain at it and finish first-launch setup:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch          # installs iOS platform support + components
```

- Verify:

```bash
xcodebuild -version                 # should print Xcode 26.x
xcrun simctl list devices available | grep iPhone   # should list iOS simulators
xcodebuild -showsdks | grep -i ios  # should show an iphoneos / iphonesimulator SDK
```

## 2. (Recommended) Homebrew + XcodeGen — lets me generate the app project in code

So the app's Xcode project is reproducible from a checked-in `project.yml` (not hand-clicked):

```bash
# Homebrew (skip if you already have `brew`): see https://brew.sh
xcodegen --version || brew install xcodegen
```

With `xcodegen` present, I'll write a `project.yml` and generate `CoffeeBean.xcodeproj` (adding the local `CoffeeBeanCore` package, HealthKit/CloudKit capabilities, Info.plist keys). If you'd rather not use it, I'll give you click-by-click Xcode steps instead.

## 3. Apple account & capabilities

| You want… | Account needed |
|---|---|
| Build & run on **Simulator** and your **own iPhone**, local-only (SwiftData local, HealthKit) | **Free Apple ID** (personal team) — enough to start |
| **CloudKit** multi-device sync (the iCloud private DB in the spec) | **Paid Apple Developer Program** ($99/yr) — required to create an iCloud container |
| TestFlight / App Store | Paid program |

**Practical path:** v1 is **local-first** — you can build and run the entire app on a **free Apple ID** with SwiftData stored locally. Turn on **CloudKit sync later** when you join the paid program (the code is written so sync is an add-on, not a dependency).

- HealthKit: works in the **Simulator** for most types (add sample data via the Simulator's Health app). **Background delivery and real sensor data require a physical iPhone.**

## 4. Your iPhone (for real HealthKit / on-device testing)

- iPhone 16/17 Pro Max: **Settings → Privacy & Security → Developer Mode → On** (reboots).
- Connect via cable, trust the Mac, and it appears as a run destination in Xcode.

## 5. When Xcode is installed, tell me — then we:

1. Verify `CoffeeBeanCore` also builds under the **iOS SDK** (not just host macOS).
2. Scaffold the app: **either** you ran `brew install xcodegen` and I generate `CoffeeBean.xcodeproj` from a `project.yml`, **or** I hand you exact Xcode steps to create the app target + add the `CoffeeBeanCore` package.
3. Add the SwiftData models, HealthKit wrapper, and the first SwiftUI screen — then you hit **⌘R** and see it run in the Simulator.

---

### TL;DR
```bash
# 1. Install Xcode from the Mac App Store, then:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
# 2. Optional, lets me generate the project:
brew install xcodegen
# 3. A free Apple ID is enough to start (CloudKit sync needs the paid program later).
```
Ping me once `xcodebuild -version` prints an Xcode version and I'll wire up the app project.

---

## 6. Running on a physical iPhone (真机)

The project is already configured for **automatic signing** (`CODE_SIGN_STYLE: Automatic`
in `App/project.yml`). What's left is one-time account + device setup.

### 6.0 Xcode version vs your iPhone's iOS — check first
Xcode can only deploy to devices whose iOS it knows. Currently installed: **Xcode 16.3
(iOS 18.4 SDK)**.
- iPhone on **iOS 18.x** → deploy today with Xcode 16.3.
- iPhone on **iOS 26** (the 17 Pro Max ships with it) → you need **Xcode 26** from the
  Mac App Store. If the App Store refuses, update macOS first (Xcode 26 needs a newer
  macOS Sequoia point release), then:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  xcodebuild -runFirstLaunch
  ```
  The project's iOS 18 deployment target is unaffected.

### 6.1 Apple ID (free is fine to start)
Xcode → **Settings → Accounts → +** → sign in with your Apple ID. A **Personal Team**
appears automatically.
- **Free account:** installs expire after **7 days** (rerun from Xcode to refresh),
  ~3 sideloaded apps max, **no iCloud/CloudKit entitlement**. HealthKit *is* allowed.
- **Paid Apple Developer ($99/yr):** 1-year profiles, CloudKit, TestFlight. Needed
  later for sync anyway.

### 6.2 Pick the team (once)
`open App/CoffeeBean.xcodeproj` → select the **CoffeeBean** target → **Signing &
Capabilities** → check **Automatically manage signing** → **Team: (your name) Personal
Team**. Xcode creates the certificate + provisioning profile automatically.
- To survive `xcodegen generate` regenerations, also bake the team in: tell me the
  Team ID (Xcode → Settings → Accounts → your team, or the Membership page) and I'll
  set `DEVELOPMENT_TEAM` in `project.yml`; after that no manual step ever again.
- If the bundle ID collides ("identifier is not available"), change
  `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` (e.g. add a suffix).

### 6.3 Prepare the iPhone (once)
1. **Settings → Privacy & Security → Developer Mode → On** (phone restarts). If the
   toggle is hidden, it appears after the first time Xcode sees the device.
2. Plug in via USB-C, tap **Trust This Computer** on the phone.
3. (Optional) In Xcode's Devices window enable **Connect via network** for cable-free
   deploys afterwards.

### 6.4 Run
Xcode: pick your iPhone in the run-destination dropdown → **⌘R**.
First launch on a free account: the phone blocks the app — go to **Settings → General →
VPN & Device Management → (your Apple ID) → Trust**, then launch again.

CLI alternative once the team is set:
```bash
cd App && xcodegen generate
xcodebuild -project CoffeeBean.xcodeproj -scheme CoffeeBean \
  -destination 'generic/platform=iOS' -configuration Debug build
xcrun devicectl list devices            # find the device id
xcrun devicectl device install app --device <ID> \
  "$(xcodebuild -project CoffeeBean.xcodeproj -scheme CoffeeBean -showBuildSettings 2>/dev/null \
     | awk -F' = ' '/ CODESIGNING_FOLDER_PATH /{print $2}' | head -1)"
```

### 6.5 Notes for real usage
- Demo/seed data (`CB_SEED` etc.) is env-gated and never runs on device — you start
  clean; default water presets + starter foods still seed.
- Data is local SwiftData. Deleting the app deletes the data (CloudKit backup comes
  with the paid account + sync workstream). The 7-day free-account expiry does **not**
  delete data — rerunning from Xcode refreshes the app in place.
