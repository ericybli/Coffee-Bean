# Handoff: Coffee Bean — Personal Health App (iOS)

## Overview
Coffee Bean is a personal health app for a lean-bulking user (and their partner — hence "two coffee beans"). It unifies **nutrition (calories + macros), water, body tracking (weight / waist / DEXA), and training (cardio + 5-day weight split)** into one calm, numbers-forward daily tool. Target platform: **native iOS (SwiftUI), iPhone-only, portrait, dark-first with a light theme**. The design language is "quiet premium data-instrument": big tabular numerals, one warm amber accent, fixed semantic hues per metric, no gamification.

## About the Design Files
The files in this bundle are **design references created in HTML** — interactive prototypes showing intended look and behavior, **not production code to copy directly**. The task is to **recreate these designs in the target codebase's environment** (intended: SwiftUI on iOS 26 — system nav, sheets, `Gauge`, Swift Charts, SF Symbols, haptics). If no codebase exists yet, SwiftUI is the intended choice. All data logic in the prototype (seeded demo data, in-memory state) must be replaced with real persistence (SwiftData/Core Data + HealthKit + Open Food Facts API per the original product brief).

## Fidelity
**High-fidelity.** Colors, typography scale, spacing, component shapes, and interaction flows are final intent. Recreate pixel-faithfully using native equivalents (e.g. SF Pro instead of the `-apple-system` stack, real SF Symbols instead of the placeholder glyphs ◒◔↗◫⚙, which are stand-ins).

## Files
- `Coffee Bean Prototype.dc.html` — **the interactive prototype** (single file: markup between `<x-dc>` tags + logic in the `Component` class). This is the source of truth for all screens, flows, and state logic described below.
- `Coffee Bean Design.dc.html` — the exploration canvas: logo options (chosen: **1c**, bean-in-ring), style tile (**1e**), earlier Today-screen layout studies, Add Food flow mocks (library → barcode scanner → serving picker → not-found manual form), and static Body/Train studies. Use it for the logo, the style tile, and the Add Food / scanner screens that are not in the interactive prototype.

## Design Tokens

### Colors (dark theme — primary)
| Role | Value |
|---|---|
| App background | `#131110` (warm near-black) |
| Card surface | `#1d1a17`, border `rgba(255,255,255,.07)` |
| Sheet surface | `#1a1815`; popover `#221f1b` |
| Text primary | `#f2ede6` |
| Text secondary / captions | `rgba(242,237,230,.45–.7)` |
| Hairline dividers | `rgba(255,255,255,.05–.08)` |
| **Accent (energy/calories, selection, primary buttons)** | `oklch(0.75 0.15 60)` — warm amber. Text on amber: `#26190a` |
| Protein | `oklch(0.75 0.11 190)` (teal) |
| Carbs | `oklch(0.78 0.11 95)` (gold) |
| Fat | `oklch(0.75 0.11 320)` (pink-violet) |
| Water | `oklch(0.75 0.11 240)` (blue). Text on blue: `#0a1826` |
| Positive / on-track | `oklch(0.72 0.13 150)` (green) |
| Negative / delete | `oklch(0.7 0.15 25)` (red); delete chip bg `oklch(0.68 0.15 25 / .13)` |

Light theme (see style tile 1e): background `#f5f1ec`, white cards with `0 1px 3px rgba(0,0,0,.04)` shadow, accent darkened to `oklch(0.68 0.15 60)` (large fills) / `oklch(0.6 0.15 60)` (text) for contrast.

### Typography (SF Pro, tabular figures everywhere numbers update)
- Hero numbers: 28–52 pt, weight 700–800, letter-spacing −0.03em
- Screen title: 28 pt / 700; card title: 15 pt / 700
- Row title: 14 pt / 600–700; body 13–14 pt; captions 10–11 pt
- Chip/button labels: 11–13 pt / 600–700

### Shape & spacing
- Phone content inset: 20 px; card padding 14–18 px; card radius 20 px (small cards 14–18, chips 12–14, sheets 24 top radius)
- Steppers: circular 48 px (sheets) / 22–32 px (inline); hit targets ≥ 44 pt in production
- Bottom sheets: dark surface, 40×4 px grabber, backdrop `rgba(0,0,0,.5)`

## Screens / Views

### 0. Auth
- **Login**: centered ring-bean logo (96 px), "Coffee Bean" wordmark (28/800), caption "Nutrition · Water · Body · Training", Email + Password fields, amber **Sign in** button, "No account? Create one" link.
- **Sign up**: Name/Email/Password + Create account; link back to Sign in. (Prototype fields are mocks; any tap on the CTA enters the app. Production: local account, no server requirement per brief.)
- **Log out** (in Settings) returns to Login.

