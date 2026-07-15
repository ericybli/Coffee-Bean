# Health App — Design Spec (v1)

- **Working title:** Coffee Bean (placeholder, from repo name — rename freely)
- **Date:** 2026-07-15
- **Status:** Approved design shape; pending final spec review before implementation planning
- **Author:** Eric + Claude (brainstorming session)
- **Platforms:** iOS 26 (iPhone). Apple Watch, widgets, Siri = **v2** (designed-for now, built later).
- **Target devices:** iPhone 16 Pro Max, iPhone 17 Pro Max (v1). Apple Watch SE 2, Series 11 (v2).

---

## 1. Vision & Goals

A **free, self-use** iOS + Apple Watch health app that unifies what is today scattered across **MyFitnessPal (nutrition) + Apple Notes (training) + WaterMinder (water)** into one app, tuned for the owner's current **clean/lean-bulk** phase. The architecture leaves a clean path to a future product without paying for that option now.

### Primary goals
1. **One daily driver.** Replace three apps. The daily loop — log meals, water, training, weight — must be fast enough that the app becomes the thing opened every day.
2. **An adaptive energy-balance engine as the spine.** Tie *intake ↔ expenditure ↔ weight trend* into one loop that gets more accurate the longer it's used (this is the differentiator; MacroFactor-style).
3. **Precision for a lean bulk.** Track a controlled surplus and read the smoothed weight trend to distinguish muscle from fat gain.
4. **Free.** No paid nutrition APIs, no per-call AI costs, no backend, no accounts.
5. **Trust the best measurement available.** When the owner has a DEXA-measured RMR, use it as the source of truth over any formula.

### Non-goals (v1)
- No accounts, no backend, no social features, no monetization.
- No licensed commercial food database (uses free Open Food Facts + a personal library).
- No AI photo/text meal estimation (costs money per call; conflicts with "free"; deferred to a possible later opt-in).
- No advanced training programming, periodization, or per-muscle volume landmarks (v3).
- No Apple Watch app, widgets, Siri, or Live Activities (v2).

### Guiding principles
- **Local-first.** The app is fully functional with no iCloud account; sync is an enhancement, never a dependency.
- **Design for the future product, pay for it later.** Swappable data-source interfaces (food source, expenditure source) so a future backend/licensed DB changes one layer, not the app.
- **Measurement beats formula.** Source-priority everywhere: measured > body-composition-derived > population formula.
- **Snapshot history.** A logged entry preserves the numbers as they were at log time; later edits to a food/target never rewrite the past.

---

## 2. Scope & Phasing

### v1 — iPhone (this spec)
Energy-balance engine · Body composition (weight + DEXA) · Water · Basic strength logging · HealthKit read/write · SwiftData + CloudKit sync · unit toggle · minimal reminders.

### v2 — Apple Watch + intelligence + satellites
- **Apple Watch app** (deliberately narrow): show **water %** and **calorie %** of the daily plan; quick-log **water / caffeine / food** (food = pick from recents/favorites, no search). Nothing else on the watch.
- **Adaptive TDEE** (empirical maintenance from intake↔trend) + **weekly review** + goal-date projection.
- **Supplements** module + reminders engine.
- **Caffeine** tracking (reuses the water preset/log pattern) + sleep-aware cutoff reminder.
- **Body photos** timeline/compare.
- **Widgets** (home/lock-screen), **Siri/App Intents**, **Live Activities / Dynamic Island**.

### v3 — training depth + insights
- Training programs/templates, periodization/deload, per-muscle weekly volume (MEV/MAV/MRV), 1RM/PR tracking, plate calculator, RPE/RIR.
- Cross-feature correlation insights (sleep × weight × training × diet).
- Micronutrients, fasting window, menstrual cycle (if applicable).
- Data export / coach mode / (if productized) backend + accounts.

> **v1 is authored to not block v2/v3.** Watch-facing rollups, the versioned target entity, App-Group-shared store, and generic preset/log models all exist from day one so later phases add code, not migrations.

---

## 3. Architecture

### 3.1 Stack

| Layer | Choice | Notes |
|---|---|---|
| UI | **SwiftUI** | Shared idiom for iPhone + future Watch. |
| Persistence | **SwiftData** (`@Model`) | iOS 17+ native store. |
| Sync | **SwiftData + CloudKit private DB** | Zero backend, zero accounts; uses device iCloud login. Private DB only (fine for single user). |
| Charts | **Swift Charts** | Trend lines, BMI, body-comp, macros. |
| Health data | **HealthKit** | Read active energy + body; write nutrition/water/weight/body back. |
| Barcode | **VisionKit `DataScannerViewController`** + **Open Food Facts** REST | Free nutrition by barcode. AVFoundation fallback for pre-A12 (not needed on target devices). |
| Reminders | **UserNotifications** (local) | Weigh-in/water in v1; supplements v2. |
| Backend / accounts | **None** (v1) | Data-source layer abstracted for the future. |

