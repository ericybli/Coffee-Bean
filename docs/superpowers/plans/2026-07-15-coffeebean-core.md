# CoffeeBeanCore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `CoffeeBeanCore`, a pure-Foundation Swift package holding all the domain logic for the Coffee Bean health app — unit conversion, the energy/TDEE/RMR engine, weight-trend smoothing, and Open Food Facts parsing — fully unit-tested with `swift test`.

**Architecture:** A dependency-free SwiftPM library target (`CoffeeBeanCore`) of value types and stateless services, plus an XCTest target. No SwiftData, HealthKit, SwiftUI, or third-party dependencies — so it compiles and tests on the host macOS toolchain (Xcode CLT) with no iOS SDK. The SwiftUI/SwiftData/HealthKit app (a separate, later plan) maps its `@Model` types to/from these value types and calls these services.

**Tech Stack:** Swift 6, SwiftPM, Foundation (`Measurement`, `Codable`, `URLSession`), XCTest.

## Global Constraints

- **No third-party dependencies.** Foundation only.
- **Package name:** `CoffeeBeanCore`. Swift tools version **6.0**. Platforms: `.macOS(.v13), .iOS(.v17)` (so it builds on the host for testing; the app deploys iOS 26).
- **Canonical SI storage** everywhere: body mass = **kg**, food mass = **g**, liquid volume = **mL**, height = **cm**, energy = **kcal**. Units convert at the display boundary only; energy is kcal in both unit systems.
- **Energy density constant:** `kcalPerKg = 7700.0` is the single canonical constant; derive `kcalPerLb` from it. Do not hardcode 3500.
- **Formulas are fixed (from the spec):**
  - Mifflin-St Jeor: male `10·kg + 6.25·cm − 5·age + 5`; female `… − 161`.
  - Katch-McArdle: `370 + 21.6·leanMassKg`.
  - TEF flat: `0.10 · intakeKcal`; per-macro: `0.25·Pkcal + 0.08·Ckcal + 0.02·Fkcal` (protein/carb 4 kcal/g, fat 9 kcal/g).
  - EWMA: `T[t] = T[t−1] + α·(W[t] − T[t−1])`.
  - Adaptive maintenance: `mean(intake over W) − kcalPerKg · (trend[end] − trend[start]) / W`.
- **US customary uses `UnitVolume.fluidOunces`/`.cups` (US), never imperial.**
- **Every service is stateless** (static or pure instance methods); no singletons, no global mutable state.
- **Commit after every task** with a `feat:`/`test:` message. Work on branch `docs/health-app-spec`.

---

### Task 0: Package scaffold

**Files:**
- Create: `Package.swift`
- Create: `Sources/CoffeeBeanCore/CoffeeBeanCore.swift`
- Create: `Tests/CoffeeBeanCoreTests/SmokeTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: a buildable/testable package with an empty `enum CoffeeBeanCore { static let version = "0.1.0" }`.

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoffeeBeanCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "CoffeeBeanCore", targets: ["CoffeeBeanCore"]),
    ],
    targets: [
        .target(name: "CoffeeBeanCore"),
        .testTarget(name: "CoffeeBeanCoreTests", dependencies: ["CoffeeBeanCore"]),
    ]
)
```

- [ ] **Step 2: Create the namespace file `Sources/CoffeeBeanCore/CoffeeBeanCore.swift`**

```swift
import Foundation

/// Namespace + package version marker.
public enum CoffeeBeanCore {
    public static let version = "0.1.0"
}
```

- [ ] **Step 3: Create the smoke test `Tests/CoffeeBeanCoreTests/SmokeTests.swift`**

```swift
import XCTest
@testable import CoffeeBeanCore

final class SmokeTests: XCTestCase {
    func testVersionIsSet() {
        XCTAssertEqual(CoffeeBeanCore.version, "0.1.0")
    }
}
```

- [ ] **Step 4: Build and test**

Run: `swift test`
Expected: builds; `testVersionIsSet` PASSES.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "feat: scaffold CoffeeBeanCore SwiftPM package"
```

---

### Task 1: Unit conversion (`UnitSystem`, `QuantityKind`, `Quantity.converted`)

**Files:**
- Create: `Sources/CoffeeBeanCore/Units/UnitSystem.swift`
- Create: `Sources/CoffeeBeanCore/Units/Quantity.swift`
- Test: `Tests/CoffeeBeanCoreTests/QuantityConversionTests.swift`

**Interfaces:**
- Produces:
  - `enum UnitSystem: String, Codable, CaseIterable, Sendable { case metric, imperial }`
  - `enum QuantityKind: Sendable { case bodyMass, foodMass, volume, height, energy }`
  - `struct Quantity: Equatable, Sendable { let canonicalValue: Double; let kind: QuantityKind; init(canonicalValue:kind:); func value(in: UnitSystem) -> Double }`
  - Canonical units: bodyMass=kg, foodMass=g, volume=mL, height=cm, energy=kcal.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class QuantityConversionTests: XCTestCase {
    func testBodyMassKgToLb() {
        let q = Quantity(canonicalValue: 72.4, kind: .bodyMass)
        XCTAssertEqual(q.value(in: .metric), 72.4, accuracy: 1e-9)
        XCTAssertEqual(q.value(in: .imperial), 159.615, accuracy: 0.01) // 72.4 / 0.45359237
    }
    func testFoodMassGToOz() {
        let q = Quantity(canonicalValue: 100, kind: .foodMass)
        XCTAssertEqual(q.value(in: .imperial), 3.5274, accuracy: 0.001) // 100 / 28.349523125
    }
    func testVolumeMlToUSFlOz() {
        let q = Quantity(canonicalValue: 500, kind: .volume)
        XCTAssertEqual(q.value(in: .imperial), 16.907, accuracy: 0.01) // 500 / 29.5735295625
    }
    func testHeightCmToInches() {
        let q = Quantity(canonicalValue: 180, kind: .height)
        XCTAssertEqual(q.value(in: .imperial), 70.866, accuracy: 0.01) // 180 / 2.54
    }
    func testEnergyIsSameBothSystems() {
        let q = Quantity(canonicalValue: 2460, kind: .energy)
        XCTAssertEqual(q.value(in: .metric), 2460, accuracy: 1e-9)
        XCTAssertEqual(q.value(in: .imperial), 2460, accuracy: 1e-9)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter QuantityConversionTests`
Expected: FAIL (types `UnitSystem`/`Quantity` not defined).

- [ ] **Step 3: Write minimal implementation**

`Sources/CoffeeBeanCore/Units/UnitSystem.swift`:
```swift
import Foundation

public enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric
    case imperial
}

public enum QuantityKind: Sendable {
    case bodyMass, foodMass, volume, height, energy

    /// The Foundation unit used for canonical (metric) storage.
    var canonicalUnit: Dimension {
        switch self {
        case .bodyMass: return UnitMass.kilograms
        case .foodMass: return UnitMass.grams
        case .volume:   return UnitVolume.milliliters
        case .height:   return UnitLength.centimeters
        case .energy:   return UnitEnergy.kilocalories
        }
    }

    /// The display unit for the given system.
    func displayUnit(for system: UnitSystem) -> Dimension {
        switch (self, system) {
        case (.bodyMass, .imperial): return UnitMass.pounds
        case (.foodMass, .imperial): return UnitMass.ounces
        case (.volume,   .imperial): return UnitVolume.fluidOunces   // US
        case (.height,   .imperial): return UnitLength.inches
        default: return canonicalUnit                                // metric, or energy (kcal both)
        }
    }
}
```

