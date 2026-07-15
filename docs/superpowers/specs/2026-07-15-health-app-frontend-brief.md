# Health App — Frontend Design Brief

> **For:** a design pass (e.g. Claude Design / a UI designer). **Purpose:** design the v1 iPhone screens. This brief is self-contained; the companion **`2026-07-15-health-app-design.md`** holds the data model, formulas, and technical constraints if you need them.
>
> **What to produce:** screen designs / mockups for the v1 flows below, a small shared component system, and light/dark treatments. Native iOS 26 SwiftUI app — design should feel *Apple-native*, not a cross-platform reskin.

---

## 1. In one line

A **personal health app** that unifies **nutrition, energy balance (calories in vs out), body composition, water, and strength training** into one calm, numbers-forward daily tool — tuned for a user who is **lean bulking** (adding muscle on a controlled calorie surplus).

## 2. Who it's for & tone

- **A single, committed user** (the owner): trains with weights regularly, does periodic DEXA scans, tracks precisely. Not a beginner. Not gamified.
- **Tone:** honest, precise, calm, athletic. Feels like a trustworthy instrument, not a cheerleader. No streak-shaming, no confetti, no dark patterns. Respects that the user already knows what they're doing.
- **The hero emotion:** *"at a glance I know exactly where my day stands, and logging is so fast I never skip it."*

## 3. Platform & constraints

- **iOS 26, iPhone only** (designed on iPhone 16/17 Pro Max — large screens, Dynamic Island). Portrait-first.
- **Native SwiftUI** patterns: system nav/tab bars, sheets, `Gauge`/`ProgressView`, **Swift Charts** for graphs, SF Symbols, San Francisco type, haptics.
- **Light & dark themes both required** (design dark-first — see §5).
- **Dynamic Type, VoiceOver, high-contrast** must be respected (see §11).
- **Units switch metric ⇄ US** globally — every number with a unit must work as both "72.4 kg / 159.6 lb", "500 ml / 17 fl oz", "180 cm / 5 ft 11 in" (see §11).
- **No ads, no upsell, no onboarding funnel.** This is a tool the user owns.

## 4. Design principles

