import SwiftUI
import SwiftData

/// Train: cardio first, then the 5-day weight split (plan, volume, exercise cards).
struct TrainTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardioSession.loggedAt) private var cardio: [CardioSession]
    @Query(sort: \WorkoutSet.loggedAt) private var allSets: [WorkoutSet]
    @Query private var plans: [DayPlan]

    @State private var showAddCardio = false
    @State private var showAddExercise = false

    private var cal: Calendar { Calendar.current }
    private var today: Date { cal.startOfDay(for: Date()) }

    var body: some View {
        let routine = routineFor(day: today)
        let todaySets = allSets.filter { $0.day == today }
        let exercises = exerciseGroups(from: todaySets)
        let todayVolume = todaySets.reduce(0) { $0 + $1.volumeKg }

        return ScreenScaffold(title: "Train") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("CARDIO")
                    CardioCard(sessions: cardio,
                               onAdd: { showAddCardio = true },
                               onDelete: { context.delete($0) })

                    sectionLabel("WEIGHTS · 5-DAY SPLIT")
                    PlanCard(routine: routine, hasLoggedSets: !todaySets.isEmpty,
                             onReassign: { reassign(to: $0) })

                    if routine == .rest && todaySets.isEmpty {
                        restCard
                    } else {
                        VolumeCard(routine: routine, todayVolumeKg: todayVolume,
                                   history: volumeHistory(routine: routine))
                        ForEach(exercises, id: \.name) { group in
                            ExerciseCard(
                                name: group.name,
                                sets: group.sets,
                                previous: previousSets(exercise: group.name),
                                onAddSet: { addSet(to: group) },
                                onDeleteSet: { context.delete($0) },
                                onRemoveExercise: { group.sets.forEach { context.delete($0) } })
                        }
                        Button { showAddExercise = true } label: {
                            Label("Add exercise", systemImage: "plus").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(Theme.accent)
                    }
                }
                .padding(20)
            }
            // DEBUG screenshot hook: CB_SCROLL=bottom starts the view scrolled to the end.
            .defaultScrollAnchor(ProcessInfo.processInfo.environment["CB_SCROLL"] == "bottom" ? .bottom : .top)
        }
        .sheet(isPresented: $showAddCardio) {
            AddCardioSheet { type, minutes in
                context.insert(CardioSession(day: today, typeRaw: type.rawValue, minutes: minutes))
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(routine: routine,
                             alreadyAdded: Set(exercises.map(\.name))) { ex in
                addExercise(ex, order: exercises.count)
            }
        }
    }

    // MARK: - Derivations

    private func routineFor(day: Date) -> Routine {
        if let plan = plans.first(where: { $0.day == day }), let r = Routine(rawValue: plan.routineRaw) {
            return r
        }
        return Routine.defaultFor(weekday: cal.component(.weekday, from: day))
    }

    private struct ExerciseGroup { let name: String; let sets: [WorkoutSet] }

    private func exerciseGroups(from sets: [WorkoutSet]) -> [ExerciseGroup] {
        Dictionary(grouping: sets, by: \.exerciseName)
            .map { name, sets in
                ExerciseGroup(name: name, sets: sets.sorted { $0.setIndex < $1.setIndex })
            }
            .sorted { ($0.sets.first?.exerciseOrder ?? 0) < ($1.sets.first?.exerciseOrder ?? 0) }
    }

    /// Sets from the most recent earlier day this exercise was performed ("Previous" reference).
    private func previousSets(exercise: String) -> [WorkoutSet] {
        let earlier = allSets.filter { $0.exerciseName == exercise && $0.day < today }
        guard let lastDay = earlier.map(\.day).max() else { return [] }
        return earlier.filter { $0.day == lastDay }.sorted { $0.setIndex < $1.setIndex }
    }

    /// Volumes of past same-routine days (had sets), ending with today. Up to 8 bars.
    private func volumeHistory(routine: Routine) -> [(date: Date, volumeKg: Double)] {
        let byDay = Dictionary(grouping: allSets.filter { $0.day < today }, by: \.day)
        let sameRoutine = byDay
            .filter { routineFor(day: $0.key) == routine }
            .map { (date: $0.key, volumeKg: $0.value.reduce(0) { $0 + $1.volumeKg }) }
            .sorted { $0.date < $1.date }
            .suffix(7)
        let todayVolume = allSets.filter { $0.day == today }.reduce(0) { $0 + $1.volumeKg }
        return Array(sameRoutine) + [(today, todayVolume)]
    }

    // MARK: - Actions

    private func reassign(to routine: Routine) {
        if let plan = plans.first(where: { $0.day == today }) {
            plan.routineRaw = routine.rawValue
        } else {
            context.insert(DayPlan(day: today, routineRaw: routine.rawValue))
        }
    }

    /// New exercise starts with one set prefilled from its previous session (else catalog default).
    private func addExercise(_ ex: CatalogExercise, order: Int) {
        let prev = previousSets(exercise: ex.name)
        let weight = prev.first?.weightKg ?? ex.defaultWeightKg
        let reps = prev.first?.reps ?? 10
        context.insert(WorkoutSet(day: today, exerciseName: ex.name, muscleGroupRaw: ex.group.rawValue,
                                  exerciseOrder: order, setIndex: 0, weightKg: weight, reps: reps))
    }

    /// "+ Add set" clones the exercise's last set.
    private func addSet(to group: ExerciseGroup) {
        guard let last = group.sets.last else { return }
        context.insert(WorkoutSet(day: today, exerciseName: last.exerciseName,
                                  muscleGroupRaw: last.muscleGroupRaw,
                                  exerciseOrder: last.exerciseOrder,
                                  setIndex: last.setIndex + 1,
                                  weightKg: last.weightKg, reps: last.reps))
    }

    private var restCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(Theme.textSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            .frame(height: 90)
            .overlay {
                VStack(spacing: 4) {
                    Text("Rest day").font(.headline).foregroundStyle(Theme.textSecondary)
                    Text("Pick a routine above to train anyway").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).bold().foregroundStyle(Theme.textSecondary).kerning(1)
    }
}
