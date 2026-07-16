import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Body composition: weight trend (raw + smoothed), DEXA scans, BMI.
struct BodyTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \WaistEntry.date) private var waists: [WaistEntry]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query private var profiles: [Profile]

    @State private var range: ChartRange = .month
    @State private var showLogWeight = false
    @State private var showLogWaist = false
    @State private var showAddDEXA = false

    private var heightCm: Double? { profiles.first?.heightCm }
    private var system: UnitSystem { profiles.first?.unitSystem ?? .metric }
    private var metrics: BodyMetrics { BodyMetrics(weights: weights, heightCm: heightCm) }
    private var shownPoints: [TrendPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? .distantPast
        let window = metrics.trend.filter { $0.date >= cutoff }
        guard system == .imperial else { return window }
        // Convert for display; canonical stays kg.
        return window.map {
            TrendPoint(date: $0.date,
                       rawAverage: $0.rawAverage.map { Units.massValue($0, .imperial) },
                       trend: Units.massValue($0.trend, .imperial))
        }
    }

    /// Waist smoothed with the same engine (values are cm instead of kg).
    private var waistTrend: [TrendPoint] {
        let engine = TrendEngine(alpha: 0.28)
        return engine.trend(from: waists.map { WeighIn(date: $0.date, massKg: $0.waistCm) })
    }
    private var shownWaistPoints: [TrendPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? .distantPast
        let window = waistTrend.filter { $0.date >= cutoff }
        guard system == .imperial else { return window }
        return window.map {
            TrendPoint(date: $0.date,
                       rawAverage: $0.rawAverage.map { Units.lengthValue($0, .imperial) },
                       trend: Units.lengthValue($0.trend, .imperial))
        }
    }

    var body: some View {
        ScreenScaffold(title: "Body") {
            ScrollView {
                VStack(spacing: 16) {
                    weightCard
                    waistCard
                    dexaCard
                    if let bmi = metrics.bmi {
                        Text(String(format: "BMI %.1f · context only — misleads for muscular users", bmi))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showLogWeight) {
            LogWeightSheet(initialKg: metrics.currentTrendKg ?? 72, system: system) { kg in
                context.insert(WeightEntry(date: Date(), massKg: kg))
            }
        }
        .sheet(isPresented: $showLogWaist) {
            LogWaistSheet(initialCm: waistTrend.last?.trend ?? 82, system: system) { cm in
                context.insert(WaistEntry(date: Date(), waistCm: cm))
            }
        }
        .sheet(isPresented: $showAddDEXA) {
            AddDEXASheet { scan in addDEXA(scan) }
        }
    }

    // MARK: - Cards

    private var weightCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trend weight").font(.subheadline).foregroundStyle(Theme.textSecondary)
                        Text(currentWeightText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    weeklyRateView
                }
                Picker("Range", selection: $range) {
                    ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if shownPoints.count >= 2 {
                    WeightTrendChart(points: shownPoints)
                    Text("trend lags the scale by design")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                } else {
                    Text("Log a few days to see your trend")
                        .font(.footnote).foregroundStyle(Theme.textSecondary)
                        .frame(height: 120)
                }

                Button { showLogWeight = true } label: {
                    Label("Log weight", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
        }
    }

    @ViewBuilder private var weeklyRateView: some View {
        if let rate = metrics.weeklyRateKg {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Weekly rate").font(.caption).foregroundStyle(Theme.textSecondary)
                Text(String(format: "%+.2f %@/wk", Units.massValue(rate, system),
                            system == .metric ? "kg" : "lb"))
                    .font(.headline).monospacedDigit().foregroundStyle(rateColor(rate))
            }
        }
    }

    private var waistCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Waist").font(.subheadline).foregroundStyle(Theme.textSecondary)
                        Text(currentWaistText)
                            .font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    waistDeltaView
                }
                if shownWaistPoints.count >= 2 {
                    WeightTrendChart(points: shownWaistPoints, color: Theme.protein, height: 130)
                } else {
                    Text("Log a few measurements to see your trend")
                        .font(.footnote).foregroundStyle(Theme.textSecondary)
                        .frame(height: 80)
                }
                Button { showLogWaist = true } label: {
                    Label("Log waist", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.protein)
            }
        }
    }

    @ViewBuilder private var waistDeltaView: some View {
        let trend = waistTrend
        if let current = trend.last?.trend, trend.count >= 8 {
            let weekAgo = trend[trend.count - 8].trend
            let deltaCm = current - weekAgo
            VStack(alignment: .trailing, spacing: 2) {
                Text("vs last week").font(.caption).foregroundStyle(Theme.textSecondary)
                Text(String(format: "%+.1f %@", Units.lengthValue(deltaCm, system),
                            system == .metric ? "cm" : "in"))
                    .font(.headline).monospacedDigit()
                    .foregroundStyle(deltaCm <= 0 ? Theme.positive : Theme.negative)
            }
        }
    }

    private var currentWaistText: String {
        guard let cm = waistTrend.last?.trend else { return "—" }
        return Units.length(cm, system)
    }

    private var dexaCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("DEXA Scans").font(.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button { showAddDEXA = true } label: { Label("Add", systemImage: "plus") }
                        .tint(Theme.accent)
                }
                if scans.isEmpty {
                    Text("No scans yet").font(.footnote).foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(scans) { scan in dexaRow(scan) }
                }
            }
        }
    }

    private func dexaRow(_ scan: BodyScan) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(scan.date, format: .dateTime.year().month().day())
                    .font(.subheadline).foregroundStyle(Theme.textPrimary)
                Text(dexaSummary(scan)).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if scan.isRMRAuthoritative {
                Text("RMR source").font(.caption2).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.2), in: Capsule())
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var currentWeightText: String {
        guard let kg = metrics.currentTrendKg else { return "—" }
        return Units.mass(kg, system)
    }

    private func rateColor(_ rate: Double) -> Color {
        guard let cur = metrics.currentTrendKg, cur > 0, rate > 0 else { return Theme.textSecondary }
        switch RateOfGain.classify(weeklyRatePercentBW: rate / cur * 100) {
        case .onTrack: return Theme.positive
        case .slightlyFast: return Theme.carbs
        case .tooFast: return Theme.negative
        }
    }

    private func dexaSummary(_ scan: BodyScan) -> String {
        var parts: [String] = []
        if let bf = scan.bodyFatFraction { parts.append(String(format: "Body fat %.1f%%", bf * 100)) }
        if let lean = scan.leanMassKg { parts.append("Lean \(Units.mass(lean, system))") }
        if let rmr = scan.rmrKcal { parts.append(String(format: "RMR %.0f", rmr)) }
        return parts.joined(separator: " · ")
    }

    private func addDEXA(_ scan: BodyScan) {
        if scan.isRMRAuthoritative {
            for s in scans { s.isRMRAuthoritative = false }
        }
        context.insert(scan)
    }
}
