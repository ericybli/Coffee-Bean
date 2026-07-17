import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Add a food to a meal slot, MyFitnessPal-style: history up front, one search
/// box that covers the library AND Open Food Facts as you type, per-row instant
/// add, a serving screen with servings⇄grams, plus barcode / quick add / create.
struct AddFoodSheet: View {
    enum Screen { case browse, barcode, create, quickAdd }
    enum ServingUnit: String, CaseIterable { case servings = "Servings", grams = "Grams" }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let slot: MealSlot
    let foods: [Food]
    var initialScreen: Screen = .browse
    var usdaApiKey: String = ""
    let onLog: (Food, Double) -> Void
    /// Quick add without a library food: (kcal, protein g, carb g, fat g).
    let onQuickAdd: (Double, Double, Double, Double) -> Void

    @State private var screen: Screen = .browse
    @State private var query = ""
    @State private var selected: Food?
    @State private var servings: Double = 1
    @State private var servingUnit: ServingUnit = .servings
    @State private var grams: Double = 100
    @State private var addedCount = 0

    // Quick add
    @State private var quickKcal: Double = 0
    @State private var quickProtein: Double = 0
    @State private var quickCarb: Double = 0
    @State private var quickFat: Double = 0

    // Barcode lookup
    @State private var barcode = ""
    @State private var lookingUp = false
    @State private var lookupMessage: String?