### 1. Shared date navigation (Food, Water, Train tabs)
- Header title **"Today"** (or "Jul 13" for other days) + chevron; tapping opens a **calendar popover** (month grid, amber circle on selected day, small amber dot under logged days, ‹ › month nav, "Back to today" link, dimmed backdrop).
- **Week strip** under header: 7 columns S M T W T F S; logged days = solid amber circle with ✓; unlogged/future = hollow ring `1.5px rgba(242,237,230,.22)`; today = 4 px amber dot floating above the letter (absolute, must not shift row alignment); selected non-today day = amber halo ring (`box-shadow: 0 0 0 2.5px bg, 0 0 0 4.5px amber@60%`).
- **Swipe left/right on the strip changes week** (touch and mouse drag, threshold ~45 px); also "‹ Prev week / Next week ›" text buttons with the week range label between. Future allowed up to +4 weeks (for training planning). "Back to today" pill appears in header when off today.
- Header right: bean-ring logo (26 px) + ⚙ settings button.

### 2. Food tab (home)
- **Calories card** (MyFitnessPal-style): title "Calories"; big line `2,140 cal / 2,750 🔥` left, `610 left` (or `over`) right; full-width amber progress bar (9 px, radius 5); caption `TDEE 2,460 (est.) · +180 kcal surplus`.
- **Macros card**: three equal columns **Carbs / Fat / Protein**, each: name (13/700), `37 g / 233` value line, 7 px progress bar in the macro's fixed hue. Targets derive from Settings (see §7).
- **Meal diary card**: five slots **Breakfast / Lunch / Dinner / Snacks / Extra**. Row: name + kcal + ▸/▾ chevron, summary line of item names (or "Nothing logged yet", dimmed title). Tapping the row **expands** an indented entry list (name · serving, kcal, red ✕ delete). The amber-tinted ＋ on each row opens the **Add Food sheet** (does not toggle expansion — stop propagation).
- **Add Food sheet**: title "Add to {slot}", Close/"Done (n added)" action, mock search field + amber barcode button, "Recent" list (name, serving · kcal, ＋ adds instantly and updates all cards live). Full add-flow reference (scanner, serving picker with quantity stepper + live macros, barcode-not-found → prefilled manual form) is in the design canvas file, section 1i.
- CTA row: amber "▣ Scan to log" + "Search".

### 3. Water tab
- **Ring** (180 px, blue, 15 px stroke): center shows **percent (34/800)**, **amount consumed** (`1,300 ml` / `44 fl oz`, blue), `of 2.0 L` caption. Animates on change.
- "Edit presets ›" link → **Edit Presets sheet** (each preset: icon, name, ±50 ml stepper; changes apply live to tiles).
- **2×2 quick-add grid**: three preset tiles (Glass 250 ml / Bottle 500 ml / Coffee 300 ml — blue-tinted, scale-down on press) + dashed **"+ Custom"** tile → **Add a Drink sheet**: type chips (Water/Coffee/Tea/Protein Shake/Juice), ±50 ml stepper, `Log Coffee · 300 ml` button.
- **Day log list**: time, `Name · amount`, red ✕ delete. Day total is the **sum of log entries** (deleting recomputes the ring).

### 4. Body tab (no date header — always current)
- **Range switcher**: segmented control `2W | 1M | 3M | 6M | 1Y` (amber active pill) controlling both charts; captions update ("Last 2 weeks" …). Long ranges sample points; raw dots hidden beyond 3M.
- **Weight card**: "Trend weight" `72.4 kg` (34/700) + "Weekly rate" `+0.31 kg/wk` green with caption `target 0.18–0.36 · in range` (imperial: 0.4–0.8 lb). Chart: faint raw dots `rgba(242,237,230,.22)` + bold amber smoothed trend line (exponential smoothing, α≈0.28 daily) + green guardrail band; caption "trend lags the scale ⓘ"; amber **"+ Log weight"** button → number sheet (±0.1 kg / ±0.2 lb stepper, Save). Weekly rate always computes from daily last-14-days regardless of view range.
- **Waist card**: current `81.6 cm` + "vs last week" delta; teal trend chart (same range/smoothing); "+ Log waist" sheet (±0.5 cm / ±0.25 in), caption "morning, relaxed".
- **DEXA Scans card**: rows (date, `Body fat 14.2% · Lean 59.8 kg · RMR 1720`), amber "RMR source" badge on the authoritative scan. **"+ Add"** → sheet with three steppers (Body fat % ±0.1, Lean mass ±0.1 kg, RMR ±10 kcal), **"Use this RMR as authoritative"** toggle (moves the badge, un-flags older scans), attach-report placeholder, Save prepends to list.
- Footer caption: "BMI 22.3 · context only — misleads for muscular users".