### 3.2 Module layering

```
┌───────────────────────────────────────────────────────────┐
│ Presentation (SwiftUI views, per feature)                 │
├───────────────────────────────────────────────────────────┤
│ Feature stores / view models (@Observable)                │
├───────────────────────────────────────────────────────────┤
│ Domain services                                           │
│  • EnergyBalanceEngine (RMR resolver, TDEE, TEF, surplus) │
│  • TrendEngine (EWMA weight trend, rate-of-change)        │
│  • TargetService (lean-bulk target generator)             │
│  • RollupService (maintains DailyRollup)                  │
│  • UnitService (canonical ↔ display)                      │
├───────────────────────────────────────────────────────────┤
│ Data sources (protocol-abstracted — the future-product    │
│  swap point)                                              │
│  • FoodSource  → OpenFoodFactsSource | LocalLibrarySource │
│  • ExpenditureSource → HealthKitSource                    │
│  • HealthStore (HKHealthStore wrapper)                    │
├───────────────────────────────────────────────────────────┤
│ Persistence: SwiftData ModelContainer (App-Group URL,     │
│  CloudKit private DB) + shared Swift package of @Models   │
└───────────────────────────────────────────────────────────┘
```

- **Models live in a shared Swift package** so the future Watch/widget targets import the exact same schema.
- **`FoodSource` protocol** (`lookup(barcode:)`, `search(query:)`) has an `OpenFoodFactsSource` today; a future licensed DB or backend is a new conformer.
- The **ModelContainer uses an App-Group container URL from day one** (even though widgets are v2) so adding an extension later needs no data migration.

### 3.3 Data-source abstraction (future-product hook)

```swift
protocol FoodSource {
    func lookup(barcode: String) async throws -> RemoteFood?   // nil = not found
    func search(_ query: String) async throws -> [RemoteFood]  // v1: local library only
}
```
`RemoteFood` is a transport struct normalized to canonical units (per-100g grams, kcal). Persisting it into the personal library is the app's concern, not the source's.

---

## 4. Data Model (SwiftData)

**CloudKit-mandated rules applied to every model** (from research — violating these silently breaks sync):
- Every stored property is **optional or has a default**.
- **No `@Attribute(.unique)`** — identity is a plain `var id: UUID = UUID()`; de-dup in app code.
- Every relationship is **optional and has an explicit `inverse:`**; delete rules are `.cascade`/`.nullify` only (no `.deny`).
- **No ordered relationships** — use an explicit `var sortIndex: Int = 0`.
- To-many relationships are optional arrays; expose a non-optional computed accessor (`var sets: [SetEntry] { _sets ?? [] }`).
- **Migration is add-only after first Production deploy** (see §12).

### 4.1 Entity overview

| Entity | Purpose | Key fields |
|---|---|---|
| `AppSettings` | Singleton (code-enforced) | `unitSystemRaw`, `tefModeRaw`, `trendAlpha`, `activeEnergyEnabled` |
| `UserProfile` | The person | `sex`, `birthDate`, `heightCm`, `activityLevelRaw` (PAL seed), `goalTypeRaw`, `rmrSourcePreferenceRaw` |
| `Food` | Library item (nutrition per 100g) | `name`, `brand?`, `barcode?`, `sourceRaw`, `isFavorite`, `kcalPer100g`, `proteinPer100g`, `carbPer100g`, `fatPer100g`, `fiberPer100g?`, `sodiumPer100g?`, `imageURL?`, `fetchedAt?`, `completenessNote?` |
| `ServingUnit` | Named portion of a `Food` | `label`, `gramsEquivalent`, `sortIndex`, `food` (inverse) |
| `FoodLogEntry` | A logged food (diary row) | `day`, `mealSlotRaw`, `loggedAt`, `food?`, `servingUnit?`, `quantity`, **snapshot** `kcal/protein/carb/fat`, `sourceRaw` |
| `MealTemplate` + `TemplateItem` | Saved reusable "meal" | template: `name`; item: `food?`, `servingUnit?`, `quantity`, `sortIndex` |
| `WeightLog` | Raw daily scale weight | `date`, `massKg`, `sourceRaw`, `loggedAt` |
| `BodyScan` | DEXA (or other) body scan | `date`, `bodyFatFraction?`, `leanMassKg?`, `fatMassKg?`, `rmrKcal?`, `isRMRAuthoritative`, `reportImageData?`, `notes?` |
| `TargetVersion` | Versioned goal/targets | `effectiveDate`, `kcalTarget`, `proteinTargetG`, `carbTargetG`, `fatTargetG`, `surplusPct`, `maintenanceTDEE`, `rmrSourceRaw` |
| `DrinkPreset` | One-tap quick-add preset | `label`, `volumeMl`, `drinkTypeRaw` (water/caffeine…), `caffeineMgPerServing?`, `iconName`, `sortIndex` |
| `DrinkLog` | A logged drink | `timestamp`, `volumeMl`, `drinkTypeRaw`, `caffeineMg?`, `preset?` |
| `Exercise` | Catalog movement | `name`, `categoryRaw` (muscle group), `equipmentRaw`, `isCustom` |
| `WorkoutSession` | A training session | `date`, `name?`, `notes?`, `startedAt?`, `endedAt?` |
| `SetEntry` | One set | `exercise?`, `session?`, `sortIndex`, `weightKg`, `reps`, `setTypeRaw`, `isDone` |
| `DailyRollup` | Precomputed day summary | `date`, `caloriesConsumed`, `calorieTarget`, `protein/carb/fat` consumed+target, `waterConsumedMl`, `waterTargetMl`, `activeEnergyKcal`, `expenditureTDEE`, `surplusDeficit`, `trendWeightKg` |