`Sources/CoffeeBeanCore/Units/Quantity.swift`:
```swift
import Foundation

/// A measurement stored once in canonical SI, displayable in either unit system.
public struct Quantity: Equatable, Sendable {
    public let canonicalValue: Double
    public let kind: QuantityKind

    public init(canonicalValue: Double, kind: QuantityKind) {
        self.canonicalValue = canonicalValue
        self.kind = kind
    }

    /// Numeric value expressed in the given system's display unit.
    public func value(in system: UnitSystem) -> Double {
        let measurement = Measurement(value: canonicalValue, unit: kind.canonicalUnit)
        return measurement.converted(to: kind.displayUnit(for: system)).value
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter QuantityConversionTests`
Expected: PASS (all 5).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Units Tests/CoffeeBeanCoreTests/QuantityConversionTests.swift
git commit -m "feat: Quantity canonical<->display unit conversion"
```

---

### Task 2: Formatting, parsing, and composite height (ft+in)

**Files:**
- Modify: `Sources/CoffeeBeanCore/Units/Quantity.swift`
- Create: `Sources/CoffeeBeanCore/Units/HeightComposite.swift`
- Test: `Tests/CoffeeBeanCoreTests/QuantityParsingTests.swift`

**Interfaces:**
- Produces:
  - `Quantity.init?(displayValue: Double, kind: QuantityKind, system: UnitSystem)` — build canonical from a value the user typed in the given system.
  - `struct FeetInches: Equatable, Sendable { let feet: Int; let inches: Int }`
  - `func heightFeetInches() -> FeetInches` on `Quantity` (kind `.height`), with 12-inch carry.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class QuantityParsingTests: XCTestCase {
    func testInitFromImperialBodyMass() {
        let q = Quantity(displayValue: 160, kind: .bodyMass, system: .imperial)!
        XCTAssertEqual(q.canonicalValue, 72.5748, accuracy: 0.001) // 160 * 0.45359237
    }
    func testInitFromMetricVolume() {
        let q = Quantity(displayValue: 500, kind: .volume, system: .metric)!
        XCTAssertEqual(q.canonicalValue, 500, accuracy: 1e-9)
    }
    func testHeightCompositeExact() {
        let q = Quantity(canonicalValue: 180.34, kind: .height) // 71 in = 5 ft 11 in
        XCTAssertEqual(q.heightFeetInches(), FeetInches(feet: 5, inches: 11))
    }
    func testHeightCompositeCarryToNextFoot() {
        // 182.7 cm = 71.93 in -> rounds to 72 in -> must carry to 6 ft 0 in
        let q = Quantity(canonicalValue: 182.7, kind: .height)
        XCTAssertEqual(q.heightFeetInches(), FeetInches(feet: 6, inches: 0))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter QuantityParsingTests`
Expected: FAIL (initializer / `heightFeetInches` not defined).

- [ ] **Step 3: Write minimal implementation**

Append to `Quantity.swift`:
```swift
public extension Quantity {
    /// Build a canonical Quantity from a value the user entered in `system`'s display unit.
    init?(displayValue: Double, kind: QuantityKind, system: UnitSystem) {
        guard displayValue.isFinite else { return nil }
        let measurement = Measurement(value: displayValue, unit: kind.displayUnit(for: system))
        let canonical = measurement.converted(to: kind.canonicalUnit).value
        self.init(canonicalValue: canonical, kind: kind)
    }

    /// Feet + whole inches with a 12-inch carry. Only meaningful for `.height`.
    func heightFeetInches() -> FeetInches {
        let totalInches = value(in: .imperial) // canonical cm -> inches
        var feet = Int(totalInches / 12)
        var inches = Int((totalInches - Double(feet) * 12).rounded())
        if inches == 12 { feet += 1; inches = 0 }
        return FeetInches(feet: feet, inches: inches)
    }
}
```

`Sources/CoffeeBeanCore/Units/HeightComposite.swift`:
```swift
import Foundation

public struct FeetInches: Equatable, Sendable {
    public let feet: Int
    public let inches: Int
    public init(feet: Int, inches: Int) {
        self.feet = feet
        self.inches = inches
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter QuantityParsingTests`
Expected: PASS (all 4).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Units Tests/CoffeeBeanCoreTests/QuantityParsingTests.swift
git commit -m "feat: Quantity display-value init + composite ft/in height"
```

---

### Task 3: Biometrics + BMR formulas

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/Biometrics.swift`
- Create: `Sources/CoffeeBeanCore/Energy/BMR.swift`
- Test: `Tests/CoffeeBeanCoreTests/BMRTests.swift`

