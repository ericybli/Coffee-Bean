import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Water tracking: blue ring vs daily goal, one-tap preset quick-add, custom drink, day log.
/// Scoped to the shared selected day — past days backfill, future days read-only.
struct WaterTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(DateNav.self) private var nav
    @Query(sort: \DrinkPreset.sortIndex) private var presets: [DrinkPreset]
    @Query(sort: \DrinkLog.timestamp, order: .reverse) private var allLogs: [DrinkLog]
    @Query private var profiles: [Profile]

    @State private var showAddDrink = false
    @State private var showEditPresets = false

    private var goalMl: Double { profiles.first?.waterGoalMl ?? 2000 }
    private var system: UnitSystem { profiles.first?.unitSystem ?? .metric }
    private var dayLogs: [DrinkLog] {
        allLogs.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: nav.selectedDay) }
    }
    private var consumedMl: Double { dayLogs.reduce(0) { $0 + $1.volumeMl } }
    private var dayCaffeineMg: Double { dayLogs.reduce(0) { $0 + ($1.caffeineMg ?? 0) } }
    /// FDA guideline for healthy adults.
    private let caffeineLimitMg = 400.0
    /// Timestamp for a log on the selected day (now for today, noon for backfilled days).
    private var logTimestamp: Date {
        nav.isToday
            ? Date()
            : Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: nav.selectedDay) ?? nav.selectedDay
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        DatedScreenScaffold {
            ScrollView {
                VStack(spacing: 20) {
                    WaterRing(consumedMl: consumedMl, goalMl: goalMl, system: system).padding(.top, 8)

                    Button { showEditPresets = true } label: {
                        Text("Edit presets ›").font(.footnote).foregroundStyle(Theme.textSecondary)
                    }

                    if nav.isFuture {
                        Text("Future day — nothing logged yet")
                            .font(.footnote).foregroundStyle(Theme.textSecondary)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(presets) { preset in presetTile(preset) }
                            customTile
                        }
                    }

                    if dayCaffeineMg > 0 { caffeineCard }
                    if !dayLogs.isEmpty { dayLogCard }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkSheet(system: system) { name, volume, typeRaw, caffeine in
                context.insert(DrinkLog(timestamp: logTimestamp, volumeMl: volume,
                                        drinkTypeRaw: typeRaw, name: name,
                                        caffeineMg: caffeine > 0 ? caffeine : nil))
            }
        }
        .sheet(isPresented: $showEditPresets) { EditPresetsSheet(presets: presets, system: system) }
    }

    // MARK: - Tiles

    private func presetTile(_ preset: DrinkPreset) -> some View {
        Button { addFromPreset(preset) } label: {
            VStack(spacing: 6) {
                Image(systemName: preset.iconName).font(.title2)
                Text(preset.label).font(.subheadline).bold()
                Text(Units.volume(preset.volumeMl, system)).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(Theme.water.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(Theme.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var customTile: some View {
        Button { showAddDrink = true } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus").font(.title2)
                Text("Custom").font(.subheadline).bold()
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.textSecondary.opacity(0.4),
                                  style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
            .foregroundStyle(Theme.textSecondary)
        }
        .buttonStyle(.plain)
    }

    /// Daily caffeine vs the FDA 400 mg guideline; only appears once caffeine is logged.
    private var caffeineCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Caffeine").font(.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(dayCaffeineMg.grouped) / \(caffeineLimitMg.grouped) mg")
                        .font(.subheadline).monospacedDigit().foregroundStyle(Theme.textSecondary)
                }
                ProgressBar(fraction: dayCaffeineMg / caffeineLimitMg,
                            color: dayCaffeineMg > caffeineLimitMg ? Theme.negative : Theme.accent)
                Text(dayCaffeineMg > caffeineLimitMg
                     ? "Over the FDA 400 mg/day guideline"
                     : "FDA guideline: up to 400 mg/day")
                    .font(.caption).foregroundStyle(
                        dayCaffeineMg > caffeineLimitMg ? Theme.negative : Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var dayLogCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(nav.title).font(.headline).foregroundStyle(Theme.textPrimary)
                ForEach(dayLogs) { log in
                    HStack {
                        Text(log.timestamp, format: .dateTime.hour().minute())
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                            .frame(width: 56, alignment: .leading)
                        Text(log.name).foregroundStyle(Theme.textPrimary)
                        if let mg = log.caffeineMg, mg > 0 {
                            Text("\(Int(mg)) mg")
                                .font(.caption2).monospacedDigit()
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(Theme.accent)
                        }
                        Spacer()
                        Text(Units.volume(log.volumeMl, system)).monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                        Button { context.delete(log) } label: {
                            Image(systemName: "xmark").font(.caption)
                        }
                        .foregroundStyle(Theme.negative)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addFromPreset(_ preset: DrinkPreset) {
        context.insert(DrinkLog(timestamp: logTimestamp, volumeMl: preset.volumeMl,
                                drinkTypeRaw: preset.drinkTypeRaw, name: preset.label,
                                caffeineMg: preset.caffeineMg > 0 ? preset.caffeineMg : nil))
    }
}
