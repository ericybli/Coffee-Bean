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