### 4.2 Design decisions baked into the model
- **Nutrition is stored per-100g on `Food`; portions are named `ServingUnit`s with `gramsEquivalent`.** A diary entry = `servingUnit × quantity`. This matches MyFitnessPal's fast-logging pattern and Open Food Facts data. Never grams-only.
- **`FoodLogEntry` snapshots macros at log time.** Editing a `Food` or re-scanning a barcode (which pulls fresh, possibly different Open Food Facts data) must not rewrite history.
- **Weight trend is derived, never stored as source of truth.** `WeightLog` holds raw; `TrendEngine` computes the EWMA series (a cached trend value may live on `DailyRollup` for cheap reads, but it is always recomputable from raw).
- **`TargetVersion` is versioned** (append a new row on each change / weekly check-in) so adaptive-TDEE history is preserved. v1 has one current row with an `effectiveDate`.
- **`DrinkPreset`/`DrinkLog` are generic over `drinkType`** so v2 caffeine reuses them instead of a parallel schema.
- **`mealSlot` is an enum-with-custom / small lookup**, not a hardcoded 4-value enum (slots are renameable and count can change).
- **`DailyRollup` exists in v1** (drives cheap dashboard/widget reads and is the v2 Watch read surface). `RollupService` recomputes it on every relevant write.
- **Indices** planned on `FoodLogEntry.day`, `(food, loggedAt)`, `WeightLog.date`, `DrinkLog.timestamp`.

---

## 5. Energy-Balance Engine (the spine)

### 5.1 RMR resolver (source priority)

```
resolveRMR() -> (value: kcal/day, source):
  1. DEXA-measured RMR  — latest BodyScan where isRMRAuthoritative && rmrKcal != nil
  2. Katch-McArdle      — from latest BodyScan lean mass:  BMR = 370 + 21.6 × LBM_kg
  3. Mifflin-St Jeor    — fallback from profile:
        male:   BMR = 10·kg + 6.25·cm − 5·age + 5
        female: BMR = 10·kg + 6.25·cm − 5·age − 161
```
- The active source is stored on the resolved result so the UI can show it ("RMR: 1,780 kcal · from DEXA 2026-06-30") and the DEXA-reconciliation view can anchor on it.
- **Katch-McArdle is gated behind a real DEXA lean-mass entry**, not a typed body-fat guess (a bad body-fat % makes it worse than Mifflin).
- A DEXA RMR stays authoritative **until the next DEXA scan** (or the user un-pins it).

### 5.2 TDEE composition (v1, static)

```
TDEE = RMR + activeEnergy_kcal(HealthKit, today) + TEF
```
- **`activeEnergy` is an *optional, adjustable input, not ground truth.*** On an iPhone-only setup HealthKit active energy is sparse (no watch) and under-counts lifting. If today's sum is 0 (watch not worn), surface a "no activity data — using estimate" state and fall back to a PAL-seeded estimate `RMR × (PAL − 1)`.
- **TEF** (thermic effect of food), default **flat 10%** (`TEF = 0.10 × intake`), with an optional **per-macro** mode (`0.25·Pkcal + 0.08·Ckcal + 0.02·Fkcal`) that rewards the owner's high protein. Configurable in `AppSettings.tefMode`.
- **Do not double-count activity:** use *either* `RMR × PAL` *or* `RMR + HealthKit active + TEF`, never both. HealthKit active energy already includes exercise + most NEAT.
- **`basalEnergyBurned` from HealthKit is unused** — it's essentially Apple-Watch-only and there is no RMR/BMR "rate" type in HealthKit. RMR lives only in our engine (never written to HealthKit).

