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

---

## 7. Xcode Cloud → TestFlight (when the dev Mac can't run Xcode 26)

**Situation:** the iPhones run iOS 26.x but this Mac is pinned to macOS 15.2, which
caps local Xcode at 16.3 (iOS 18.4 SDK) — too old to deploy to the devices or to pass
App Store Connect's iOS 26 SDK upload requirement (in force since April 2026).

**Solution:** build in **Xcode Cloud** (included with the paid Apple Developer
Program — 25 free compute hours/month). Local Mac keeps doing simulator development
with Xcode 16.3; the cloud builds with Xcode 26 and pushes to TestFlight.

Already prepared in this repo:
- `App/CoffeeBean.xcodeproj` is **committed** (with a shared scheme) — Xcode Cloud
  builds straight from the repo. It's still generated from `App/project.yml`:
  after editing project.yml, run `cd App && xcodegen generate` and commit the result.
- Repo pushed to **private GitHub: `ericybli/Coffee-Bean`**.

One-time setup (GUI, ~15 min):
1. Local Xcode 16.3: open `App/CoffeeBean.xcodeproj` → menu **Integrate → Create
   Workflow…** (or Report navigator → Cloud tab) → sign in with the paid Apple ID.
2. Grant Xcode Cloud access to the GitHub repo when prompted (installs Apple's
   GitHub App on `ericybli/Coffee-Bean`).
3. Workflow settings: **Environment → newest Xcode 26.x**; Start Condition → branch
   (e.g. `master` or `docs/health-app-spec`); Action → **Archive - iOS**;
   Post-action → **TestFlight (Internal Testing)**. Xcode Cloud manages signing
   automatically (cloud-managed certificates) and can create the App Store Connect
   app record for `com.ericybli.coffeebean` during setup.
4. App Store Connect → TestFlight → Internal Testing group → add your (and your
   partner's) Apple IDs. Phones install via the TestFlight app.

After that, every push to the watched branch = automatic cloud build → TestFlight
update on the phones. If Xcode 16.3's workflow editor misbehaves, workflows can also
be edited in the App Store Connect web UI (Xcode Cloud tab).

> **Note:** §6–7 assume the paid account is usable for this app. It turned out the
> paid account belongs to the company and this is a personal app → the **chosen path
> is §8 (AltStore)**. §6–7 are kept for reference (they become relevant again if a
> personal paid account is ever purchased — recommended long-term).

---

## 8. ✅ Chosen path: AltStore sideloading (free, personal Apple ID, no company account)

**Why:** the paid Apple account is the company's; this is a personal health app. AltStore
signs the app with a **free personal Apple ID** and installs it over USB/WiFi — nothing
ever touches App Store Connect or the company account. Works with the pinned macOS 15.2
+ Xcode 16.3 (the IPA is built locally with the iOS 18.4 SDK and runs fine on iOS 26.5).

### 8.1 Build the IPA (already scripted)
```bash
Scripts/build-ipa.sh        # → dist/CoffeeBean.ipa (unsigned; AltStore signs it)
```

### 8.2 One-time setup
1. **Mac:** download **AltServer** from https://altstore.io → move to /Applications →
   open (menu-bar icon appears).
2. **iPhone:** plug in via USB-C → trust the Mac in Finder if prompted.
3. Menu bar → AltServer icon → **Install AltStore → (your iPhone)** → sign in with a
   **personal (free) Apple ID**. (2FA: AltServer walks you through it. If you prefer,
   create a fresh Apple ID just for signing.)
4. **iPhone:** Settings → General → **VPN & Device Management** → trust the developer
   certificate; Settings → Privacy & Security → **Developer Mode → On** (restarts).
5. AirDrop `dist/CoffeeBean.ipa` to the iPhone (save to Files), open **AltStore** on
   the phone → **My Apps → ＋** → pick CoffeeBean.ipa → installs.

### 8.3 The 7-day refresh (free-account signing expiry)
- Keep AltServer running on the Mac. When the iPhone is on the **same WiFi**, AltStore
  auto-refreshes signatures in the background (leave Background App Refresh on for
  AltStore). Manual refresh: open AltStore → My Apps → Refresh.
- If it ever fully expires, the app icon stays but won't launch — one tap of Refresh
  (or reinstall the IPA) fixes it; **SwiftData data survives** refreshes/reinstalls of
  the same bundle ID.

### 8.4 Updating the app
```bash
Scripts/build-ipa.sh   # rebuild after code changes
```
AirDrop the new IPA → AltStore → My Apps → ＋ → install over the old one (data kept).

### 8.5 Limits & caveats (honest list)
- Free accounts: max **3 sideloaded apps** active (AltStore itself counts as one),
  10 App-ID registrations per 7 days, signatures last 7 days.
- The partner's iPhone repeats §8.2 with **their own** free Apple ID (or the same one).
- **iOS 26.5 compatibility:** AltStore tracks new iOS releases closely, but if
  Install AltStore fails on 26.5, try the newest AltServer beta or the SideStore fork.
- **HealthKit (future):** free personal teams do support the HealthKit entitlement,
  but AltStore's re-signing of it needs verifying when we add HealthKit. CloudKit
  sync will NOT be possible on a free account — that feature waits for a personal
  paid account.
- Bundle ID is now personal: `com.ericybli.coffeebean` (changed from the company
  domain). If the company portal ended up with a `com.ericybli.coffeebean` App ID
  from the earlier Xcode Cloud attempt, delete it at
  developer.apple.com → Identifiers.
