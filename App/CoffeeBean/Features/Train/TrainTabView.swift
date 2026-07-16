import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Train: cardio first, then the 5-day weight split (plan, volume, exercise cards).
/// Scoped to the shared selected day — past days backfill; future days show the plan.
struct TrainTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(DateNav.self) private var nav
    @Query(sort: \CardioSession.loggedAt) private var cardio: [CardioSession]
    @Query(sort: \WorkoutSet.loggedAt) private var allSets: [WorkoutSet]
    @Query private var plans: [DayPlan]
    @Query private var profiles: [Profile]

    @State private var showAddCardio = false
    @State private var showAddExercise = false

    private var cal: Calendar { Calendar.current }
    private var selectedDay: Date { nav.selectedDay }
    private var system: UnitSystem { profiles.first?.unitSystem ?? .metric }

    var body: some View {
        let routine = routineFor(day: selectedDay)
        let daySets = allSets.filter { cal.isDate($0.day, inSameDayAs: selectedDay) }
        let exercises = exerciseGroups(from: daySets)
        let dayVolume = daySets.reduce(0) { $0 + $1.volumeKg }

        return DatedScreenScaffold {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !nav.isFuture {
                        sectionLabel("CARDIO")
                        CardioCard(day: selectedDay, sessions: cardio,
                                   onAdd: { showAddCardio = true },
                                   onDelete: { context.delete($0) })
                    }

                    sectionLabel("WEIGHTS · 5-DAY SPLIT")
                    PlanCard(routine: routine, sessionLabel: sessionLabel(hasSets: !daySets.isEmpty),
                             onReassign: { reassign(to: $0) })

                    if nav.isFuture {
                        if routine == .rest {
                            restCard
                        } else {
                            Text("Planned — log sets on the day")
                                .font(.footnote).foregroundStyle(Theme.textSecondary)
                        }
                    } else if routine == .rest && daySets.isEmpty {
                        restCard
                    } else {
                        VolumeCard(routine: routine, todayVolumeKg: dayVolume,
                                   history: volumeHistory(routine: routine), system: system)
                        ForEach(exercises, id: \.name) { group in
                            ExerciseCard(
                                name: group.name,
                                sets: group.sets,
                                previous: previousSets(exercise: group.name),
                                system: system,
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
                context.insert(CardioSession(day: selectedDay, typeRaw: type.rawValue, minutes: minutes))
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
        if let plan = plans.first(where: { cal.isDate($0.day, inSameDayAs: day) }),
           let r = Routine(rawValue: plan.routineRaw) {
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

    private func sessionLabel(hasSets: Bool) -> String {
        if nav.isFuture { return "Planned session" }
        if hasSets { return "Logged session" }
        return nav.isToday ? "Today's session" : "No session logged"
    }

    /// Sets from the most recent day before the selected day this exercise was performed.
    private func previousSets(exercise: String) -> [WorkoutSet] {
        let earlier = allSets.filter { $0.exerciseName == exercise && $0.day < selectedDay }
        guard let lastDay = earlier.map(\.day).max() else { return [] }
        return earlier.filter { $0.day == lastDay }.sorted { $0.setIndex < $1.setIndex }
    }

    /// Volumes of earlier same-routine days (had sets), ending with the selected day. Up to 8 bars.
    private func volumeHistory(routine: Routine) -> [(date: Date, volumeKg: Double)] {
        let byDay = Dictionary(grouping: allSets.filter { $0.day < selectedDay }, by: \.day)
        let sameRoutine = byDay
            .filter { routineFor(day: $0.key) == routine }
            .map { (date: $0.key, volumeKg: $0.value.reduce(0) { $0 + $1.volumeKg }) }
            .sorted { $0.date < $1.date }
            .suffix(7)
        let dayVolume = allSets.filter { cal.isDate($0.day, inSameDayAs: selectedDay) }
            .reduce(0) { $0 + $1.volumeKg }
        return Array(sameRoutine) + [(selectedDay, dayVolume)]
    }

    // MARK: - Actions

    private func reassign(to routine: Routine) {
        if let plan = plans.first(where: { cal.isDate($0.day, inSameDayAs: selectedDay) }) {
            plan.routineRaw = routine.rawValue
        } else {
            context.insert(DayPlan(day: selectedDay, routineRaw: routine.rawValue))
        }
    }

    /// New exercise starts with one set prefilled from its previous session (else catalog default).
    private func addExercise(_ ex: CatalogExercise, order: Int) {
        let prev = previousSets(exercise: ex.name)
        let weight = prev.first?.weightKg ?? ex.defaultWeightKg
        let reps = prev.first?.reps ?? 10
        context.insert(WorkoutSet(day: selectedDay, exerciseName: ex.name, muscleGroupRaw: ex.group.rawValue,
                                  exerciseOrder: order, setIndex: 0, weightKg: weight, reps: reps))
    }

    /// "+ Add set" clones the exercise's last set.
    private func addSet(to group: ExerciseGroup) {
        guard let last = group.sets.last else { return }
        context.insert(WorkoutSet(day: selectedDay, exerciseName: last.exerciseName,
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