**Interfaces:**
- Produces:
  - `enum Sex: String, Codable, Sendable { case male, female }`
  - `struct Biometrics: Equatable, Sendable { let weightKg, heightCm: Double; let ageYears: Int; let sex: Sex; let bodyFatFraction: Double?; let leanMassKg: Double? }`
  - `enum BMR { static func mifflinStJeor(_:) -> Double; static func katchMcArdle(leanMassKg:) -> Double }`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class BMRTests: XCTestCase {
    func testMifflinMale() {
        // 80kg, 180cm, 30y, male: 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
        let b = Biometrics(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male,
                           bodyFatFraction: nil, leanMassKg: nil)
        XCTAssertEqual(BMR.mifflinStJeor(b), 1780, accuracy: 1e-6)
    }
    func testMifflinFemale() {
        // 65kg, 165cm, 30y, female: 650 + 1031.25 - 150 - 161 = 1370.25
        let b = Biometrics(weightKg: 65, heightCm: 165, ageYears: 30, sex: .female,
                           bodyFatFraction: nil, leanMassKg: nil)
        XCTAssertEqual(BMR.mifflinStJeor(b), 1370.25, accuracy: 1e-6)
    }
    func testKatchMcArdle() {
        // lean 60kg: 370 + 21.6*60 = 370 + 1296 = 1666
        XCTAssertEqual(BMR.katchMcArdle(leanMassKg: 60), 1666, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter BMRTests`
Expected: FAIL (types not defined).

- [ ] **Step 3: Write minimal implementation**

`Biometrics.swift`:
```swift
import Foundation

public enum Sex: String, Codable, Sendable { case male, female }

public struct Biometrics: Equatable, Sendable {
    public let weightKg: Double
    public let heightCm: Double
    public let ageYears: Int
    public let sex: Sex
    public let bodyFatFraction: Double?   // 0...1, from DEXA
    public let leanMassKg: Double?        // from DEXA (drives Katch-McArdle)

    public init(weightKg: Double, heightCm: Double, ageYears: Int, sex: Sex,
                bodyFatFraction: Double?, leanMassKg: Double?) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.sex = sex
        self.bodyFatFraction = bodyFatFraction
        self.leanMassKg = leanMassKg
    }
}
```

`BMR.swift`:
```swift
import Foundation

public enum BMR {
    /// Mifflin-St Jeor resting metabolic rate (kcal/day).
    public static func mifflinStJeor(_ b: Biometrics) -> Double {
        let base = 10 * b.weightKg + 6.25 * b.heightCm - 5 * Double(b.ageYears)
        return base + (b.sex == .male ? 5 : -161)
    }

    /// Katch-McArdle resting metabolic rate (kcal/day) from lean body mass.
    public static func katchMcArdle(leanMassKg: Double) -> Double {
        370 + 21.6 * leanMassKg
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BMRTests`
Expected: PASS (all 3).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy Tests/CoffeeBeanCoreTests/BMRTests.swift
git commit -m "feat: Biometrics + Mifflin-St Jeor and Katch-McArdle BMR"
```

---

### Task 4: RMR resolver (source priority)

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/RMRResolver.swift`
- Test: `Tests/CoffeeBeanCoreTests/RMRResolverTests.swift`

**Interfaces:**
- Consumes: `Biometrics`, `BMR`.
- Produces:
  - `enum RMRSource: String, Codable, Sendable { case dexaMeasured, katchMcArdle, mifflinStJeor }`
  - `struct RMRResult: Equatable, Sendable { let value: Double; let source: RMRSource }`
  - `enum RMRResolver { static func resolve(biometrics: Biometrics, measuredRMR: Double?) -> RMRResult }`
  - Priority: `measuredRMR` (DEXA) → `biometrics.leanMassKg` (Katch) → Mifflin.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class RMRResolverTests: XCTestCase {
    private func base(lean: Double?) -> Biometrics {
        Biometrics(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male,
                   bodyFatFraction: lean.map { _ in 0.15 }, leanMassKg: lean)
    }
    func testPrefersMeasuredDexaRMR() {
        let r = RMRResolver.resolve(biometrics: base(lean: 68), measuredRMR: 1720)
        XCTAssertEqual(r, RMRResult(value: 1720, source: .dexaMeasured))
    }
    func testFallsBackToKatchWhenLeanMassPresent() {
        let r = RMRResolver.resolve(biometrics: base(lean: 68), measuredRMR: nil)
        XCTAssertEqual(r.source, .katchMcArdle)
        XCTAssertEqual(r.value, 370 + 21.6 * 68, accuracy: 1e-6)
    }
    func testFallsBackToMifflinWhenNoDexa() {
        let r = RMRResolver.resolve(biometrics: base(lean: nil), measuredRMR: nil)
        XCTAssertEqual(r.source, .mifflinStJeor)
        XCTAssertEqual(r.value, 1780, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RMRResolverTests`
Expected: FAIL (types not defined).

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public enum RMRSource: String, Codable, Sendable {
    case dexaMeasured, katchMcArdle, mifflinStJeor
}

public struct RMRResult: Equatable, Sendable {
    public let value: Double
    public let source: RMRSource
    public init(value: Double, source: RMRSource) {
        self.value = value
        self.source = source
    }
}

public enum RMRResolver {
    /// Resolve RMR by source priority: measured DEXA > Katch-McArdle (DEXA lean mass) > Mifflin-St Jeor.
    public static func resolve(biometrics: Biometrics, measuredRMR: Double?) -> RMRResult {
        if let measured = measuredRMR {
            return RMRResult(value: measured, source: .dexaMeasured)
        }
        if let lean = biometrics.leanMassKg {
            return RMRResult(value: BMR.katchMcArdle(leanMassKg: lean), source: .katchMcArdle)
        }
        return RMRResult(value: BMR.mifflinStJeor(biometrics), source: .mifflinStJeor)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RMRResolverTests`
Expected: PASS (all 3).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy/RMRResolver.swift Tests/CoffeeBeanCoreTests/RMRResolverTests.swift
git commit -m "feat: RMR resolver with DEXA>Katch>Mifflin priority"
```

---

### Task 5: Macros + TEF

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/Macros.swift`
- Create: `Sources/CoffeeBeanCore/Energy/TEF.swift`
- Test: `Tests/CoffeeBeanCoreTests/TEFTests.swift`

**Interfaces:**
- Produces:
  - `struct Macros: Equatable, Sendable { let proteinG, carbG, fatG: Double; var kcal: Double }`
  - `enum TEFMode: String, Codable, Sendable { case none, flatTen, perMacro }`
  - `enum TEF { static func value(mode: TEFMode, intakeKcal: Double, macros: Macros?) -> Double }`
  - Constants `kcalPerGramProtein = 4`, `…Carb = 4`, `…Fat = 9`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class TEFTests: XCTestCase {
    func testMacrosKcal() {
        let m = Macros(proteinG: 200, carbG: 250, fatG: 70)
        XCTAssertEqual(m.kcal, 200*4 + 250*4 + 70*9, accuracy: 1e-6) // 800+1000+630 = 2430
    }
    func testFlatTenPercent() {
        XCTAssertEqual(TEF.value(mode: .flatTen, intakeKcal: 2500, macros: nil), 250, accuracy: 1e-6)
    }
    func testNoneIsZero() {
        XCTAssertEqual(TEF.value(mode: .none, intakeKcal: 2500, macros: nil), 0, accuracy: 1e-6)
    }
    func testPerMacro() {
        // P200g=800kcal*.25=200; C250g=1000*.08=80; F70g=630*.02=12.6 -> 292.6
        let m = Macros(proteinG: 200, carbG: 250, fatG: 70)
        XCTAssertEqual(TEF.value(mode: .perMacro, intakeKcal: m.kcal, macros: m), 292.6, accuracy: 1e-6)
    }
    func testPerMacroWithoutMacrosFallsBackToFlatTen() {
        XCTAssertEqual(TEF.value(mode: .perMacro, intakeKcal: 2500, macros: nil), 250, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TEFTests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

`Macros.swift`:
```swift
import Foundation

public let kcalPerGramProtein = 4.0
public let kcalPerGramCarb = 4.0
public let kcalPerGramFat = 9.0

public struct Macros: Equatable, Sendable {
    public let proteinG: Double
    public let carbG: Double
    public let fatG: Double
    public init(proteinG: Double, carbG: Double, fatG: Double) {
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
    }
    public var kcal: Double {
        proteinG * kcalPerGramProtein + carbG * kcalPerGramCarb + fatG * kcalPerGramFat
    }
}
```

`TEF.swift`:
```swift
import Foundation

public enum TEFMode: String, Codable, Sendable { case none, flatTen, perMacro }

public enum TEF {
    /// Thermic effect of food (kcal). perMacro requires macros; without them it falls back to flat 10%.
    public static func value(mode: TEFMode, intakeKcal: Double, macros: Macros?) -> Double {
        switch mode {
        case .none:
            return 0
        case .flatTen:
            return 0.10 * intakeKcal
        case .perMacro:
            guard let m = macros else { return 0.10 * intakeKcal }
            return 0.25 * (m.proteinG * kcalPerGramProtein)
                 + 0.08 * (m.carbG * kcalPerGramCarb)
                 + 0.02 * (m.fatG * kcalPerGramFat)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TEFTests`
Expected: PASS (all 5).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy/Macros.swift Sources/CoffeeBeanCore/Energy/TEF.swift Tests/CoffeeBeanCoreTests/TEFTests.swift
git commit -m "feat: Macros kcal + TEF (none/flat/per-macro)"
```

---

### Task 6: Static TDEE + energy balance

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/EnergyBalance.swift`
- Test: `Tests/CoffeeBeanCoreTests/EnergyBalanceTests.swift`

**Interfaces:**
- Consumes: `TEFMode`, `TEF`, `Macros`, `RMRResult`.
- Produces:
  - `struct ExpenditureInputs: Sendable { let rmr: Double; let activeEnergyKcal: Double; let tefMode: TEFMode }`
  - `enum EnergyBalance { static func staticTDEE(rmr:activeEnergyKcal:intakeKcal:macros:tefMode:) -> Double; static func balance(intakeKcal:tdee:) -> Double }`
  - `balance > 0` = surplus.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class EnergyBalanceTests: XCTestCase {
    func testStaticTDEEFlatTEF() {
        // rmr 1780 + active 500 + TEF(flat 10% of 2500 intake)=250 => 2530
        let tdee = EnergyBalance.staticTDEE(rmr: 1780, activeEnergyKcal: 500,
                                            intakeKcal: 2500, macros: nil, tefMode: .flatTen)
        XCTAssertEqual(tdee, 2530, accuracy: 1e-6)
    }
    func testBalanceSurplusIsPositive() {
        let b = EnergyBalance.balance(intakeKcal: 2800, tdee: 2530)
        XCTAssertEqual(b, 270, accuracy: 1e-6) // surplus
    }
    func testBalanceDeficitIsNegative() {
        let b = EnergyBalance.balance(intakeKcal: 2200, tdee: 2530)
        XCTAssertEqual(b, -330, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter EnergyBalanceTests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public struct ExpenditureInputs: Sendable {
    public let rmr: Double
    public let activeEnergyKcal: Double
    public let tefMode: TEFMode
    public init(rmr: Double, activeEnergyKcal: Double, tefMode: TEFMode) {
        self.rmr = rmr
        self.activeEnergyKcal = activeEnergyKcal
        self.tefMode = tefMode
    }
}

public enum EnergyBalance {
    /// TDEE = RMR + active energy + TEF (TEF is a function of intake, not of expenditure).
    public static func staticTDEE(rmr: Double, activeEnergyKcal: Double,
                                  intakeKcal: Double, macros: Macros?, tefMode: TEFMode) -> Double {
        rmr + activeEnergyKcal + TEF.value(mode: tefMode, intakeKcal: intakeKcal, macros: macros)
    }

    /// Positive = surplus (bulk), negative = deficit.
    public static func balance(intakeKcal: Double, tdee: Double) -> Double {
        intakeKcal - tdee
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter EnergyBalanceTests`
Expected: PASS (all 3).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy/EnergyBalance.swift Tests/CoffeeBeanCoreTests/EnergyBalanceTests.swift
git commit -m "feat: static TDEE composition + surplus/deficit balance"
```

---

### Task 7: Calorie target + macro split + rate-of-gain

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/CalorieTarget.swift`
- Create: `Sources/CoffeeBeanCore/Energy/MacroSplit.swift`
- Create: `Sources/CoffeeBeanCore/Energy/RateOfGain.swift`
- Test: `Tests/CoffeeBeanCoreTests/TargetTests.swift`

**Interfaces:**
- Consumes: `Macros`.
- Produces:
  - `enum CalorieTarget: Equatable, Sendable { case fixed(Double); case tdeeOffset(Double); func resolve(tdee: Double) -> Double }`
  - `struct MacroSplit: Equatable, Sendable { let carbPct, fatPct, proteinPct: Double; static let `default`, highProtein, keto: MacroSplit; static func custom(carbPct:fatPct:) -> MacroSplit; func grams(forCalories:) -> Macros }` (percents are of total calories, 0...100)
  - `enum RateBand: Sendable { case onTrack, slightlyFast, tooFast }`
  - `enum RateOfGain { static func classify(weeklyRatePercentBW: Double) -> RateBand }`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class TargetTests: XCTestCase {
    func testCalorieTargetFixed() {
        XCTAssertEqual(CalorieTarget.fixed(2610).resolve(tdee: 2460), 2610, accuracy: 1e-6)
    }
    func testCalorieTargetTDEEOffset() {
        XCTAssertEqual(CalorieTarget.tdeeOffset(150).resolve(tdee: 2460), 2610, accuracy: 1e-6)
    }
    func testDefaultSplitGrams() {
        // Default 50/30/20 C/F/P of 2000 kcal: C=1000/4=250, F=600/9=66.67, P=400/4=100
        let m = MacroSplit.default.grams(forCalories: 2000)
        XCTAssertEqual(m.carbG, 250, accuracy: 1e-6)
        XCTAssertEqual(m.fatG, 66.6667, accuracy: 0.001)
        XCTAssertEqual(m.proteinG, 100, accuracy: 1e-6)
    }
    func testCustomProteinAutoFills() {
        // custom carbs 40, fat 20 => protein auto = 40
        let s = MacroSplit.custom(carbPct: 40, fatPct: 20)
        XCTAssertEqual(s.proteinPct, 40, accuracy: 1e-6)
    }
    func testRateOfGainBands() {
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 0.35), .onTrack)
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 0.65), .slightlyFast)
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 1.2), .tooFast)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TargetTests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

`CalorieTarget.swift`:
```swift
import Foundation

public enum CalorieTarget: Equatable, Sendable {
    case fixed(Double)
    case tdeeOffset(Double)   // + surplus / - deficit relative to TDEE

    public func resolve(tdee: Double) -> Double {
        switch self {
        case .fixed(let v): return v
        case .tdeeOffset(let d): return tdee + d
        }
    }
}
```

`MacroSplit.swift`:
```swift
import Foundation

/// Percent-of-calories split. carbPct + fatPct + proteinPct == 100.
public struct MacroSplit: Equatable, Sendable {
    public let carbPct: Double
    public let fatPct: Double
    public let proteinPct: Double

    public init(carbPct: Double, fatPct: Double, proteinPct: Double) {
        self.carbPct = carbPct
        self.fatPct = fatPct
        self.proteinPct = proteinPct
    }

    public static let `default` = MacroSplit(carbPct: 50, fatPct: 30, proteinPct: 20)
    public static let highProtein = MacroSplit(carbPct: 40, fatPct: 20, proteinPct: 40)
    public static let keto = MacroSplit(carbPct: 10, fatPct: 65, proteinPct: 25)

    /// Custom split: user sets carbs and fat; protein auto-fills the remainder.
    public static func custom(carbPct: Double, fatPct: Double) -> MacroSplit {
        MacroSplit(carbPct: carbPct, fatPct: fatPct, proteinPct: max(0, 100 - carbPct - fatPct))
    }

    /// Grams for each macro given a calorie target (carb/protein 4 kcal/g, fat 9 kcal/g).
    public func grams(forCalories calories: Double) -> Macros {
        Macros(
            proteinG: (proteinPct / 100 * calories) / kcalPerGramProtein,
            carbG:    (carbPct / 100 * calories) / kcalPerGramCarb,
            fatG:     (fatPct / 100 * calories) / kcalPerGramFat
        )
    }
}
```

`RateOfGain.swift`:
```swift
import Foundation

public enum RateBand: Sendable { case onTrack, slightlyFast, tooFast }

public enum RateOfGain {
    /// Lean-bulk guardrail on weekly bodyweight change (%BW/week).
    /// on-track 0.25–0.5, slightly fast 0.5–0.75, too fast > 0.75.
    public static func classify(weeklyRatePercentBW rate: Double) -> RateBand {
        if rate > 0.75 { return .tooFast }
        if rate > 0.5 { return .slightlyFast }
        return .onTrack
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TargetTests`
Expected: PASS (all 5).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy/CalorieTarget.swift Sources/CoffeeBeanCore/Energy/MacroSplit.swift Sources/CoffeeBeanCore/Energy/RateOfGain.swift Tests/CoffeeBeanCoreTests/TargetTests.swift
git commit -m "feat: calorie target modes, macro-split presets, rate-of-gain bands"
```

---

### Task 8: Weight-trend EWMA (daily grid + gap interpolation)

**Files:**
- Create: `Sources/CoffeeBeanCore/Trend/WeighIn.swift`
- Create: `Sources/CoffeeBeanCore/Trend/TrendEngine.swift`
- Test: `Tests/CoffeeBeanCoreTests/TrendEWMATests.swift`

**Interfaces:**
- Produces:
  - `struct WeighIn: Equatable, Sendable { let date: Date; let massKg: Double }`
  - `struct TrendPoint: Equatable, Sendable { let date: Date; let rawAverage: Double?; let trend: Double }`
  - `struct TrendEngine { let alpha: Double; var calendar: Calendar; init(alpha: Double = 0.1, calendar: Calendar = …UTC…); func trend(from: [WeighIn]) -> [TrendPoint] }`
  - Default `alpha` = 0.1 (research); the app passes its own (design uses ~0.28).

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class TrendEWMATests: XCTestCase {
    // Fixed UTC calendar + day helper for deterministic dates.
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ n: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 1, day: n))!
    }

    func testEWMAKnownSequence() {
        // alpha 0.5, weights 100 then 102: T0=100, T1=100+0.5*(102-100)=101
        let engine = TrendEngine(alpha: 0.5, calendar: cal)
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(2), massKg: 102),
        ])
        XCTAssertEqual(points.map(\.trend), [100, 101])
    }

    func testCollapsesMultiplePerDay() {
        // two weigh-ins same day -> averaged before smoothing
        let engine = TrendEngine(alpha: 1.0, calendar: cal) // alpha 1 -> trend == raw avg
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(1), massKg: 102),
        ])
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].rawAverage, 101)
        XCTAssertEqual(points[0].trend, 101)
    }

    func testGapInterpolation() {
        // day1=100, day3=104, day2 missing -> interpolated raw 102. alpha 1 -> trend follows interpolation.
        let engine = TrendEngine(alpha: 1.0, calendar: cal)
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(3), massKg: 104),
        ])
        XCTAssertEqual(points.count, 3)
        XCTAssertNil(points[1].rawAverage)          // day 2 had no weigh-in
        XCTAssertEqual(points[1].trend, 102)        // interpolated into the smoother
        XCTAssertEqual(points[2].trend, 104)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TrendEWMATests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

`WeighIn.swift`:
```swift
import Foundation

public struct WeighIn: Equatable, Sendable {
    public let date: Date
    public let massKg: Double
    public init(date: Date, massKg: Double) {
        self.date = date
        self.massKg = massKg
    }
}

public struct TrendPoint: Equatable, Sendable {
    public let date: Date
    public let rawAverage: Double?   // nil if no weigh-in that day
    public let trend: Double
    public init(date: Date, rawAverage: Double?, trend: Double) {
        self.date = date
        self.rawAverage = rawAverage
        self.trend = trend
    }
}
```

`TrendEngine.swift`:
```swift
import Foundation

public struct TrendEngine {
    public let alpha: Double
    public var calendar: Calendar

    public init(alpha: Double = 0.1, calendar: Calendar = TrendEngine.utcCalendar) {
        self.alpha = alpha
        self.calendar = calendar
    }

    public static var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// Smoothed trend over a per-calendar-day grid, gaps linearly interpolated.
    public func trend(from weighIns: [WeighIn]) -> [TrendPoint] {
        guard !weighIns.isEmpty else { return [] }

        // 1. Collapse to one average per calendar day.
        var byDay: [Date: [Double]] = [:]
        for w in weighIns {
            let d = calendar.startOfDay(for: w.date)
            byDay[d, default: []].append(w.massKg)
        }
        let sortedDays = byDay.keys.sorted()
        let firstDay = sortedDays.first!
        let lastDay = sortedDays.last!

        // 2. Build the continuous daily grid (raw average or nil).
        var grid: [(date: Date, raw: Double?)] = []
        var cursor = firstDay
        while cursor <= lastDay {
            if let vals = byDay[cursor] {
                grid.append((cursor, vals.reduce(0, +) / Double(vals.count)))
            } else {
                grid.append((cursor, nil))
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }

        // 3. Linear-interpolate missing days between known values.
        let interpolated = linearInterpolate(grid.map(\.raw))

        // 4. EWMA recursion.
        var trends: [Double] = []
        var t = interpolated[0]
        for (i, value) in interpolated.enumerated() {
            if i == 0 { t = value } else { t += alpha * (value - t) }
            trends.append(t)
        }

        // 5. Assemble points (rawAverage stays nil on interpolated-only days).
        return grid.enumerated().map { i, g in
            TrendPoint(date: g.date, rawAverage: g.raw, trend: trends[i])
        }
    }

    /// Fill nils by linear interpolation between surrounding known values; edges hold nearest known.
    private func linearInterpolate(_ series: [Double?]) -> [Double] {
        let n = series.count
        var out = [Double](repeating: 0, count: n)
        var lastKnownIndex: Int? = nil
        for i in 0..<n {
            if let v = series[i] {
                out[i] = v
                if let last = lastKnownIndex, last < i - 1 {
                    let startV = out[last], endV = v
                    let span = i - last
                    for j in (last + 1)..<i {
                        let frac = Double(j - last) / Double(span)
                        out[j] = startV + (endV - startV) * frac
                    }
                }
                lastKnownIndex = i
            }
        }
        // Leading nils -> first known value.
        if let first = series.firstIndex(where: { $0 != nil }) {
            for i in 0..<first { out[i] = series[first]! }
        }
        return out
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TrendEWMATests`
Expected: PASS (all 3).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Trend Tests/CoffeeBeanCoreTests/TrendEWMATests.swift
git commit -m "feat: weight-trend EWMA with daily grid + gap interpolation"
```

---

### Task 9: Weekly rate + goal projection + warm-up

**Files:**
- Modify: `Sources/CoffeeBeanCore/Trend/TrendEngine.swift`
- Test: `Tests/CoffeeBeanCoreTests/TrendRateTests.swift`

**Interfaces:**
- Consumes: `TrendPoint`.
- Produces (on `TrendEngine`):
  - `func weeklyRateKg(trend: [TrendPoint], overLastDays: Int = 14) -> Double` — least-squares slope × 7.
  - `func projectionDays(currentTrendKg: Double, goalKg: Double, weeklyRateKg: Double) -> Double?` — nil if rate is zero/wrong sign.
  - `func isWarmUp(trend: [TrendPoint], minDays: Int = 13) -> Bool`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class TrendRateTests: XCTestCase {
    private let engine = TrendEngine(alpha: 0.1, calendar: TrendEngine.utcCalendar)
    private func mkTrend(_ values: [Double]) -> [TrendPoint] {
        let cal = TrendEngine.utcCalendar
        return values.enumerated().map { i, v in
            TrendPoint(date: cal.date(from: DateComponents(year: 2026, month: 2, day: i + 1))!,
                       rawAverage: v, trend: v)
        }
    }
    func testWeeklyRateOnLinearTrend() {
        // +0.1 kg/day over 15 days -> 0.7 kg/week
        let t = mkTrend((0..<15).map { 70 + 0.1 * Double($0) })
        XCTAssertEqual(engine.weeklyRateKg(trend: t, overLastDays: 14), 0.7, accuracy: 1e-6)
    }
    func testProjectionDays() {
        // from 72 to 75 at 0.3 kg/wk -> 3 / (0.3/7) = 70 days
        let days = engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: 0.3)!
        XCTAssertEqual(days, 70, accuracy: 1e-6)
    }
    func testProjectionNilWhenRateZero() {
        XCTAssertNil(engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: 0))
    }
    func testProjectionNilWhenWrongDirection() {
        // goal above current but losing weight -> unreachable
        XCTAssertNil(engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: -0.2))
    }
    func testWarmUp() {
        XCTAssertTrue(engine.isWarmUp(trend: mkTrend(Array(repeating: 70, count: 10))))
        XCTAssertFalse(engine.isWarmUp(trend: mkTrend(Array(repeating: 70, count: 20))))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TrendRateTests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

Append to `TrendEngine.swift`:
```swift
public extension TrendEngine {
    /// Weekly rate of change (kg/week) = least-squares slope of the trend over the last `overLastDays` days × 7.
    func weeklyRateKg(trend: [TrendPoint], overLastDays: Int = 14) -> Double {
        let window = Array(trend.suffix(overLastDays))
        guard window.count >= 2 else { return 0 }
        let xs = window.indices.map(Double.init)              // day index 0..n-1
        let ys = window.map(\.trend)
        let n = Double(window.count)
        let sumX = xs.reduce(0, +), sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return 0 }
        let slopePerDay = (n * sumXY - sumX * sumY) / denom
        return slopePerDay * 7
    }

    /// Days to reach `goalKg` at the current weekly rate. nil if rate is zero or points the wrong way.
    func projectionDays(currentTrendKg: Double, goalKg: Double, weeklyRateKg: Double) -> Double? {
        guard weeklyRateKg != 0 else { return nil }
        let remaining = goalKg - currentTrendKg
        let perDay = weeklyRateKg / 7
        let days = remaining / perDay
        return days > 0 ? days : nil
    }

    /// True while the trend is still converging (fewer than `minDays` days of data ≈ 2 half-lives at α=0.1).
    func isWarmUp(trend: [TrendPoint], minDays: Int = 13) -> Bool {
        trend.count < minDays
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TrendRateTests`
Expected: PASS (all 5).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Trend/TrendEngine.swift Tests/CoffeeBeanCoreTests/TrendRateTests.swift
git commit -m "feat: weekly rate (LSQ slope), goal projection, warm-up flag"
```

---

### Task 10: Adaptive TDEE + DEXA reconciliation

**Files:**
- Create: `Sources/CoffeeBeanCore/Energy/AdaptiveTDEE.swift`
- Test: `Tests/CoffeeBeanCoreTests/AdaptiveTDEETests.swift`

**Interfaces:**
- Produces:
  - `let kcalPerKg = 7700.0`, `let kcalPerLb = kcalPerKg * 0.45359237`
  - `struct AdaptiveResult: Equatable, Sendable { let maintenanceKcal: Double; let isTrustworthy: Bool }`
  - `enum AdaptiveTDEE { static func maintenance(meanIntakeKcal:trendStartKg:trendEndKg:windowDays:) -> Double; static func evaluate(meanIntakeKcal:trendStartKg:trendEndKg:windowDays:daysLogged:weighIns:) -> AdaptiveResult; static func impliedActivityMultiplier(adaptiveTDEE:rmr:) -> Double; static func impliedActiveEnergy(adaptiveTDEE:rmr:tefKcal:) -> Double }`
  - Trustworthy when `daysLogged >= 14 && weighIns >= 8`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class AdaptiveTDEETests: XCTestCase {
    func testMaintenanceGainMeansSurplus() {
        // gained 0.5 kg over 14 days on mean intake 2800:
        // maintenance = 2800 - 7700*0.5/14 = 2800 - 275 = 2525 (< intake => was in surplus)
        let m = AdaptiveTDEE.maintenance(meanIntakeKcal: 2800, trendStartKg: 72.0,
                                         trendEndKg: 72.5, windowDays: 14)
        XCTAssertEqual(m, 2525, accuracy: 1e-6)
    }
    func testMaintenanceLossMeansDeficit() {
        // lost 0.5 kg over 14 days on mean intake 2200:
        // maintenance = 2200 - 7700*(-0.5)/14 = 2200 + 275 = 2475 (> intake => was in deficit)
        let m = AdaptiveTDEE.maintenance(meanIntakeKcal: 2200, trendStartKg: 72.5,
                                         trendEndKg: 72.0, windowDays: 14)
        XCTAssertEqual(m, 2475, accuracy: 1e-6)
    }
    func testTrustworthyGating() {
        let ok = AdaptiveTDEE.evaluate(meanIntakeKcal: 2800, trendStartKg: 72, trendEndKg: 72.5,
                                       windowDays: 14, daysLogged: 20, weighIns: 12)
        XCTAssertTrue(ok.isTrustworthy)
        let notYet = AdaptiveTDEE.evaluate(meanIntakeKcal: 2800, trendStartKg: 72, trendEndKg: 72.5,
                                           windowDays: 14, daysLogged: 5, weighIns: 3)
        XCTAssertFalse(notYet.isTrustworthy)
    }
    func testDexaReconciliation() {
        // adaptive 2530, DEXA RMR 1720 -> multiplier 1.4709; active = 2530-1720-250 = 560
        XCTAssertEqual(AdaptiveTDEE.impliedActivityMultiplier(adaptiveTDEE: 2530, rmr: 1720),
                       1.47093, accuracy: 0.001)
        XCTAssertEqual(AdaptiveTDEE.impliedActiveEnergy(adaptiveTDEE: 2530, rmr: 1720, tefKcal: 250),
                       560, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AdaptiveTDEETests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public let kcalPerKg = 7700.0
public let kcalPerLb = kcalPerKg * 0.45359237   // derive; never hardcode 3500

public struct AdaptiveResult: Equatable, Sendable {
    public let maintenanceKcal: Double
    public let isTrustworthy: Bool
    public init(maintenanceKcal: Double, isTrustworthy: Bool) {
        self.maintenanceKcal = maintenanceKcal
        self.isTrustworthy = isTrustworthy
    }
}

public enum AdaptiveTDEE {
    /// Empirical maintenance from the energy-balance identity over a window.
    /// Gaining trend weight lowers maintenance below intake (you were in surplus).
    public static func maintenance(meanIntakeKcal: Double, trendStartKg: Double,
                                   trendEndKg: Double, windowDays: Int) -> Double {
        let deltaKg = trendEndKg - trendStartKg
        return meanIntakeKcal - kcalPerKg * deltaKg / Double(windowDays)
    }

    public static func evaluate(meanIntakeKcal: Double, trendStartKg: Double, trendEndKg: Double,
                                windowDays: Int, daysLogged: Int, weighIns: Int) -> AdaptiveResult {
        let m = maintenance(meanIntakeKcal: meanIntakeKcal, trendStartKg: trendStartKg,
                            trendEndKg: trendEndKg, windowDays: windowDays)
        return AdaptiveResult(maintenanceKcal: m, isTrustworthy: daysLogged >= 14 && weighIns >= 8)
    }

    /// DEXA reconciliation: treat RMR as the fixed resting anchor.
    public static func impliedActivityMultiplier(adaptiveTDEE: Double, rmr: Double) -> Double {
        guard rmr != 0 else { return 0 }
        return adaptiveTDEE / rmr
    }

    public static func impliedActiveEnergy(adaptiveTDEE: Double, rmr: Double, tefKcal: Double) -> Double {
        adaptiveTDEE - rmr - tefKcal
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AdaptiveTDEETests`
Expected: PASS (all 4).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Energy/AdaptiveTDEE.swift Tests/CoffeeBeanCoreTests/AdaptiveTDEETests.swift
git commit -m "feat: adaptive TDEE back-calc, gating, DEXA reconciliation"
```

---

### Task 11: Open Food Facts response decoding (lenient)

**Files:**
- Create: `Sources/CoffeeBeanCore/Food/OFFResponse.swift`
- Create: `Tests/CoffeeBeanCoreTests/Fixtures/off_nutella.json`
- Create: `Tests/CoffeeBeanCoreTests/Fixtures/off_kj_only.json`
- Test: `Tests/CoffeeBeanCoreTests/OFFDecodingTests.swift`
- Modify: `Package.swift` (add `resources: [.copy("Fixtures")]` to the test target)

**Interfaces:**
- Produces:
  - `struct OFFResponse: Decodable, Sendable { let status: Int?; let statusVerbose: String?; let code: String?; let product: OFFProduct? }`
  - `struct OFFProduct: Decodable, Sendable { let productName: String?; let brands: String?; let servingSize: String?; let servingQuantity: Double?; let nutritionDataPer: String?; let imageFrontSmallURL: String?; let nutriments: [String: Double] }` — nutriments decoded leniently (Double, Int, or numeric String).

- [ ] **Step 1: Add fixtures and register resources**

`Tests/CoffeeBeanCoreTests/Fixtures/off_nutella.json`:
```json
{ "status": 1, "status_verbose": "product found", "code": "3017624010701",
  "product": { "product_name": "Nutella", "brands": "Ferrero",
    "serving_size": "15 g", "serving_quantity": 15, "nutrition_data_per": "100g",
    "image_front_small_url": "https://example.org/nutella.jpg",
    "nutriments": { "energy-kcal_100g": 539, "proteins_100g": 6.3,
      "carbohydrates_100g": 57.5, "fat_100g": 30.9, "energy_100g": 2255 } } }
```

`Tests/CoffeeBeanCoreTests/Fixtures/off_kj_only.json`:
```json
{ "status": 1, "code": "1111111111111",
  "product": { "product_name": "KJ Only Bar", "nutrition_data_per": "100g",
    "nutriments": { "energy-kj_100g": "1000", "proteins_100g": "5",
      "carbohydrates_100g": 20, "fat_100g": 10 } } }
```

Modify the test target in `Package.swift`:
```swift
.testTarget(name: "CoffeeBeanCoreTests", dependencies: ["CoffeeBeanCore"],
            resources: [.copy("Fixtures")]),
```

- [ ] **Step 2: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class OFFDecodingTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }
    func testDecodeNutella() throws {
        let r = try JSONDecoder().decode(OFFResponse.self, from: fixture("off_nutella"))
        XCTAssertEqual(r.status, 1)
        XCTAssertEqual(r.product?.productName, "Nutella")
        XCTAssertEqual(r.product?.nutriments["energy-kcal_100g"], 539)
        XCTAssertEqual(r.product?.nutriments["proteins_100g"], 6.3)
        XCTAssertEqual(r.product?.servingQuantity, 15)
    }
    func testDecodesNumericStrings() throws {
        // energy-kj as a String "1000", proteins as "5" -> must decode to Doubles
        let r = try JSONDecoder().decode(OFFResponse.self, from: fixture("off_kj_only"))
        XCTAssertEqual(r.product?.nutriments["energy-kj_100g"], 1000)
        XCTAssertEqual(r.product?.nutriments["proteins_100g"], 5)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --filter OFFDecodingTests`
Expected: FAIL (`OFFResponse` not defined).

- [ ] **Step 4: Write minimal implementation**

`Sources/CoffeeBeanCore/Food/OFFResponse.swift`:
```swift
import Foundation

/// A JSON number that may arrive as Double, Int, or a numeric String (Open Food Facts is inconsistent).
struct LenientDouble: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { value = d }
        else if let i = try? c.decode(Int.self) { value = Double(i) }
        else if let s = try? c.decode(String.self) { value = Double(s) }
        else { value = nil }
    }
}

public struct OFFResponse: Decodable, Sendable {
    public let status: Int?
    public let statusVerbose: String?
    public let code: String?
    public let product: OFFProduct?

    enum CodingKeys: String, CodingKey {
        case status, code
        case statusVerbose = "status_verbose"
        case product
    }
}

public struct OFFProduct: Decodable, Sendable {
    public let productName: String?
    public let brands: String?
    public let servingSize: String?
    public let servingQuantity: Double?
    public let nutritionDataPer: String?
    public let imageFrontSmallURL: String?
    public let nutriments: [String: Double]

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutritionDataPer = "nutrition_data_per"
        case imageFrontSmallURL = "image_front_small_url"
        case nutriments
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productName = try c.decodeIfPresent(String.self, forKey: .productName)
        brands = try c.decodeIfPresent(String.self, forKey: .brands)
        servingSize = try c.decodeIfPresent(String.self, forKey: .servingSize)
        servingQuantity = (try c.decodeIfPresent(LenientDouble.self, forKey: .servingQuantity))?.value
        nutritionDataPer = try c.decodeIfPresent(String.self, forKey: .nutritionDataPer)
        imageFrontSmallURL = try c.decodeIfPresent(String.self, forKey: .imageFrontSmallURL)
        let raw = try c.decodeIfPresent([String: LenientDouble].self, forKey: .nutriments) ?? [:]
        nutriments = raw.compactMapValues(\.value)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `swift test --filter OFFDecodingTests`
Expected: PASS (both).

- [ ] **Step 6: Commit**

```bash
git add Package.swift Sources/CoffeeBeanCore/Food/OFFResponse.swift Tests/CoffeeBeanCoreTests/Fixtures Tests/CoffeeBeanCoreTests/OFFDecodingTests.swift
git commit -m "feat: lenient Open Food Facts response decoding"
```

---

### Task 12: Open Food Facts normalization → `RemoteFood` + `FoodSource`

**Files:**
- Create: `Sources/CoffeeBeanCore/Food/RemoteFood.swift`
- Create: `Sources/CoffeeBeanCore/Food/OpenFoodFactsParser.swift`
- Create: `Sources/CoffeeBeanCore/Food/FoodSource.swift`
- Test: `Tests/CoffeeBeanCoreTests/OFFParserTests.swift`

**Interfaces:**
- Consumes: `OFFResponse`.
- Produces:
  - `struct RemoteFood: Equatable, Sendable { let barcode: String?; let name: String; let brand: String?; let kcalPer100g, proteinPer100g, carbPer100g, fatPer100g: Double; let servingSizeText: String?; let imageURL: String? }`
  - `enum OpenFoodFactsParser { static func parse(_ response: OFFResponse, barcode: String) -> RemoteFood? }` — nil unless found AND name present AND a usable kcal value (direct or kJ/4.184).
  - `protocol FoodSource: Sendable { func lookup(barcode: String) async throws -> RemoteFood? }`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class OFFParserTests: XCTestCase {
    private func fixture(_ name: String) throws -> OFFResponse {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode(OFFResponse.self, from: Data(contentsOf: url))
    }
    func testParsesNutella() throws {
        let food = OpenFoodFactsParser.parse(try fixture("off_nutella"), barcode: "3017624010701")!
        XCTAssertEqual(food.name, "Nutella")
        XCTAssertEqual(food.kcalPer100g, 539, accuracy: 1e-6)
        XCTAssertEqual(food.proteinPer100g, 6.3, accuracy: 1e-6)
    }
    func testDerivesKcalFromKJ() throws {
        // 1000 kJ / 4.184 = 239.006 kcal
        let food = OpenFoodFactsParser.parse(try fixture("off_kj_only"), barcode: "1111111111111")!
        XCTAssertEqual(food.kcalPer100g, 239.006, accuracy: 0.01)
    }
    func testNilWhenNotFound() {
        let r = OFFResponse.notFound(code: "000")
        XCTAssertNil(OpenFoodFactsParser.parse(r, barcode: "000"))
    }
    func testNilWhenNoUsableEnergy() {
        let r = OFFResponse.placeholder(name: "Empty", code: "999") // name but no nutriments
        XCTAssertNil(OpenFoodFactsParser.parse(r, barcode: "999"))
    }
}

// Test-only builders for synthetic responses.
extension OFFResponse {
    static func notFound(code: String) -> OFFResponse {
        try! JSONDecoder().decode(OFFResponse.self,
            from: Data(#"{"status":0,"code":"\#(code)"}"#.utf8))
    }
    static func placeholder(name: String, code: String) -> OFFResponse {
        try! JSONDecoder().decode(OFFResponse.self,
            from: Data(#"{"status":1,"code":"\#(code)","product":{"product_name":"\#(name)","nutriments":{}}}"#.utf8))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OFFParserTests`
Expected: FAIL (`RemoteFood`/`OpenFoodFactsParser` not defined).

- [ ] **Step 3: Write minimal implementation**

`RemoteFood.swift`:
```swift
import Foundation

public struct RemoteFood: Equatable, Sendable {
    public let barcode: String?
    public let name: String
    public let brand: String?
    public let kcalPer100g: Double
    public let proteinPer100g: Double
    public let carbPer100g: Double
    public let fatPer100g: Double
    public let servingSizeText: String?
    public let imageURL: String?

    public init(barcode: String?, name: String, brand: String?,
                kcalPer100g: Double, proteinPer100g: Double, carbPer100g: Double,
                fatPer100g: Double, servingSizeText: String?, imageURL: String?) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbPer100g = carbPer100g
        self.fatPer100g = fatPer100g
        self.servingSizeText = servingSizeText
        self.imageURL = imageURL
    }
}
```

`OpenFoodFactsParser.swift`:
```swift
import Foundation

public enum OpenFoodFactsParser {
    private static let kjPerKcal = 4.184

    /// Normalize an OFF response to a usable RemoteFood, or nil if not found / not nutritionally usable.
    public static func parse(_ response: OFFResponse, barcode: String) -> RemoteFood? {
        // "found" requires status == 1 and a product with a name.
        guard response.status == 1, let p = response.product,
              let name = p.productName, !name.isEmpty else { return nil }

        // Usable energy: direct kcal, else derive from kJ.
        let kcal: Double?
        if let direct = p.nutriments["energy-kcal_100g"] {
            kcal = direct
        } else if let kj = p.nutriments["energy-kj_100g"] {
            kcal = kj / kjPerKcal
        } else {
            kcal = nil
        }
        guard let energy = kcal else { return nil }

        return RemoteFood(
            barcode: barcode,
            name: name,
            brand: p.brands,
            kcalPer100g: energy,
            proteinPer100g: p.nutriments["proteins_100g"] ?? 0,
            carbPer100g: p.nutriments["carbohydrates_100g"] ?? 0,
            fatPer100g: p.nutriments["fat_100g"] ?? 0,
            servingSizeText: p.servingSize,
            imageURL: p.imageFrontSmallURL
        )
    }
}
```

`FoodSource.swift`:
```swift
import Foundation

/// Abstraction over where food nutrition comes from (Open Food Facts today; a licensed DB / backend later).
public protocol FoodSource: Sendable {
    func lookup(barcode: String) async throws -> RemoteFood?
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OFFParserTests`
Expected: PASS (all 4).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Food/RemoteFood.swift Sources/CoffeeBeanCore/Food/OpenFoodFactsParser.swift Sources/CoffeeBeanCore/Food/FoodSource.swift Tests/CoffeeBeanCoreTests/OFFParserTests.swift
git commit -m "feat: normalize OFF response to RemoteFood + FoodSource protocol"
```

---

### Task 13: Open Food Facts client (URL construction)

**Files:**
- Create: `Sources/CoffeeBeanCore/Food/OpenFoodFactsClient.swift`
- Test: `Tests/CoffeeBeanCoreTests/OFFClientTests.swift`

**Interfaces:**
- Consumes: `FoodSource`, `RemoteFood`, `OpenFoodFactsParser`.
- Produces:
  - `struct OpenFoodFactsClient: FoodSource { init(baseURL: URL, userAgent: String, session: URLSession); func productURL(barcode: String) -> URL; func lookup(barcode:) async throws -> RemoteFood? }`
  - `static let productionBaseURL`, `static let stagingBaseURL`.
  - We unit-test **URL construction + header** (pure, offline); the live network call is exercised by the app.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import CoffeeBeanCore

final class OFFClientTests: XCTestCase {
    func testProductURLIncludesFieldsAndBarcode() {
        let client = OpenFoodFactsClient(
            baseURL: OpenFoodFactsClient.productionBaseURL,
            userAgent: "CoffeeBean/1.0 (engineering@month2month.com)")
        let url = client.productURL(barcode: "3017624010701")
        let s = url.absoluteString
        XCTAssertTrue(s.hasPrefix("https://world.openfoodfacts.org/api/v2/product/3017624010701"))
        XCTAssertTrue(s.contains("fields="))
        XCTAssertTrue(s.contains("energy-kcal_100g") || s.contains("nutriments"))
    }
    func testStagingBaseURL() {
        XCTAssertEqual(OpenFoodFactsClient.stagingBaseURL.absoluteString,
                       "https://world.openfoodfacts.net")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OFFClientTests`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenFoodFactsClient: FoodSource {
    public static let productionBaseURL = URL(string: "https://world.openfoodfacts.org")!
    public static let stagingBaseURL = URL(string: "https://world.openfoodfacts.net")!

    private static let fields = [
        "code", "product_name", "brands", "serving_size", "serving_quantity",
        "nutriments", "nutrition_data_per", "image_front_small_url"
    ].joined(separator: ",")

    let baseURL: URL
    let userAgent: String
    let session: URLSession

    public init(baseURL: URL = OpenFoodFactsClient.productionBaseURL,
                userAgent: String,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.session = session
    }

    public func productURL(barcode: String) -> URL {
        var comps = URLComponents(url: baseURL.appendingPathComponent("api/v2/product/\(barcode)"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "fields", value: Self.fields)]
        return comps.url!
    }

    public func lookup(barcode: String) async throws -> RemoteFood? {
        var request = URLRequest(url: productURL(barcode: barcode))
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        return OpenFoodFactsParser.parse(decoded, barcode: barcode)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OFFClientTests`
Expected: PASS (both).

- [ ] **Step 5: Commit**

```bash
git add Sources/CoffeeBeanCore/Food/OpenFoodFactsClient.swift Tests/CoffeeBeanCoreTests/OFFClientTests.swift
git commit -m "feat: Open Food Facts client (URL + User-Agent + lookup)"
```

---

### Task 14: Full-suite green + README

**Files:**
- Create: `Sources/CoffeeBeanCore/README.md`

- [ ] **Step 1: Run the entire test suite**

Run: `swift test`
Expected: ALL tests pass (Tasks 0–13), zero failures.

- [ ] **Step 2: Write `Sources/CoffeeBeanCore/README.md`**

```markdown
# CoffeeBeanCore

Pure-Foundation domain logic for the Coffee Bean health app. No SwiftData,
HealthKit, SwiftUI, or third-party dependencies — builds and tests on the
host toolchain with `swift test`.

## Modules
- **Units** — `UnitSystem`, `QuantityKind`, `Quantity` (canonical SI storage,
  metric⇄US display, composite ft/in).
- **Energy** — `BMR` (Mifflin-St Jeor, Katch-McArdle), `RMRResolver`
  (DEXA > Katch > Mifflin), `TEF`, `EnergyBalance` (static TDEE + balance),
  `CalorieTarget`, `MacroSplit`, `RateOfGain`, `AdaptiveTDEE`.
- **Trend** — `TrendEngine` (EWMA on a daily grid with gap interpolation,
  weekly rate, goal projection, warm-up).
- **Food** — Open Food Facts decoding/normalization (`OFFResponse`,
  `OpenFoodFactsParser` → `RemoteFood`), `FoodSource` protocol,
  `OpenFoodFactsClient`.

## Canonical units
kg (body), g (food), mL (volume), cm (height), kcal (energy). Convert only
at the display boundary. Energy density constant: `kcalPerKg = 7700`.

## Consumed by
The iOS app maps its SwiftData `@Model` types to/from these value types and
calls these stateless services.
```

- [ ] **Step 3: Commit**

```bash
git add Sources/CoffeeBeanCore/README.md
git commit -m "docs: CoffeeBeanCore package README + full suite green"
```

---

## Self-Review

**1. Spec coverage (against `2026-07-15-health-app-design.md`):**
- Units & measurement (§11) → Tasks 1–2. ✅
- RMR resolver + priority (§5.1) → Tasks 3–4. ✅
- TDEE + TEF + balance (§5.2–5.3) → Tasks 5–6. ✅
- Lean-bulk targets + macro split + rate-of-gain (§5.4, design §7) → Task 7. ✅
- Weight-trend EWMA + rate + projection (§6.1) → Tasks 8–9. ✅
- Adaptive TDEE + DEXA reconciliation (§5.5) → Task 10. ✅
- Open Food Facts decode/normalize/client + FoodSource abstraction (§3.3, §7.2) → Tasks 11–13. ✅
- **Deferred to later plans (correctly out of scope for a pure-logic package):** SwiftData `@Model`s + CloudKit (§4, §12), HealthKit (§10), SwiftUI screens + IA (design handoff), notifications (§13), Watch/widgets (§14–15). These need Xcode/iOS SDK and are separate plans.

**2. Placeholder scan:** No TBD/TODO; every step has runnable code and an exact command. ✅

**3. Type consistency:** `Quantity`, `Biometrics`, `RMRResult`/`RMRSource`, `Macros`, `TEFMode`, `MacroSplit`, `CalorieTarget`, `TrendPoint`/`WeighIn`/`TrendEngine`, `AdaptiveResult`, `OFFResponse`/`OFFProduct`, `RemoteFood`, `FoodSource`, `OpenFoodFactsParser`, `OpenFoodFactsClient` — each defined once and referenced with matching signatures downstream. `kcalPerKg` defined once (Task 10) and used as the energy-density constant. ✅

## Follow-on plans (not this plan)
1. **App scaffold & data layer** — Xcode project (via XcodeGen `project.yml` or Xcode), SwiftData `@Model`s authored to the CloudKit rules (§4), App-Group + CloudKit `ModelContainer`, mapping to/from `CoffeeBeanCore` value types, `HealthStore` wrapper.
2. **Feature verticals** recreating the design handoff: Food (home) · Water · Body · Train · Settings — one plan each, in the spec's build order.
3. **Sync, reminders, app icon (bean-in-ring), polish.**
