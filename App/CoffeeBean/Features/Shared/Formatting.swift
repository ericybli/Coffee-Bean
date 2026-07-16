import Foundation

extension Double {
    /// Grouped integer string, e.g. 2140 -> "2,140" (locale-aware).
    var grouped: String { formatted(.number.precision(.fractionLength(0))) }
}
