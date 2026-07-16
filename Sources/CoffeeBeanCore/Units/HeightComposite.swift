import Foundation

public struct FeetInches: Equatable, Sendable {
    public let feet: Int
    public let inches: Int
    public init(feet: Int, inches: Int) {
        self.feet = feet
        self.inches = inches
    }
}