### 5.3 Surplus / deficit
```
balance = intake_kcal − TDEE          // + = surplus (bulk), − = deficit
```
Displayed prominently on the dashboard, framed for the bulk (target = small green surplus).

### 5.4 Lean-bulk target generator (`TargetService`)
```
maintenance      = adaptiveTDEE (v2) OR TDEE_static (v1)
calorieTarget    = maintenance × (1 + surplusPct)     // surplusPct default 0.10, clamp 0.05–0.15
                   (or an absolute +250 kcal default)
proteinTargetG   = clamp(1.6…2.2, default 2.0) × bodyweightKg
fatTargetG       = max(0.8 × bodyweightKg, 0.25 × calorieTarget / 9)   // hormone floor
carbTargetG      = (calorieTarget − proteinKcal − fatKcal) / 4
```
- **Rate-of-gain guardrail** from the weight *trend* slope (never day-over-day): target **0.25–0.5 %BW/week** (green), 0.5–0.75 % (caution), >1 lb/week (pull surplus back).

### 5.5 Adaptive TDEE (v2 — designed here so v1 persists the right data)
```
trend[t]      = trend[t−1] + α·(scale[t] − trend[t−1])       // α = 0.1 (see §6)
adaptiveTDEE  = mean(intake over W) − KCAL_PER_KG × (trend[end] − trend[start]) / W
               // W = trailing 14–28 days;  KCAL_PER_KG = 7700 (KCAL_PER_LB = 3500)
```
- **Gating:** show a confident adaptive number only after **≥14 days AND ≥~8 weigh-ins**; before that, use `TDEE_static`, labeled "stabilizing." Blend static→adaptive with a confidence weight ramping 0→1 across days 7–21.
- **Early-phase confound:** exclude/down-weight the first ~7–14 days after a phase change (glycogen/water/creatine, not tissue) with a visible disclaimer.
- **DEXA reconciliation:** treat DEXA RMR as a fixed resting floor; derive & display
  `impliedActivity+TEF = adaptiveTDEE − RMR`, `impliedActiveEnergy = adaptiveTDEE − RMR − TEF` (cross-check vs mean HealthKit active), `impliedActivityMultiplier = adaptiveTDEE / RMR` (sane ~1.2–1.9; warn outside ~1.1–2.2 → under-logging or scale error).
- **Convergence note for implementers:** because the loop self-corrects weekly, the exact energy-density constant mostly affects convergence speed, not the converged value — don't over-tune it. For *forward surplus prescription* during a lean bulk, prefer a mixed-tissue planning constant (~5,000–6,600 kcal/kg gained) rather than the fat-only 7,700.

**v1 must persist:** daily intake totals + raw weigh-ins (in `DailyRollup` + `WeightLog`) so v2 adaptive starts warm, not cold.

### 5.6 Unit-test obligations (engine)
- Back-calc **sign**: trend up ⇒ maintenance < intake (was in surplus). Test a gain and a loss scenario.
- RMR resolver picks the correct source at each priority tier.
- One canonical energy-density constant in SI (`7700 kcal/kg`), derive `kcal/lb` (avoid 3500 vs 7716 drift).
- TEF flat vs per-macro consistency; TEF added to expenditure (not subtracted from intake) applied consistently.

---

## 6. Body Composition & Weight Trend

