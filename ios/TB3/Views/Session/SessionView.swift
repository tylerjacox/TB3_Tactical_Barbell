// TB3 iOS — Session View (full-screen workout)

import SwiftUI

struct SessionView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) var dismiss
    @Bindable var vm: SessionViewModel

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Top bar
                topBar

                if let exercise = vm.currentExercise {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Exercise info
                            exerciseInfo(exercise)

                            // Set dots
                            SetDotIndicators(sets: vm.currentSets)

                            // Plates
                            PlateDisplayView(plates: exercise.plates, isBodyweight: exercise.isBodyweight)

                            // Timer
                            if vm.timerPhase != nil {
                                TimerDisplayView(
                                    elapsed: vm.timerElapsed,
                                    phase: vm.timerPhase,
                                    isOvertime: vm.isOvertime
                                )
                            }
                        }
                        .padding()
                    }

                    Spacer()

                    // Exercise pager dots
                    if let session = vm.session {
                        ExerciseDotIndicators(
                            exercises: session.exercises,
                            sets: session.sets,
                            currentIndex: session.currentExerciseIndex,
                            onSelect: { vm.goToExercise($0) }
                        )
                        .padding(.bottom, 8)
                    }

                    // Undo toast
                    if let undoSetNum = vm.undoSetNumber {
                        undoToast(setNumber: undoSetNum)
                    }

                    // Main action button
                    mainButton
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
            }

            // Navigation chevrons
            navigationChevrons
        }
        .background(Color.tb3Background)
        .confirmDialog(isPresented: $vm.showEndConfirm, config: ConfirmDialogConfig(
            title: "End Workout?",
            message: "Your progress will be saved to history.",
            confirmLabel: "End Workout",
            isDanger: true,
            onConfirm: { vm.endWorkoutEarly() }
        ))
        // 250ms timer tick via TimelineView
        .overlay {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                Color.clear
                    .onChange(of: context.date) { _, _ in
                        vm.timerTick()
                    }
            }
            .frame(width: 0, height: 0)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if let session = vm.session {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Week \(session.week) \u{2022} Session \(session.session)")
                        .font(.caption)
                        .foregroundStyle(Color.tb3Muted)
                }
            }

            Spacer()

            Menu {
                if vm.timerPhase == .exercise {
                    Button("Stop Timer") { vm.stopTimer() }
                }
                Button("End Workout", role: .destructive) {
                    vm.showEndConfirm = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding()
    }

    // MARK: - Exercise Info

    private func exerciseInfo(_ exercise: ActiveSessionExercise) -> some View {
        VStack(spacing: 8) {
            Text(LiftName(rawValue: exercise.liftName)?.displayName ?? exercise.liftName)
                .font(.title.bold())

            if exercise.targetWeight > 0 {
                Text("\(Int(exercise.targetWeight)) lb")
                    .font(.title2.monospaced())
                    .foregroundColor(.tb3Accent)
            } else if exercise.isBodyweight {
                Text("Bodyweight")
                    .font(.title2)
                    .foregroundStyle(Color.tb3Muted)
            }

            // Reps info
            let repsStr: String = {
                switch exercise.repsPerSet {
                case .single(let r): return "\(r) reps"
                case .array(let arr): return arr.map(String.init).joined(separator: ", ") + " reps"
                }
            }()
            Text(repsStr)
                .font(.subheadline)
                .foregroundStyle(Color.tb3Muted)
        }
    }

    // MARK: - Main Button

    private var mainButton: some View {
        Group {
            if vm.timerPhase == .rest {
                // Rest phase: "Begin Set X"
                Button {
                    vm.completeSet()
                } label: {
                    Text("Begin Set \(vm.nextSetNumber)")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.beginSetGreen)
                .controlSize(.large)
            } else if vm.allSetsComplete {
                // All sets done
                Button {} label: {
                    Text("All Sets Done")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)
            } else {
                // Exercise phase or no timer: "Complete Set X / Y"
                Button {
                    vm.completeSet()
                } label: {
                    Text("Complete Set \(vm.nextSetNumber) / \(vm.currentSets.count)")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.completeSetOrange)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Undo Toast

    private func undoToast(setNumber: Int) -> some View {
        HStack {
            Text("Set \(setNumber) complete")
                .font(.subheadline)
            Spacer()
            Button("Undo") {
                vm.handleUndo()
            }
            .font(.subheadline.bold())
        }
        .padding()
        .background(Color.tb3Card)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tb3Border, lineWidth: 1))
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Navigation Chevrons

    private var navigationChevrons: some View {
        HStack {
            if let session = vm.session, session.currentExerciseIndex > 0 {
                Button {
                    vm.goToExercise(session.currentExerciseIndex - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(Color.tb3Muted)
                        .padding(12)
                }
                .accessibilityLabel("Previous exercise")
            }

            Spacer()

            if let session = vm.session, session.currentExerciseIndex < session.exercises.count - 1 {
                Button {
                    vm.goToExercise(session.currentExerciseIndex + 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundStyle(Color.tb3Muted)
                        .padding(12)
                }
                .accessibilityLabel("Next exercise")
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 4)
    }
}
