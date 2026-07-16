import SwiftUI
import SwiftData

/// Add a food to a meal slot. Paths: browse the library, scan/enter a barcode
/// (Open Food Facts lookup), or create a food manually — then choose servings.
struct AddFoodSheet: View {
    enum Screen { case browse, barcode, create }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let slot: MealSlot
    let foods: [Food]
    var initialScreen: Screen = .browse
    let onLog: (Food, Double) -> Void

    @State private var screen: Screen = .browse
    @State private var query = ""
    @State private var selected: Food?
    @State private var servings: Double = 1
    @State private var addedCount = 0

    // Barcode lookup
    @State private var barcode = ""
    @State private var lookingUp = false
    @State private var lookupMessage: String?

    // Manual create
    @State private var newName = ""
    @State private var newBrand = ""
    @State private var newKcal: Double = 0
    @State private var newProtein: Double = 0
    @State private var newCarb: Double = 0
    @State private var newFat: Double = 0
    @State private var newServingLabel = "100 g"
    @State private var newServingGrams: Double = 100

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
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .onAppear {
            screen = initialScreen
            // DEBUG screenshot hook: auto-run a barcode lookup when CB_SCAN is set.
            if let code = ProcessInfo.processInfo.environment["CB_SCAN"] {
                screen = .barcode
                barcode = code
                Task { await lookup() }
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let food = selected {
            servingPicker(food)
        } else {
            switch screen {
            case .browse: browse
            case .barcode: barcodeLookup
            case .create: createForm
            }
        }
    }

    private var title: String {
        if selected != nil { return "Serving" }
        switch screen {
        case .browse: return "Add to \(slot.title)"
        case .barcode: return "Scan barcode"
        case .create: return "Create food"
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(canGoBack ? "Back" : "Close") { goBack() }
        }
        ToolbarItem(placement: .confirmationAction) { trailingAction }
    }

    @ViewBuilder private var trailingAction: some View {
        if let food = selected {
            // Log and return to the list so several items can be added in one session.
            Button("Add") {
                onLog(food, servings)
                addedCount += 1
                selected = nil
            }
            .bold()
        } else if screen == .create {
            Button("Save") { saveNewFood() }
                .bold()
                .disabled(newName.isEmpty)
        } else if screen == .browse && addedCount > 0 {
            Button("Done (\(addedCount) added)") { dismiss() }
                .bold()
        }
    }

    private var canGoBack: Bool { selected != nil || screen != .browse }
    private func goBack() {
        if selected != nil { selected = nil; lookupMessage = nil }
        else if screen != .browse { screen = .browse }
        else { dismiss() }
    }

    // MARK: Browse

    private var browse: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                actionChip("Scan barcode", "barcode.viewfinder") { screen = .barcode }
                actionChip("Create food", "square.and.pencil") { screen = .create }
            }
            .padding([.horizontal, .top])

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
                    description: Text(query.isEmpty ? "Scan or create your first food." : "No foods match “\(query)”.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { food in
                            foodRow(food)
                            Divider().overlay(Theme.textSecondary.opacity(0.1))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    /// The ＋ logs one default serving instantly; tapping the rest of the row
    /// opens the serving picker.
    private func instantAdd(_ food: Food) {
        onLog(food, 1)
        addedCount += 1
    }

    private func actionChip(_ label: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon).font(.subheadline)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }

    private func foodRow(_ food: Food) -> some View {
        HStack {
            Button { selected = food; servings = 1 } label: {
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
                    if food.sourceRaw == "openFoodFacts" {
                        Image(systemName: "barcode").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { instantAdd(food) } label: {
                Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add one \(food.servingLabel) of \(food.name)")
        }
        .padding(.vertical, 6)
    }

    // MARK: Barcode

    private var barcodeLookup: some View {
        VStack(spacing: 18) {
            Image(systemName: "barcode.viewfinder").font(.system(size: 44)).foregroundStyle(Theme.accent)
            Text("On device this scans with the camera. Here, type a barcode.")
                .font(.caption).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            TextField("e.g. 3017624010701", text: $barcode)
                .keyboardType(.numberPad).multilineTextAlignment(.center)
                .padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
            if lookingUp {
                ProgressView().tint(Theme.accent)
            } else {
                Button { Task { await lookup() } } label: {
                    Text("Look up").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).padding(.horizontal)
                .disabled(barcode.count < 6)
            }
            if let msg = lookupMessage {
                Text(msg).font(.caption).foregroundStyle(Theme.negative)
                Button("Create manually") { screen = .create }.foregroundStyle(Theme.accent)
            }
            Spacer()
        }
        .padding(.top, 28)
    }

    private func lookup() async {
        lookingUp = true
        lookupMessage = nil
        do {
            if let remote = try await OFFService.lookup(barcode: barcode) {
                let food = Food.from(remote)
                context.insert(food)
                servings = 1
                selected = food
            } else {
                lookupMessage = "Not found in Open Food Facts."
            }
        } catch {
            lookupMessage = "Lookup failed — check your connection."
        }
        lookingUp = false
    }

    // MARK: Create

    private var createForm: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $newName)
                TextField("Brand (optional)", text: $newBrand)
            }
            Section("Per 100 g") {
                numberRow("Calories", $newKcal, "kcal")
                numberRow("Protein", $newProtein, "g")
                numberRow("Carbs", $newCarb, "g")
                numberRow("Fat", $newFat, "g")
            }
            Section("Serving") {
                TextField("Label (e.g. 1 scoop)", text: $newServingLabel)
                numberRow("Grams per serving", $newServingGrams, "g")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.sheet)
    }

    private func numberRow(_ label: String, _ value: Binding<Double>, _ unit: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
            Text(unit).foregroundStyle(Theme.textSecondary)
        }
    }

    private func saveNewFood() {
        let food = Food(
            name: newName, brand: newBrand.isEmpty ? nil : newBrand,
            barcode: barcode.isEmpty ? nil : barcode,
            kcalPer100g: newKcal, proteinPer100g: newProtein, carbPer100g: newCarb, fatPer100g: newFat,
            servingLabel: newServingLabel.isEmpty ? "100 g" : newServingLabel,
            servingGrams: max(1, newServingGrams))
        context.insert(food)
        servings = 1
        selected = food
    }

    // MARK: Serving

    private func servingPicker(_ food: Food) -> some View {
        let t = food.totals(servings: servings)
        return VStack(spacing: 20) {
            Text(food.name).font(.headline).foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
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
