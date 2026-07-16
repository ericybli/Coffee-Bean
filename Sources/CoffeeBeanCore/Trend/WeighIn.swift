import Foundation

public struct WeighIn: Equatable, Sendable {
    public let date: Date
    public let massKg: Double
    public init(date: Date, massKg: Double) {
        self.date = date
        self.massKg = massKg
    }
}

public struct TrendPoint: Equatable, Sendable {
    public let date: Date
    public let rawAverage: Double?   // nil if no weigh-in that day
    public let trend: Double
    public init(date: Date, rawAverage: Double?, trend: Double) {
        self.date = date
        self.rawAverage = rawAverage
        self.trend = trend
    }
}
