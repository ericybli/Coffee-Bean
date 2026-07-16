import Foundation

public enum Sex: String, Codable, Sendable { case male, female }

public struct Biometrics: Equatable, Sendable {
    public let weightKg: Double
    public let heightCm: Double
    public let ageYears: Int
    public let sex: Sex
    public let bodyFatFraction: Double?   // 0...1, from DEXA
    public let leanMassKg: Double?        // from DEXA (drives Katch-McArdle)

    public init(weightKg: Double, heightCm: Double, ageYears: Int, sex: Sex,
                bodyFatFraction: Double?, leanMassKg: Double?) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.sex = sex
        self.bodyFatFraction = bodyFatFraction
        self.leanMassKg = leanMassKg
    }
}
