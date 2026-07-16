import Foundation

/// Abstraction over where food nutrition comes from (Open Food Facts today; a licensed DB / backend later).
public protocol FoodSource: Sendable {
    func lookup(barcode: String) async throws -> RemoteFood?
}
