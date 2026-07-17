import SwiftUI

/// Five expandable meal slots with per-entry delete and a per-slot add button.
struct MealDiaryCard: View {
    let entriesBySlot: [MealSlot: [FoodLogEntry]]
    var allowAdd: Bool = true
    let onAdd: (MealSlot) -> Void
    let onDelete: (FoodLogEntry) -> Void

    @State private var expanded: Set<MealSlot> = []

    var body: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(Array(MealSlot.allCases.enumerated()), id: \.element) { idx, slot in
                    slotRow(slot)
                    if expanded.contains(slot) {
                        ForEach(entriesBySlot[slot] ?? []) { entry in entryRow(entry) }
                    }
                    if idx < MealSlot.allCases.count - 1 {
                        Divider().overlay(Theme.textSecondary.opacity(0.1))
                    }
                }
            }
        }
    }

    private func slotRow(_ slot: MealSlot) -> some View {
        let entries = entriesBySlot[slot] ?? []
        let kcal = entries.reduce(0) { $0 + $1.kcal }
        return HStack {
            Button {
                if expanded.contains(slot) { expanded.remove(slot) } else { expanded.insert(slot) }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.title).font(.subheadline).bold()
                            .foregroundStyle(entries.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                        Text(entries.isEmpty ? "Nothing logged yet" : entries.map(\.foodName).joined(separator: ", "))
                            .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                    Spacer()
                    if !entries.isEmpty {
                        Text("\(kcal.grouped) cal").font(.caption).monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                        Image(systemName: expanded.contains(slot) ? "chevron.up" : "chevron.down")
                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if allowAdd {
                Button { onAdd(slot) } label: {
                    Image(systemName: "plus").font(.subheadline).foregroundStyle(Theme.accent)
                        .frame(width: 30, height: 30)
                        .background(Theme.accent.opacity(0.15), in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add food to \(slot.title)")
            }
        }
        .padding(.vertical, 6)
    }

    private func entryRow(_ entry: FoodLogEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.foodName).font(.caption).foregroundStyle(Theme.textPrimary)
                Text(servingText(entry)).font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(entry.kcal.grouped) cal").font(.caption2).monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
            Button { onDelete(entry) } label: {
                Image(systemName: "xmark").font(.caption2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(Theme.negative)
            .accessibilityLabel("Delete \(entry.foodName)")
        }
        .padding(.leading, 12)
    }

    private func servingText(_ e: FoodLogEntry) -> String {
        // Quick-add entries have no library food; their label is the whole story.
        guard e.foodID != nil else { return e.servingLabel }
        let q = e.quantity == e.quantity.rounded() ? String(Int(e.quantity)) : String(format: "%.1f", e.quantity)
        return "\(q) × \(e.servingLabel)"
    }
}