### 6.1 Weight trend (`TrendEngine`)
- **EWMA, default α = 0.1** (Hacker's Diet / TrendWeight / MacroFactor lineage): `T[t] = T[t−1] + 0.1·(W[t] − T[t−1])`. Half-life ≈ 6.6 days, ~20-day-SMA lag. Seed `T0` = first weigh-in (or mean of first 3).
- **Compute on a per-calendar-day grid** in one consistent calendar (normalize each weigh-in to `startOfDay`; average multiple same-day weigh-ins before smoothing).
- **Gaps → linear-interpolate** raw weigh-ins onto the daily grid (MacroFactor's method), then run the recursion. (Not trend-substitution, which flat-lines gaps.)
- **Time-aware option** for long gaps: `α_eff = 1 − (1−α)^Δdays`.
- **Precompute** the `[(date, rawAvg?, trend, slope)]` array in the model layer — never inside the Chart body.
- **Weekly rate** = `7 × slope`, slope = least-squares fit over trailing **14–28 days** (28 for a slow lean bulk). Feeds the engine and goal projection.
- **α exposed as an advanced "trend responsiveness" setting** (~0.05–0.15).
- **Warm-up flag** for the first ~13 days (~2 half-lives) — don't compute rate/goal-date yet.

### 6.2 DEXA / body scans
- `BodyScan` holds body-fat %, lean mass, fat mass, optional measured RMR (+ authoritative flag), and an attached report image.
- Feeds: RMR resolver (§5.1), Katch-McArdle LBM, and the body-comp charts.
- Charts: lean mass + fat mass (kg/lb), body-fat %, optional RMR — `PointMark` at each scan date connected by `.interpolationMethod(.linear)` (or `.stepEnd`), annotated. **Never auto-interpolate DEXA as a dense daily line** (implies precision you don't have).

### 6.3 BMI
- Kept (owner requested) as a **de-emphasized secondary** line: `BMI = kg / m²`, muted, explicitly labeled "context only — misclassifies muscular users."

### 6.4 Charting rules (Swift Charts)
- Raw weigh-ins = faint `PointMark` (secondary, low opacity, small symbol); trend = bold `LineMark` `.interpolationMethod(.monotone)`, width ~2.5.
- **Never `.catmullRom`/`.cardinal`** (overshoot → fake dips/peaks — the #1 weight-trend charting bug).
- `.chartYScale(domain: .automatic(includesZero: false))` so small ranges aren't crushed.
- Goal projection = dashed `LineMark` from last trend point at current slope + `RuleMark` at goal weight; labeled a linear estimate.
- Optional ± band via `AreaMark(yStart:yEnd:)`.
- Large histories → vectorized `LinePlot`/`PointPlot`.
- **Explain the lag:** the back-looking trend reads higher than the scale during a cut and lower during a bulk — surface a one-liner, don't "fix" it.

---

## 7. Meal Logging & Food Library

### 7.1 Logging paths (in priority of speed)
1. **Recents / favorites / "copy yesterday" / meal templates** — the fastest re-log path (a query over recent `FoodLogEntry`, plus `isFavorite` and `MealTemplate`).
2. **Barcode scan** → local cache → Open Food Facts.
3. **Manual entry** (and it's the universal fallback).

### 7.2 Open Food Facts integration (verified 2026)
- **Endpoint:** `GET https://world.openfoodfacts.org/api/v2/product/{barcode}?fields=code,product_name,brands,serving_size,serving_quantity,nutriments,nutrition_data_per,image_front_small_url`
- **Required custom `User-Agent`:** `CoffeeBean/1.0 (engineering@month2month.com)` (no API key for reads; default UA risks throttling).
- **Field paths:** `product.nutriments["energy-kcal_100g"]`, `proteins_100g`, `carbohydrates_100g`, `fat_100g`; `serving_quantity` (grams, may be string/absent); `nutrition_data_per` ("100g"|"serving"). **`energy_100g` is kJ — always use `energy-kcal_*`.** Decode `nutriments` as a lenient `[String: Number-or-String]` dictionary (hyphenated keys aren't Swift identifiers; values vary in type).
- **Rate limits:** 15 req/min/IP product reads. Trivial for a manual scanner (~1 req/scan). **Cache permanently by barcode** — never re-hit for a known barcode (offer a manual "refresh").
- **"Found but empty" is common:** a valid barcode can return `status:1` with a name but no nutriments (placeholder entries). **Accept only if** HTTP 2xx **and** found **and** (`product_name` present **and** a usable `energy-kcal` value). Otherwise → treat as not-found → manual entry, pre-filled with whatever partial data came back.
- **Not-found is inconsistent** (both `200 + status:0` and occasional `404`) — treat *any* of {404, status:0, found-but-empty} identically as "manual entry."
- **License (ODbL):** private, personal caching is unencumbered. If ever productized: attribute "Open Food Facts," keep OFF-sourced records logically separable (store `source = .openFoodFacts`), share-alike attaches only to a redistributed derived database. `source` flag is on `Food` already.
- **Dev:** point debug builds at staging `https://world.openfoodfacts.net` (Basic auth `off`/`off`).
- **Coverage caveat:** Chinese/restaurant/loose foods are patchy or unscannable — the manual + personal-library path carries real weight; treat OFF as a convenience, not the backbone.

### 7.3 Barcode scanning
- **VisionKit `DataScannerViewController`** (gate on `isSupported && isAvailable`), symbologies `[.ean13, .ean8, .upce]` (UPC-A arrives as EAN-13 with a leading `0` — normalize). `recognizesMultipleItems: false`, debounce so one physical scan = one lookup.
- `NSCameraUsageDescription` required. Denied camera → route to manual entry.

### 7.4 Serving/normalization
- Store nutrition **per-100g**; import converts (kJ→kcal `/4.184`; scale by `portionGrams/100`).
- `serving_size` is free text — a *hint/prefill* only; the portion the user logs is a `ServingUnit.gramsEquivalent × quantity`. Compute per-serving on demand; don't depend on OFF `_serving` keys existing.
- Diary organized by renameable **meal slots**; `FoodLogEntry` snapshots macros.

---

## 8. Water Tracking (replaces WaterMinder)

- **One-tap quick-add is the whole value prop.** `DrinkPreset` list (custom sizes/labels/icons) is built in v1.
- `DrinkLog` timestamps each add; dashboard shows a water ring vs `waterTargetMl` (from `AppSettings`/`TargetVersion`).
- Written to HealthKit as `dietaryWater` (mL) with `HKMetadataKeyWasUserEntered: true`.
- Generic `drinkType` field → v2 caffeine reuses the same presets/log with `caffeineMg`.

---

## 9. Strength Training (basic — replaces Notes)

Mirrors Hevy/Strong's proven model, minimal for v1:
- `Exercise` catalog (name, muscle group, equipment, `isCustom`).
- `WorkoutSession` → ordered `SetEntry` rows (`weightKg`, `reps`, `setType` warmup/normal/failure, `isDone`), ordered by `sortIndex`.
- **"Previous" pre-fill** (the biggest lifting-UX win): when adding an exercise, query its most recent completed sets and pre-populate weight/reps as editable defaults. Default scope = "last time overall" (SetEntry query designed to filter by routine later, in v3).
- **Session volume** = Σ `weightKg × reps`; **projected 1RM** (Epley `w·(1 + reps/30)`) shown on exercise history. Per-exercise history computed on the fly.
- v1 stays out of programs/periodization/volume-landmarks (v3).

---

## 10. HealthKit Integration

### 10.1 Types & units

| Concern | Type | Unit | Dir |
|---|---|---|---|
| Active energy | `.activeEnergyBurned` | `kilocalorie()` | Read |
| Dietary energy | `.dietaryEnergyConsumed` | `kilocalorie()` | R/W |
| Protein / carbs / fat | `.dietaryProtein` / `.dietaryCarbohydrates` / `.dietaryFatTotal` | `gram()` | R/W |
| Water | `.dietaryWater` | `literUnit(with:.milli)` (mL) | R/W |
| Body mass | `.bodyMass` | `gramUnit(with:.kilo)` (kg) | R/W |
| Body fat % | `.bodyFatPercentage` | `percent()` **as fraction 0–1** (0.22 = 22%) | R/W |
| Lean mass | `.leanBodyMass` | kg | R/W |
| Height | `.height` | `meterUnit(with:.centi)` | R/W |

- **`basalEnergyBurned` deliberately unused** (watch-only; no RMR type). Use `kilocalorie()` (== `largeCalorie()`), never `calorie()` (1000× error).

### 10.2 Queries & auth
- **Daily totals:** `HKStatisticsCollectionQueryDescriptor(..., options: .cumulativeSum, anchorDate: startOfDay, intervalComponents: DateComponents(day: 1))` (correctly buckets midnight-spanning samples and apportions across sources — avoids double-counting; classic `HKStatisticsQuery` also acceptable).
- **Auth:** `try await healthStore.requestAuthorization(toShare:read:)`; Info.plist needs **both** `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`; HealthKit capability enabled.
- **Read-auth asymmetry (critical):** you *cannot* detect read denial — denied reads look like "no data." **Never gate UI on read authorization;** run the query and render an empty state.
- **Write-back** keeps Apple Health authoritative: on meal save write `dietaryEnergyConsumed` + macros, grouped via `HKCorrelation(type: .food)`; water → `dietaryWater`; weigh-in → `bodyMass`; DEXA → `bodyFatPercentage`(fraction) + `leanBodyMass` + `bodyMass`.
- **Freshness:** `HKObserverQuery` on `activeEnergyBurned` + `enableBackgroundDelivery(frequency: .hourly)` (always call the completion handler); incremental reads via `HKAnchoredObjectQueryDescriptor` with a persisted `HKQueryAnchor`. (Background delivery is device-only, not Simulator.)

---

## 11. Units & Measurement (one-tap metric ⇄ US)

- **Canonical SI storage** as plain `Double`s: `massKg`, `volumeMl`, `foodMassG`, `heightCm`, `energy kcal`. **Only mass/volume/length switch; energy is kcal in both systems.**
- **`Quantity` value type** wrapping the canonical Double + a `Dimension` enum that knows its canonical unit, metric unit, US unit, `FormatStyle` usage, and rounding rule. Vends a `Measurement` on demand; `.converted(to:)` for exact conversions; `Measurement.FormatStyle` for display.
- **Never persist** `Measurement`, `HKUnit`, or unit strings on records (breaks `#Predicate`/CloudKit) — store canonical primitives + a `unitSystemRaw` enum on `AppSettings`.
- **Height is the hard case:** ft+in is composite — `MeasurementFormatter` prints "5.92 ft". Use `FormatStyle` `usage: .personHeight` **with an explicit `en_US` locale**, or compute ft/in manually with a 12-inch carry. Entry in US mode = two fields (feet Int, inches Double).
- **Don't trust locale to honor the toggle** (format styles sometimes ignore `Locale.measurementSystem`): explicitly `.converted(to:)` the chosen unit, then format with `usage: .asProvided` / `unitOptions: .providedUnit`.
- **US = `UnitVolume.fluidOunces`/`.cups`** (US), never `.imperialFluidOunces` (UK, ~4% smaller).
- **Round for display only**; keep full-precision canonical values (dirty-check before overwrite) to avoid round-trip drift.
- **HealthKit is a pure boundary:** build `HKQuantity` from the canonical unit; read with `doubleValue(for: canonicalHKUnit)`. The toggle never touches HealthKit.
- Preference mirrored to App-Group `UserDefaults` (widgets, v2) and pushed to Watch via `WCSession.updateApplicationContext` (v2); `WidgetCenter.reloadAllTimelines()` on change.

---

## 12. Sync, Persistence & Migration

- **`ModelConfiguration`** with an **App-Group container URL** + **`cloudKitDatabase: .private("iCloud.com.<team>.CoffeeBean")`**. Capabilities: iCloud/CloudKit, Background Modes → Remote notifications, Push Notifications.
- **`migrationPlan:` wired from v1** (even with a single `SchemaV1`) so v1→v2 is painless. Use `VersionedSchema` + `SchemaMigrationPlan`.
- **After first Production deploy: add-only migrations forever** — no rename/delete/retype of synced attributes/entities (CloudKit treats it as delete+create → data loss + cold-launch `fatalError`). Deprecate instead.
- **Release checklist item:** CloudKit Console → **Deploy Schema Changes to Production** before any TestFlight/App Store build (Dev JIT schema masks this; release fails silently otherwise). Keep a `#if DEBUG` `initializeCloudKitSchema` helper; add queryable indexes so records are inspectable.
- **Known bug to design around:** custom `willMigrate`/`didMigrate` often don't fire with CloudKit on — if a data-transform migration is needed, init with `cloudKitDatabase: .none`, migrate, then re-enable on next launch.
- **Account state:** watch `CKContainer.accountStatus` / `.CKAccountChanged`; non-blocking banner when iCloud is signed out/full; note that unaccepted iCloud ToS silently stalls sync.
- **Eventually-consistent:** never assume a write is instantly visible on another device.

---

## 13. Reminders (v1, minimal)

- Local `UserNotifications` only. v1 scope: **weigh-in reminder** and **water nudges** (opt-in).
- Model reminders as a small set of **repeating `UNCalendarNotificationTrigger`** requests keyed by time-of-day; **rebuild from settings on every app foreground** (edits don't auto-update scheduled notifications).
- Respect the **64-pending cap** (repeating triggers, not one-per-future-day). Supplement reminders (many daily times) arrive in v2 — same pattern, still well under 64.
- Interruption level `.active`/`.passive` for nudges; reserve `.timeSensitive` (self-provisioned entitlement) for v2 actionable dose reminders. **Never** design around `.critical` (needs Apple approval).

---

## 14. Apple Watch (v2 — architecture reserved now)

Narrow scope: **water % + calorie %** glance, quick-log **water/caffeine/food** (recents only).
- **Data sharing:** the watchOS target gets **its own `ModelContainer` on the same CloudKit container** (App Groups do **not** cross devices). Layer **WatchConnectivity** as a low-latency shim: `updateApplicationContext` ships the latest `DailyRollup`; `transferUserInfo` queues quick-logs back; **reconcile by entry UUID** so CloudKit + WCSession never double-count. (CloudKit push to the watch is slow/unreliable — never rely on it alone.)
- **`DailyRollup` is the watch's read surface** (already built in v1) — the watch never syncs/scans raw rows.
- **Complications / Smart Stack** via WidgetKit-on-watchOS (`AccessoryCircular` rings, `RelevanceConfiguration` so a water widget surfaces mid-day).
- **Quick-log via App Intents** (same intents power watch buttons, complications, Siri).
- **SE 2 vs Series 11:** SE 2 has **no always-on display** and **no double-tap** — degrade gracefully (no reliance on AOD or double-tap; everything reachable by tap + Digital Crown).

---

## 15. Widgets / Siri / Live Activities (v2 — reserved now)

- **App-Group-shared SwiftData store from v1** (already specified) so the widget/App-Intent extension reads the same store.
- **All quick-log actions authored as `AppIntent`s** (reused by Siri/Shortcuts, interactive widgets, watch).
- Widgets: home `.systemSmall/Medium`, lock-screen `.accessoryCircular` (calorie/water ring), `.accessoryRectangular` (remaining kcal + P/C/F) using `Gauge`/`ProgressView` (survive accented/desaturated rendering; never color-only).
- Freshness by **user/app-initiated `WidgetCenter.reloadAllTimelines()`** on each write (no backend push; passive budget ~40–70/day). Reload policy `.never` or `.after(nextMidnight)`.
- Live Activity: a day-long "calorie budget remaining" in the Dynamic Island, updated locally per meal (ContentState < 4 KB).

---

## 16. Cross-Cutting Concerns

- **Privacy:** all health data on-device + user's private iCloud; no third-party servers (Open Food Facts sends only the barcode, no personal data). Clear HealthKit purpose strings.
- **Error/empty states:** first-run (no data), HealthKit not authorized (render empty, don't block), iCloud signed out, barcode not-found/offline → manual entry, adaptive-TDEE "stabilizing."
- **Testing:** engine unit tests (§5.6), trend-engine tests (gaps, multi-per-day, sign of rate), unit-conversion round-trip tests, OFF response decoding (rich / sparse / placeholder / not-found fixtures), CloudKit model-rule lint (all optional/defaulted, inverses present).
- **Accessibility:** Dynamic Type, VoiceOver labels on rings/charts, don't encode meaning in color alone.

---

## 17. Open Questions / Decisions Log

**Decided**
- Personal-use first, product-later → on-device, no backend/accounts; data-source layer abstracted. 
- Food logging = personal library + Open Food Facts barcode + manual. (No AI estimation in v1.)
- RMR priority: DEXA-measured > Katch-McArdle(DEXA LBM) > Mifflin-St Jeor.
- TDEE v1 static; adaptive TDEE v2. Weight trend EWMA α=0.1.
- Watch (v2) scope frozen to water%/calorie% + quick-log water/caffeine/food.
- Units switchable metric ⇄ US, canonical SI storage.
- iOS 26 target; iPhone-only v1.

**Open (non-blocking — resolve during planning/build)**
1. App name (working title "Coffee Bean").
2. Default meal slots & whether "snacks" is single or multiple.
3. Default `DrinkPreset` set (sizes/labels) to ship.
4. TEF default: flat 10% (proposed) vs per-macro on by default.
5. Exact onboarding order (HealthKit prompt timing vs profile setup).
6. Whether v1 ships a starter `Exercise` catalog or starts empty + user-added.

---

## 18. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| iPhone-only HealthKit expenditure is sparse/inaccurate | Treat active energy as optional input; PAL-seed fallback; adaptive TDEE (v2) self-corrects; own RMR engine. |
| Open Food Facts coverage gaps (Chinese/restaurant/loose) | Personal library + manual entry are first-class, not fallback afterthoughts; permanent local cache. |
| SwiftData+CloudKit model rigidity / silent sync failures | Author all models to CloudKit rules from day one; add-only migrations; release-checklist schema deploy; local-first so sync is optional. |
| Adaptive TDEE misleads early (glycogen/water) | Gate ≥14 days/≥8 weigh-ins; exclude first ~2 weeks; label "stabilizing"; drive off trend, not raw. |
| Scope (5 modules) too big for one build | Build module-by-module behind the shared model package + engine; DailyRollup + rollup service first, then one module end-to-end as the template. |
| Weight-trend charting overshoot misleads | `.monotone` only; precompute trend; explain lag. |

---

## 19. Suggested build order (for the implementation plan)

1. **Foundation:** shared model package (all `@Model`s to CloudKit rules) + `ModelContainer` (App-Group + CloudKit) + migration plan + `AppSettings`/`UserProfile` + `UnitService`/`Quantity`.
2. **HealthStore** wrapper + authorization + write-back plumbing.
3. **Body module** end-to-end (weigh-in, `TrendEngine`, charts, DEXA, BMI) — smallest complete vertical, exercises the model + units + HealthKit + charts.
4. **Energy engine** (RMR resolver, static TDEE, TEF, target generator) + **meal logging** (library, OFF, barcode, serving model, diary) + `RollupService`.
5. **Water** (presets, log, ring).
6. **Strength** (catalog, session, sets, "previous" pre-fill, volume).
7. **Dashboard** tying it together (reads `DailyRollup`) + reminders + onboarding.

Each vertical follows TDD; the body module is the reference pattern for the rest.
