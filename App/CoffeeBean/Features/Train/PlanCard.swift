import SwiftUI

/// Today's routine + chips to reassign the day.
struct PlanCard: View {
    let routine: Routine
    let hasLoggedSets: Bool
    let onReassign: (Routine) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(hasLoggedSets ? "Logged session" : "Today's session")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                Text(routine.dayTitle)
                    .font(.title3).bold().foregroundStyle(Theme.textPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Routine.allCases) { r in
                            Text(r.title)
                                .font(.subheadline)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(r == routine ? Theme.accent : Theme.card, in: Capsule())
                                .overlay(Capsule().strokeBorder(Theme.textSecondary.opacity(r == routine ? 0 : 0.25)))
                                .foregroundStyle(r == routine ? Color(hex: 0x26190A) : Theme.textPrimary)
                                .onTapGesture { onReassign(r) }
                        }
                    }
                }
            }
        }
    }
}
