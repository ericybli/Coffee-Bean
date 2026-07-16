import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Water tracking: blue ring vs daily goal, one-tap preset quick-add, custom drink, day log.
struct WaterTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DrinkPreset.sortIndex) private var presets: [DrinkPreset]
    @Query(sort: \DrinkLog.timestamp, order: .reverse) private var allLogs: [DrinkLog]
    @Query private var profiles: [Profile]

    @State private var showAddDrink = false
    @State private var showEditPresets = false

    private var goalMl: Double { profiles.first?.waterGoalMl ?? 2000 }
    private var system: UnitSystem { profiles.first?.unitSystem ?? .metric }
    private var todayLogs: [DrinkLog] { allLogs.filter { Calendar.current.isDateInToday($0.timestamp) } }
    private var consumedMl: Double { todayLogs.reduce(0) { $0 + $1.volumeMl } }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScreenScaffold(title: "Water") {
            ScrollView {
                VStack(spacing: 20) {
                    WaterRing(consumedMl: consumedMl, goalMl: goalMl, system: system).padding(.top, 8)

                    Button { showEditPresets = true } label: {
                        Text("Edit presets ›").font(.footnote).foregroundStyle(Theme.textSecondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets) { preset in presetTile(preset) }
                        customTile
                    }

                    if !todayLogs.isEmpty { dayLogCard }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkSheet(system: system) { name, volume, typeRaw in
                context.insert(DrinkLog(timestamp: Date(), volumeMl: volume,
                                        drinkTypeRaw: typeRaw, name: name))
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

    private var dayLogCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today").font(.headline).foregroundStyle(Theme.textPrimary)
                ForEach(todayLogs) { log in
                    HStack {
                        Text(log.timestamp, format: .dateTime.hour().minute())
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                            .frame(width: 56, alignment: .leading)
                        Text(log.name).foregroundStyle(Theme.textPrimary)
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
        context.insert(DrinkLog(timestamp: Date(), volumeMl: preset.volumeMl,
                                drinkTypeRaw: preset.drinkTypeRaw, name: preset.label))
    }
}
