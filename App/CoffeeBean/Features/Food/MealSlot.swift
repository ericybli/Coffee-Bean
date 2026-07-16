import Foundation

/// The five diary meal slots.
enum MealSlot: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks, extra

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        case .extra: return "Extra"
        }
    }
}