    // Online name search: USDA (generic foods) + Open Food Facts (packaged),
    // queried in parallel; nil results = that source failed or hasn't run.
    @State private var usdaResults: [RemoteFood]?
    @State private var offResults: [RemoteFood]?
    @State private var searchingRemote = false
    @State private var searchedOnce = false

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
            // DEBUG screenshot hooks: CB_SCAN auto-runs a barcode lookup,
            // CB_SEARCH types a query (debounced auto-search takes it from there).
            if let code = ProcessInfo.processInfo.environment["CB_SCAN"] {
                screen = .barcode
                barcode = code
                Task { await lookup() }
            } else if let q = ProcessInfo.processInfo.environment["CB_SEARCH"] {
                query = q
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
            case .quickAdd: quickAddForm
            }
        }
    }

    private var title: String {
        if selected != nil { return "Serving" }
        switch screen {
        case .browse: return "Add to \(slot.title)"
        case .barcode: return "Scan barcode"
        case .create: return "Create food"
        case .quickAdd: return "Quick add"
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
                onLog(food, servingsEquivalent(food))
                addedCount += 1
                selected = nil
            }
            .bold()
        } else if screen == .create {
            Button("Save") { saveNewFood() }
                .bold()
                .disabled(newName.isEmpty)
        } else if screen == .quickAdd {
            Button("Add") {
                onQuickAdd(quickKcal, quickProtein, quickCarb, quickFat)
                dismiss()
            }
            .bold()
            .disabled(quickKcal <= 0)
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
            HStack(spacing: 10) {
                actionChip("Scan", "barcode.viewfinder") { screen = .barcode }
                actionChip("Quick add", "bolt.fill") { screen = .quickAdd }
                actionChip("Create", "square.and.pencil") { screen = .create }
            }
            .padding([.horizontal, .top])

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                TextField("Search library & Open Food Facts", text: $query)
                    .foregroundStyle(Theme.textPrimary)
                    .submitLabel(.search)
                    .onSubmit { Task { await searchOnline() } }
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .padding()
            .onChange(of: query) {
                usdaResults = nil
                offResults = nil
                searchedOnce = false
            }

            if filtered.isEmpty && query.isEmpty {
                ContentUnavailableView(
                    "No foods yet", systemImage: "magnifyingglass",
                    description: Text("Scan, search, quick add, or create your first food.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !filtered.isEmpty {
                            sectionHeader(query.isEmpty ? "HISTORY" : "MY FOODS")
                        }
                        ForEach(filtered) { food in
                            foodRow(food)
                            Divider().overlay(Theme.textSecondary.opacity(0.1))
                        }
                        if !query.isEmpty { onlineSection }
                    }
                    .padding(.horizontal)
                }
            }
        }
        // Debounced search-as-you-type: each keystroke restarts the task; only a
        // 500 ms pause lets it reach the network. Cancellation aborts the request.
        .task(id: query) {
            guard query.trimmingCharacters(in: .whitespaces).count >= 3 else { return }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await searchOnline()
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text).font(.caption2).bold().foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10).padding(.bottom, 4)
    }

    // MARK: Online name search

    /// USDA generic foods first (the user's usual unlabeled meals), then Open
    /// Food Facts packaged products — both filled in as the query settles.
    @ViewBuilder private var onlineSection: some View {
        HStack {
            Text("ONLINE").font(.caption2).bold().foregroundStyle(Theme.textSecondary)
            Spacer()
            if searchingRemote { ProgressView().tint(Theme.accent).controlSize(.small) }
        }
        .padding(.top, 14).padding(.bottom, 4)

        if !searchingRemote && !searchedOnce {
            Text(query.trimmingCharacters(in: .whitespaces).count >= 3
                 ? "Searching as you type…" : "Keep typing to search online…")
                .font(.caption).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else if searchedOnce {
            resultsBlock("GENERIC (USDA)", usdaResults)
            resultsBlock("PACKAGED (OPEN FOOD FACTS)", offResults)
            if usdaResults == nil && offResults == nil {
                Text("Online search failed — try again in a moment.")
                    .font(.caption).foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else if (usdaResults ?? []).isEmpty && (offResults ?? []).isEmpty {
                Text("No online matches. Try another name, or create it manually.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
    }

    /// One source's results; hidden when the source failed or matched nothing.
    @ViewBuilder private func resultsBlock(_ label: String, _ results: [RemoteFood]?) -> some View {
        if let results, !results.isEmpty {
            sectionHeader(label)
            ForEach(Array(results.enumerated()), id: \.offset) { _, r in
                remoteRow(r)
                Divider().overlay(Theme.textSecondary.opacity(0.1))
            }
        }
    }

    private func remoteRow(_ r: RemoteFood) -> some View {
        Button { selectRemote(r) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.name).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Text([r.brand, "\(r.kcalPer100g.grouped) cal / 100 g"]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "square.and.arrow.down").font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(r.name) to library")
    }

    private func searchOnline() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return }
        searchingRemote = true
        // Both sources in parallel; a failed source stays nil and its section hides.
        async let usda = try? USDAService.search(query: q, apiKey: usdaApiKey)
        async let off = try? OFFService.search(query: q)
        let (u, o) = await (usda, off)
        // Only apply if the query hasn't moved on while we were fetching.
        if q == query.trimmingCharacters(in: .whitespaces), !Task.isCancelled {
            usdaResults = u
            offResults = o
            searchedOnce = true
        }
        searchingRemote = false
    }

    /// Save an online result into the library (reusing any food already saved
    /// with the same barcode) and go straight to the serving picker.
    private func selectRemote(_ r: RemoteFood) {
        if let code = r.barcode, let existing = foods.first(where: { $0.barcode == code }) {
            select(existing)
        } else {
            let food = Food.from(r)
            context.insert(food)
            select(food)
        }
    }

    /// Open the serving screen for a food with fresh quantity state.
    private func select(_ food: Food) {
        servings = 1
        servingUnit = .servings
        grams = food.servingGrams
        selected = food
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
            Button { select(food) } label: {
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
        // Long-press to manage the library. Deleting a food keeps past log
        // entries intact — they carry their own name and nutrition copies.
        .contextMenu {
            Button {
                food.isFavorite.toggle()
            } label: {
                Label(food.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: food.isFavorite ? "star.slash" : "star")
            }
            Button(role: .destructive) {
                context.delete(food)
            } label: {
                Label("Delete from library", systemImage: "trash")
            }
        }
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
                select(food)
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
        select(food)
    }

    // MARK: Serving

    /// Servings of `food` represented by the current quantity state, whichever
    /// unit is active. This is the one number the log path consumes.
    private func servingsEquivalent(_ food: Food) -> Double {
        servingUnit == .grams ? grams / max(1, food.servingGrams) : servings
    }

    private func servingPicker(_ food: Food) -> some View {
        let t = food.totals(servings: servingsEquivalent(food))
        return VStack(spacing: 20) {
            Text(food.name).font(.headline).foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("\(t.kcal.grouped) cal")
                .font(.system(size: 40, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(Theme.accent)
            Text("P \(Int(t.protein))g · C \(Int(t.carb))g · F \(Int(t.fat))g")
                .font(.caption).foregroundStyle(Theme.textSecondary)

            Picker("Unit", selection: $servingUnit) {
                ForEach(ServingUnit.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            .onChange(of: servingUnit) {
                // Carry the amount across so switching units never changes the meal.
                if servingUnit == .grams { grams = servings * food.servingGrams }
                else { servings = grams / max(1, food.servingGrams) }
            }

            HStack(spacing: 24) {
                stepButton("minus", "Decrease amount") {
                    if servingUnit == .grams { grams = max(5, grams - 10) }
                    else { servings = max(0.5, servings - 0.5) }
                }
                VStack(spacing: 2) {
                    TextField("0", value: servingUnit == .grams ? $grams : $servings, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title3).bold().foregroundStyle(Theme.textPrimary)
                        .frame(width: 90)
                        .padding(.vertical, 6)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    Text(servingUnit == .grams ? "grams" : "× \(food.servingLabel)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                .frame(minWidth: 90)
                stepButton("plus", "Increase amount") {
                    if servingUnit == .grams { grams = min(2000, grams + 10) }
                    else { servings = min(20, servings + 0.5) }
                }
            }
        }
        .padding()
    }

    // MARK: Quick add

    /// MFP-style quick add: log calories (and optionally macros) with no library food.
    private var quickAddForm: some View {
        Form {
            Section("Calories") {
                numberRow("Calories", $quickKcal, "kcal")
            }
            Section("Macros (optional)") {
                numberRow("Protein", $quickProtein, "g")
                numberRow("Carbs", $quickCarb, "g")
                numberRow("Fat", $quickFat, "g")
            }
            Section {
                Text("Logs straight to \(slot.title) — no library food is created.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.sheet)
    }

    private func stepButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title2).frame(width: 54, height: 54)
                .background(Theme.card, in: Circle()).foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel(label)
    }
}