1. **Glance first, detail on tap.** The Today screen answers "where am I?" in under 2 seconds. Everything else is a tap deeper.
2. **Logging friction is the enemy.** The most common actions (add water, add a recent food, log a set, log weight) are 1–2 taps from where you already are. Recents / favorites / "copy yesterday" / quick-add presets are front and center.
3. **Numbers are the design.** Big, confident, legible figures. The typography *is* the UI. Charts are honest and quiet.
4. **Trend over noise.** Always show the smoothed weight *trend* prominently and raw daily weigh-ins faintly behind it. Never let a single noisy number (a 1 kg water-weight jump) dominate.
5. **Show the source & the uncertainty.** When a number is estimated (TDEE, adaptive maintenance "stabilizing"), say so quietly. Trust comes from honesty, not false precision.
6. **One accent, used with intent.** A single confident accent color for "the number that matters right now" (today's energy balance). Macros/water/etc. get their own restrained hues.

## 5. Visual direction (recommended — refine as designer)

Design **dark-first**, then adapt to light. Aesthetic: **quiet, premium, data-instrument** — think the honesty of MacroFactor, the calm of Gentler Streak, the number-forward density of a good trading/analytics app, the clarity of Apple Fitness rings. Not neon "gym bro," not pastel wellness fluff.

- **Layout:** generous negative space, clear vertical rhythm, card/section grouping, comfortable tap targets (≥44 pt). Content-dense where it earns it (diary, set logging), airy where it counts (dashboard hero).
- **Color:** near-black/charcoal dark surfaces (not pure #000), soft elevated cards. **One primary accent** for today's energy-balance state. A small, consistent semantic set: **calories/energy**, **protein**, **carbs**, **fat**, **water** each get a fixed hue used everywhere (a macro is always the same color). Green/amber/red reserved for *guardrail* states (rate-of-gain in/over range), not decoration. Follow the **`dataviz` skill's palette method** for chart colors and light/dark parity — don't hand-pick chart colors ad hoc.
- **Typography:** SF Pro. Very large rounded/condensed numerals for hero stats; clear label hierarchy. Tabular figures so numbers don't jump while updating.
- **Iconography:** SF Symbols, consistent weight. Custom, simple glyphs only for drink presets / muscle groups if needed.
- **Charts (Swift Charts):** faint dots for raw data, one bold smooth **monotone** trend line (never overshooting spline). Muted gridlines. Annotations for DEXA anchors and goals. Rings/gauges for daily completion. No 3D, no gradients-as-decoration.
- **Motion:** subtle. A ring filling on log, a gentle number roll-up. Haptic tick on quick-add. Nothing bouncy.

*(Deliver a small style tile: color roles, type scale, one ring, one chart, one list row, one log sheet — so the system is legible before all screens are drawn.)*

## 6. Information architecture

**Tab bar (4 tabs) + Settings via the Today header:**

| Tab | Screen | Owns |
|---|---|---|
| **Today** | Dashboard | Energy balance, macros, water, quick-adds, today's timeline, entry to Settings |
| **Food** | Diary + library | Meal slots, add/scan/manual food, personal library, meal templates |
| **Body** | Weight & composition | Weight trend, BMI, DEXA scans, body-comp charts |
| **Train** | Workouts | Session list/history, active session, exercise catalog & history |

Water lives on **Today** (ring + quick-add) with a water-detail sheet. Settings, profile, targets, units, reminders, HealthKit, and the **energy/TDEE breakdown** are reached from the Today header (gear) and a "how is this calculated?" affordance.

---

## 7. Screens to design (v1)

For each: **purpose · key content · primary actions · states**. Design the happy path *and* the empty/permission/error states — they're most of the felt experience early on.

### 7.1 Today (Dashboard) — the hero screen
- **Purpose:** answer "where's my day?" instantly; be the fastest place to log.
- **Key content (priority order):**
  1. **Energy balance hero** — calories consumed vs target, and the **surplus/deficit** number (framed positively for a bulk: "+180 kcal · on target"). A ring or arc is natural. This is the one screen element that gets the primary accent.
  2. **Macros** — protein / carbs / fat consumed vs target (three compact bars or mini-rings; protein most prominent).
  3. **Water ring** + one-tap **quick-add chips** (preset sizes).
  4. **Expenditure snapshot** — today's TDEE = RMR + active energy (+TEF), with a subtle "estimated / from DEXA RMR" caption and a tap-through to the breakdown.
  5. **Weight trend mini** — sparkline of the trend + current trend weight and weekly rate (e.g. "−0.0 → +0.3 kg/wk").
  6. **Today's timeline** — chronological list of what's been logged (meals, water, workout), each tappable/editable.
  7. **Quick actions row** — Add food · Scan · Add water · Log weight · Start workout.
- **States:** first-run (no logs → friendly "log your first meal" with the quick actions elevated); no HealthKit auth (expenditure card shows "connect Apple Health" without blocking the rest); adaptive-TDEE "stabilizing" caption (v2-ready).

### 7.2 Food — Diary
- **Purpose:** the day's food organized by **meal slots** (Breakfast/Lunch/Dinner/Snacks, renameable).
- **Key content:** per-slot list of `FoodLogEntry` rows (name, serving×qty, kcal, small macro dots); per-slot and per-day totals vs target; a **"＋ Add"** on each slot.
- **Primary actions:** add food to a slot; **copy yesterday** / **add a saved meal template**; edit/delete an entry; **Save this slot/day as a meal template**.
- **States:** empty slot (ghost "＋ Add breakfast"); over/under target (quiet color on the day total).

### 7.3 Add Food (the highest-traffic flow — design carefully)
A sheet with three fast paths, **recents/favorites shown immediately**:
- **Search/list** the personal library (recents, favorites, all) — big fast list, favorite stars.
- **Scan barcode** (primary CTA) → camera → result.
- **Manual entry / create food**.
- On selecting a food → **Serving picker**: choose a `ServingUnit` (e.g. "1 scoop", "100 g", "1 cup") + a numeric **quantity stepper**, live-updating kcal/macros; choose meal slot; confirm.
- **States:** empty library (first run → "scan or add your first food"); scanning; **barcode found**; **not-found / offline** → slides into a pre-filled manual-entry form ("we couldn't find it — add it once and it's saved"); found-but-incomplete (pre-fill partial, ask user to complete).

### 7.4 Barcode Scanner
- **Purpose:** point-and-log packaged foods.
- **Content:** live camera with a scan reticle, guidance text, torch toggle, manual-entry escape hatch.
- **States:** requesting camera permission; permission denied (explain + button to Settings + "enter manually"); scanning; recognized (brief confirmation → serving picker); not found (→ manual).

### 7.5 Food Detail / Edit / Create
- **Purpose:** view/edit a library food; create a manual one; define serving units.
- **Content:** name, brand, source badge (**Open Food Facts** / manual), per-100g macros, list of serving units (label + grams-equivalent, add/remove), favorite toggle, "refresh from Open Food Facts" (for scanned items).
- **Note:** editing a food must **not** rewrite past diary entries (snapshotted) — reflect this subtly if surfaced.

### 7.6 Body — Weight & Composition
- **Purpose:** the trend truth of the bulk.
- **Key content:**
  1. **Weight trend chart** — faint raw weigh-in dots + bold **monotone trend line**; current **trend weight** + **weekly rate** with the guardrail band (0.25–0.5 %BW/wk = on-track). A dashed goal projection + goal RuleMark if a goal is set. A one-line "trend lags the scale by design" explainer affordance.
  2. **Log weight** (quick, prominent) — number pad, defaults to morning, unit-aware.
  3. **DEXA scans** — list of scans (date, body-fat %, lean mass, fat mass, RMR badge if authoritative); tap → **DEXA detail** (all metrics + attached report image); **Add DEXA** (enter metrics, mark RMR authoritative, attach a photo/PDF of the report).
  4. **Body-composition charts** — lean mass & fat mass over the DEXA anchors, body-fat % (point anchors + linear connectors, clearly "measured points, interpolated between").
  5. **BMI** — de-emphasized secondary line, labeled "context only — misleads for muscular users."
- **States:** no weigh-ins yet (prompt); warm-up (<~13 days → "trend still forming"); no DEXA yet (Katch-McArdle/Mifflin note on where RMR comes from).

### 7.7 Water (sheet from Today)
- **Purpose:** frictionless hydration logging.
- **Content:** big water ring vs target; **grid of quick-add preset chips** (custom sizes/icons); today's drink log list (editable); **edit presets** (label, size, icon).
- **States:** empty (default presets prompt); target met (satisfying but quiet completion).

### 7.8 Train — Workouts
- **Purpose:** replace Notes for lifting; fast set logging.
- **Screens:**
  - **History/list** — past `WorkoutSession`s (date, name, volume, key lifts); **Start workout**.
  - **Active session** — add exercises; per-exercise **set rows** with a **"Previous" column** pre-filling last time's weight×reps (tap to accept); weight + reps steppers, set-type (warmup/normal/failure) toggle, **done check**; running **session volume**; finish.
  - **Exercise detail/history** — per-exercise chart (top set / est. 1RM / volume over time), best set, PRs.
  - **Exercise catalog** — searchable list by muscle group/equipment; add custom exercise.
- **States:** first workout (empty catalog decision — either a starter catalog or "add your first exercise"); mid-set editing; finishing summary.

### 7.9 Energy / TDEE breakdown (from Today)
- **Purpose:** transparency into the number that drives everything.
- **Content:** stacked breakdown — **RMR** (with source: "DEXA-measured" / "Katch-McArdle from DEXA" / "Mifflin-St Jeor") + **active energy** (from Apple Health, with "sparse — watch not worn" caveat when 0) + **TEF** = **TDEE**; then **intake − TDEE = balance**. A quiet "how this is calculated" explainer. (v2: adaptive maintenance + DEXA reconciliation view — leave visual room.)

### 7.10 Settings & Profile
- **Purpose:** the knobs.
- **Content:** **Units** (metric ⇄ US master toggle), **Profile** (sex, birth date, height, activity level, goal = lean bulk), **Targets** (calorie surplus %, protein g/kg, view current targets & how they're derived), **RMR source preference**, **Apple Health** connection & permissions, **Reminders** (weigh-in, water), **TEF mode** (advanced), **Trend responsiveness** (advanced α).
- **States:** HealthKit connected/not; iCloud signed out (non-blocking banner).

### 7.11 Onboarding (minimal — it's a personal tool)
- 3–4 lightweight steps: welcome → **profile** (sex/height/DOB/activity/goal) → **units** → **Apple Health** permission (explain what/why, skippable) → land on Today. No account, no email, no paywall. (Exact order is open — propose one.)

---

## 8. Shared component system (design these once, reuse)

- **Energy-balance hero ring/arc** (with surplus/deficit readout).
- **Macro mini-bars / mini-rings** (protein/carb/fat, fixed hues).
- **Completion ring** (water, calories %) — reused for the future watch.
- **Stat tile** (big number + label + optional delta/caption + optional source badge).
- **Quick-add chip** (preset size, icon, tappable, haptic).
- **Trend chart** (raw dots + monotone trend line + optional band + goal projection).
- **Anchor chart** (DEXA point anchors + linear connectors + annotations).
- **Diary/log list row** (name, sub-detail, value, macro dots, swipe to edit/delete).
- **Serving picker** (unit selector + quantity stepper + live macro readout).
- **Set-log row** (previous column, weight/reps steppers, type toggle, done check).
- **Source badge** (Open Food Facts / manual / DEXA / Apple Health).
- **"Estimated/stabilizing" caption** treatment (honest uncertainty).
- **Number-pad entry sheet** (unit-aware; ft+in composite for height in US mode).

## 9. Key flows to storyboard (show the taps)

1. **Log a packaged food by barcode:** Today → Scan → recognize → serving picker → confirm → ring updates. (Design the not-found → manual detour too.)
2. **Quick-add water:** Today → tap a preset chip → ring fills + haptic (zero navigation).
3. **Log morning weight:** Today → Log weight → number pad → trend chart updates.
4. **Add a DEXA scan:** Body → Add DEXA → enter metrics + mark RMR authoritative + attach report → RMR source badge updates across the app.
5. **Log a workout:** Train → Start → add exercise → accept "Previous" → tweak reps → done → finish summary.
6. **Copy yesterday's dinner:** Food → Dinner slot → Copy yesterday → adjust.

## 10. States & edge cases (design them, don't skip)

- First-run empty states for every tab (inviting, action-forward).
- HealthKit **not authorized** (never blocks; cards degrade to "connect Apple Health").
- Barcode **not found / offline** → pre-filled manual entry.
- **iCloud signed out** → non-blocking banner (data still works locally).
- Weight-trend **warm-up** (<~2 weeks) and adaptive-TDEE **"stabilizing"** captions (v2-ready).
- Rate-of-gain **guardrail** states (on-track / a bit fast / too fast).
- Over/under macro & calorie target (quiet, non-judgmental).

## 11. Accessibility & internationalization

- **Dynamic Type** to the largest sizes (numbers and lists must reflow, not truncate).
- **VoiceOver** labels for rings/charts/gauges (e.g. "Calories: 2,140 of 2,600, 180 surplus"). Never rely on color alone — pair hue with label/shape.
- **Contrast** meets WCAG AA in both themes; test the accented/lock-screen desaturated rendering (v2 widgets) early conceptually.
- **Unit-awareness everywhere:** design number displays and entry for both metric and US, including the **ft+in composite** for height and whole-number rounding for volumes. Never show a raw unit mismatch.
- **Tabular numerals** so live-updating figures don't shift layout.

## 12. Out of scope for this v1 design pass (but keep the language extensible)

- **Apple Watch** app (v2): will reuse the **completion ring** (water %, calorie %) and quick-add chips — design those components so they scale down to a watch face/complication later.
- **Widgets / Lock Screen / Live Activities** (v2): the calorie ring and "remaining kcal + P/C/F" will become accessory widgets — keep a version of those that reads well tiny and desaturated.
- **Supplements, caffeine, body photos, insights** (v2/v3): leave IA room (e.g. Today could gain a "supplements due" card; Body could gain a photos timeline).

---

### Deliverables requested from the design pass
1. A **style tile** (color roles + type scale + core components) in dark and light.
2. **Today** (hero) in full, both themes, with 2–3 states (populated / first-run / no-HealthKit).
3. The **Add Food** flow (library → scan → serving picker → not-found→manual).
4. **Body** (weight trend + DEXA) screen.
5. **Train** active-session screen (with the "Previous" column).
6. The reusable **component sheet** from §8.
