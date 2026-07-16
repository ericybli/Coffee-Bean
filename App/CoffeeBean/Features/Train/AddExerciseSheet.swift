import SwiftUI

/// Pick an exercise from the catalog (grouped by muscle group, today's routine first).
struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let routine: Routine
    let alreadyAdded: Set<String>
    let onPick: (CatalogExercise) -> Void

    private var groups: [Routine] {
        let others = Routine.allCases.filter { $0 != .rest && $0 != routine }
        return routine == .rest ? others : [routine] + others
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.self) { group in
                    Section(group.title) {
                        ForEach(group.defaultExercises) { ex in
                            Button {
                                onPick(ex)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(ex.name).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    if alreadyAdded.contains(ex.name) {
                                        Image(systemName: "checkmark").font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    } else {
                                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                            .disabled(alreadyAdded.contains(ex.name))
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.sheet)
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }
}