### 5. Train tab (uses date header; future dates plannable)
Two labeled sections, **CARDIO first, then WEIGHTS · 5-DAY SPLIT**.
- **Cardio card**: "Cardio volume" `20 min` big + "vs last cardio day" ±min (green/red) + `~140 kcal burned`; **bar chart of minutes/day for the last 8 days** (selected day teal, others gray); sessions list (type, min, ~kcal, ✕ delete); "+ Add cardio" sheet: type chips (Run 11 / Bike 8 / Row 10 / Incline Walk 7 / Swim 9 kcal·min⁻¹), ±5 min stepper with live kcal preview.
- **Weights plan card**: label "Today's session / Planned session / Logged session" (future/past aware), routine name (e.g. "Chest Day"), chips **Chest / Back / Shoulder / Leg / Arm / Rest** to reassign the day. Default weekly split: Mon Chest, Tue Back, Wed Leg, Thu Shoulder, Fri Arm, Sat+Sun Rest. Rest state: dashed card "Rest day".
- **Volume card**: "Session volume" `6,240 kg` + "vs last {routine} Day" delta kg & % (green/red); **bar chart of the last 8 same-routine sessions** (current amber). Volume = Σ weight×reps over all sets.
- **Exercise cards** (4 defaults per routine, from a 20-exercise catalog grouped by the five muscle groups): header name + ✕ remove; comparison line "Last time 100 kg × 8 × 3" vs current volume delta; grid SET | KG(/LB) | REPS with ± steppers (±2.5 kg / ±5 lb, ±1 rep) and per-set red ✕; "+ Add set" clones the last set. "+ Add exercise" → catalog sheet (name, group · default load).

### 6. Settings (full-screen push from ⚙)
- ‹ Back header; **Account card** (avatar initial on amber, name, email); **UNITS** segmented `Metric | Imperial` — switches the entire app: kg⇄lb, cm⇄in, ml⇄fl oz, stepper increments (2.5 kg⇄5 lb, 0.1 kg⇄0.2 lb, 0.5 cm⇄0.25 in), height cm⇄`5 ft 11 in` composite. Canonical storage stays metric; conversion at display time only.
- **PROFILE**: Sex chips (Male/Female), Age ±1, Height ±1 cm / ±1 in.
- **DAILY TARGETS** (see §7). **APP**: Apple Health sync + morning weigh-in reminder toggles (amber switch, 44×26). **Log out** (red-tinted).

### 7. Daily targets model (drives Food tab live)
- **Calories** — two modes (segmented): **Fixed value** (±50 kcal, min 1200) or **vs TDEE (±)** (offset stepper ±50; label reads "+150 kcal · surplus over TDEE" or "−300 · deficit under TDEE"). Result line: `= 2,610 kcal target · TDEE 2,460 (est.)`. TDEE is a placeholder constant (2,460) in the prototype — production computes RMR (+ DEXA-authoritative override) + active energy + TEF.
- **Macro split** — presets **Default 50/30/20 (C/F/P)**, **High Protein 40/20/40**, **Keto 10/65/25**, or **Custom** (Carbs & Fat ±5% steppers, Protein auto-fills the remainder; note text explains this). Stacked ratio bar in the three macro hues; each row shows `%` and computed grams: carbs & protein at 4 kcal/g, fat at 9 kcal/g of the calorie target.

## Interactions & Behavior (summary)
- All mutations update dependent numbers immediately (rings, bars, totals, deltas) with ~0.35 s width/dash transitions; add haptic ticks on quick-adds in production.
- Sheets: slide-up bottom sheets, backdrop tap closes.
- Deleting any log entry (food/water/set/cardio) recomputes totals.
- Past days are editable (backfill); future days: Food/Water empty, Train shows planned sessions.
- Week strip and calendar mark "logged" = any food or water entry that day.

## State Management (production mapping)
- Per-day records keyed by date: meals (5 slots, snapshotted food entries), water log (name + ml + time), weight, waist, train day (routine + exercises + sets + cardio sessions).
- Global: selected date, week offset, units (metric/imperial), profile (sex/age/height), targets (cal mode+value/offset, macro preset + custom ratios), preset drink sizes, toggle prefs.
- Derived: calorie/macro totals & targets, trend lines (exponential smoothing), weekly rate, session volumes, vs-last-session deltas.

## Assets
- **Logo (chosen: option 1c)**: geometric coffee bean (rotated ellipse + S-curve crease) inside a 270° amber progress ring — vector recipe in both HTML files (`<svg viewBox="0 0 64 64">`: ring r=26 stroke 4–5, dasharray 122/163, rotated −90°; bean ellipse rx 9.5 ry 13.5 rotated −25°). Recreate as an asset catalog icon; app-icon and small-size variants shown in the design canvas.
- No raster images. All glyphs in the prototype (◒ ◔ ↗ ◫ ⚙ ▣ ⌕) are placeholders → use SF Symbols (e.g. `fork.knife`, `drop`, `chart.line.uptrend.xyaxis`, `dumbbell`, `gearshape`, `barcode.viewfinder`, `magnifyingglass`).
