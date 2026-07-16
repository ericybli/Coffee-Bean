import SwiftUI

/// Add a food to a meal slot: pick from the library (favorites/recents first), then choose servings.
struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    let slot: MealSlot
    let foods: [Food]
    let onLog: (Food, Double) -> Void

    @State private var query = ""
    @State private var selected: Food?
    @State private var servings: Double = 1

    private var filtered: [Food] {
        let base = foods.sorted {
            ($0.isFavorite ? 1 : 0, $0.lastUsedAt) > ($1.isFavorite ? 1 : 0, $1.lastUsedAt)
        }
        guard !query.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                if let food = selected { servingPicker(food) } else { list }
            }
            .navigationTitle(selected == nil ? "Add to \(slot.title)" : "Serving")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selected == nil ? "Close" : "Back") {
                        if selected == nil { dismiss() } else { selected = nil }
                    }
                }
                if let food = selected {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { onLog(food, servings); dismiss() }.bold()
                    }
                }
            }
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                TextField("Search foods", text: $query).foregroundStyle(Theme.textPrimary)
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .padding()

            if filtered.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "No foods yet" : "No results",
                    systemImage: "magnifyingglass",
                    description: Text(query.isEmpty ? "Your library is empty." : "No foods match “\(query)”.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { food in
                            Button { selected = food; servings = 1 } label: { foodRow(food) }
                                .buttonStyle(.plain)
                            Divider().overlay(Theme.textSecondary.opacity(0.1))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func foodRow(_ food: Food) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name).foregroundStyle(Theme.textPrimary)
                Text("\(food.servingLabel) · \(food.totals(servings: 1).kcal.grouped) cal")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if food.isFavorite {
                Image(systemName: "star.fill").font(.caption2).foregroundStyle(Theme.accent)
            }
            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 10)
    }

    private func servingPicker(_ food: Food) -> some View {
        let t = food.totals(servings: servings)
        return VStack(spacing: 20) {
            Text(food.name).font(.headline).foregroundStyle(Theme.textPrimary)
            Text("\(t.kcal.grouped) cal")
                .font(.system(size: 40, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(Theme.accent)
            Text("P \(Int(t.protein))g · C \(Int(t.carb))g · F \(Int(t.fat))g")
                .font(.caption).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 24) {
                stepButton("minus", "Decrease servings") { servings = max(0.5, servings - 0.5) }
                VStack(spacing: 2) {
                    Text(servingsText).font(.title3).bold().foregroundStyle(Theme.textPrimary)
                    Text("× \(food.servingLabel)").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                .frame(minWidth: 90)
                stepButton("plus", "Increase servings") { servings = min(20, servings + 0.5) }
            }
        }
        .padding()
    }

    private var servingsText: String {
        servings == servings.rounded() ? String(Int(servings)) : String(format: "%.1f", servings)
    }

    private func stepButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title2).frame(width: 54, height: 54)
                .background(Theme.card, in: Circle()).foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel(label)
    }
}
