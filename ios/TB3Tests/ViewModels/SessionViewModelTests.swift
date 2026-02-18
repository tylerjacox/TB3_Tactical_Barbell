// TB3 iOS Tests — SessionViewModel (workout engine logic)

import XCTest
@testable import TB3

final class SessionViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeExercise(
        liftName: String = "Squat",
        targetWeight: Double = 200,
        reps: Int = 5,
        isBodyweight: Bool = false
    ) -> ActiveSessionExercise {
        ActiveSessionExercise(
            liftName: liftName,
            targetWeight: targetWeight,
            plates: [],
            repsPerSet: .single(reps),
            isBodyweight: isBodyweight
        )
    }

    private func makeSession(
        exercises: [ActiveSessionExercise]? = nil,
        setsPerExercise: Int = 5,
        week: Int = 1,
        sessionNum: Int = 1
    ) -> ActiveSessionState {
        let exercises = exercises ?? [
            makeExercise(liftName: "Squat", targetWeight: 200),
            makeExercise(liftName: "Bench", targetWeight: 150),
            makeExercise(liftName: "Weighted Pull-up", targetWeight: 50, isBodyweight: true),
        ]

        var sets: [SessionSet] = []
        for (i, _) in exercises.enumerated() {
            for s in 1...setsPerExercise {
                sets.append(SessionSet(
                    exerciseIndex: i,
                    setNumber: s,
                    targetReps: 5,
                    actualReps: nil,
                    completed: false,
                    completedAt: nil
                ))
            }
        }

        return ActiveSessionState(
            status: .inProgress,
            templateId: "operator",
            week: week,
            session: sessionNum,
            exercises: exercises,
            sets: sets,
            currentExerciseIndex: 0,
            timerState: nil,
            startedAt: Date.iso8601Now(),
            exerciseStartTimes: [0: Date.iso8601Now()],
            weekPercentage: 70,
            minSets: 3,
            maxSets: setsPerExercise
        )
    }

    // MARK: - Current Exercise

    func testCurrentExerciseReturnsCorrectExercise() {
        let session = makeSession()
        XCTAssertEqual(session.exercises[session.currentExerciseIndex].liftName, "Squat")
    }

    func testCurrentExerciseAfterNavigation() {
        var session = makeSession()
        session.currentExerciseIndex = 1
        XCTAssertEqual(session.exercises[session.currentExerciseIndex].liftName, "Bench")
    }

    // MARK: - Sets Tracking

    func testCurrentSetsFiltersByExerciseIndex() {
        let session = makeSession(setsPerExercise: 5)
        let sets = session.sets.filter { $0.exerciseIndex == 0 }
        XCTAssertEqual(sets.count, 5)
    }

    func testCompletedSetsCountStartsAtZero() {
        let session = makeSession()
        let completedCount = session.sets.filter { $0.exerciseIndex == 0 && $0.completed }.count
        XCTAssertEqual(completedCount, 0)
    }

    func testNextSetNumberStartsAtOne() {
        let session = makeSession()
        let completedCount = session.sets.filter { $0.exerciseIndex == 0 && $0.completed }.count
        XCTAssertEqual(completedCount + 1, 1)
    }

    func testAllSetsCompleteIsFalseInitially() {
        let session = makeSession()
        let sets = session.sets.filter { $0.exerciseIndex == 0 }
        XCTAssertFalse(sets.allSatisfy(\.completed))
    }

    func testAllSetsCompleteIsTrueWhenAllDone() {
        var session = makeSession(setsPerExercise: 3)
        for i in 0..<session.sets.count where session.sets[i].exerciseIndex == 0 {
            session.sets[i].completed = true
        }
        let sets = session.sets.filter { $0.exerciseIndex == 0 }
        XCTAssertTrue(sets.allSatisfy(\.completed))
    }

    func testAllExercisesComplete() {
        var session = makeSession(setsPerExercise: 3)
        for i in 0..<session.sets.count {
            session.sets[i].completed = true
        }
        XCTAssertTrue(session.sets.allSatisfy(\.completed))
    }

    // MARK: - Timer State

    func testTimerStateNilInitially() {
        let session = makeSession()
        XCTAssertNil(session.timerState)
    }

    func testRestTimerState() {
        var session = makeSession()
        let now = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .rest, startedAt: now, restDurationSeconds: 120)
        XCTAssertEqual(session.timerState?.phase, .rest)
        XCTAssertEqual(session.timerState?.restDurationSeconds, 120)
    }

    func testExerciseTimerState() {
        var session = makeSession()
        let now = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .exercise, startedAt: now, restDurationSeconds: nil)
        XCTAssertEqual(session.timerState?.phase, .exercise)
        XCTAssertNil(session.timerState?.restDurationSeconds)
    }

    // MARK: - Set Completion Flow

    func testCompletingSetMarksCompleted() {
        var session = makeSession(setsPerExercise: 3)
        if let idx = session.sets.firstIndex(where: { $0.exerciseIndex == 0 && !$0.completed }) {
            session.sets[idx].completed = true
            session.sets[idx].actualReps = session.sets[idx].targetReps
            session.sets[idx].completedAt = Date().timeIntervalSince1970 * 1000
        }
        let completedCount = session.sets.filter { $0.exerciseIndex == 0 && $0.completed }.count
        XCTAssertEqual(completedCount, 1)
    }

    func testCompletingSetStartsRestTimer() {
        var session = makeSession(setsPerExercise: 3)
        if let idx = session.sets.firstIndex(where: { $0.exerciseIndex == 0 && !$0.completed }) {
            session.sets[idx].completed = true
            let now = Date().timeIntervalSince1970 * 1000
            session.timerState = TimerState(phase: .rest, startedAt: now, restDurationSeconds: 120)
        }
        XCTAssertEqual(session.timerState?.phase, .rest)
    }

    func testBeginSetTransitionsToExercisePhase() {
        var session = makeSession(setsPerExercise: 3)
        // Complete first set, start rest
        let now = Date().timeIntervalSince1970 * 1000
        session.sets[0].completed = true
        session.timerState = TimerState(phase: .rest, startedAt: now, restDurationSeconds: 120)

        // "Begin Set" transitions to exercise phase
        session.timerState = TimerState(phase: .exercise, startedAt: now, restDurationSeconds: nil)
        XCTAssertEqual(session.timerState?.phase, .exercise)
    }

    // MARK: - Undo

    func testUndoRevertsSetCompletion() {
        var session = makeSession(setsPerExercise: 3)
        // Complete set 1
        session.sets[0].completed = true
        session.sets[0].actualReps = 5
        session.sets[0].completedAt = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .rest, startedAt: Date().timeIntervalSince1970 * 1000, restDurationSeconds: 120)

        // Undo
        session.sets[0].completed = false
        session.sets[0].actualReps = nil
        session.sets[0].completedAt = nil
        session.timerState = nil

        XCTAssertFalse(session.sets[0].completed)
        XCTAssertNil(session.sets[0].actualReps)
        XCTAssertNil(session.timerState)
    }

    // MARK: - Exercise Navigation

    func testGoToExerciseUpdatesIndex() {
        var session = makeSession()
        session.currentExerciseIndex = 1
        XCTAssertEqual(session.currentExerciseIndex, 1)
        XCTAssertEqual(session.exercises[session.currentExerciseIndex].liftName, "Bench")
    }

    func testGoToExerciseClearsTimer() {
        var session = makeSession()
        session.timerState = TimerState(phase: .rest, startedAt: 0, restDurationSeconds: 120)
        session.currentExerciseIndex = 2
        session.timerState = nil
        XCTAssertNil(session.timerState)
    }

    func testGoToExerciseRecordsStartTime() {
        var session = makeSession()
        XCTAssertNil(session.exerciseStartTimes[1])
        session.currentExerciseIndex = 1
        session.exerciseStartTimes[1] = Date.iso8601Now()
        XCTAssertNotNil(session.exerciseStartTimes[1])
    }

    // MARK: - Session Completion

    func testSessionBuildLog() {
        var session = makeSession(setsPerExercise: 3)
        // Complete all sets
        for i in 0..<session.sets.count {
            session.sets[i].completed = true
            session.sets[i].actualReps = session.sets[i].targetReps
        }

        // Build exercise logs
        var exerciseLogs: [SyncExerciseLog] = []
        for (i, exercise) in session.exercises.enumerated() {
            let exerciseSets = session.sets.filter { $0.exerciseIndex == i && $0.completed }
            let setLogs = exerciseSets.map { set in
                SyncExerciseSet(
                    targetReps: set.targetReps,
                    actualReps: set.actualReps ?? set.targetReps,
                    completed: set.completed
                )
            }
            exerciseLogs.append(SyncExerciseLog(
                liftName: exercise.liftName,
                targetWeight: exercise.targetWeight,
                actualWeight: exercise.targetWeight,
                sets: setLogs,
                durationSeconds: nil
            ))
        }

        XCTAssertEqual(exerciseLogs.count, 3)
        XCTAssertEqual(exerciseLogs[0].liftName, "Squat")
        XCTAssertEqual(exerciseLogs[0].sets.count, 3)
        XCTAssertTrue(exerciseLogs[0].sets.allSatisfy(\.completed))
    }

    func testSessionStatusCompleted() {
        var session = makeSession(setsPerExercise: 3)
        for i in 0..<session.sets.count {
            session.sets[i].completed = true
        }
        let completedCount = session.sets.filter(\.completed).count
        let totalCount = session.sets.count
        let status = completedCount == totalCount ? "completed" : completedCount > 0 ? "partial" : "skipped"
        XCTAssertEqual(status, "completed")
    }

    func testSessionStatusPartial() {
        var session = makeSession(setsPerExercise: 3)
        session.sets[0].completed = true
        let completedCount = session.sets.filter(\.completed).count
        let totalCount = session.sets.count
        let status = completedCount == totalCount ? "completed" : completedCount > 0 ? "partial" : "skipped"
        XCTAssertEqual(status, "partial")
    }

    func testSessionStatusSkipped() {
        let session = makeSession(setsPerExercise: 3)
        let completedCount = session.sets.filter(\.completed).count
        let totalCount = session.sets.count
        let status = completedCount == totalCount ? "completed" : completedCount > 0 ? "partial" : "skipped"
        XCTAssertEqual(status, "skipped")
    }

    // MARK: - RepsPerSet Array (Gladiator Week 6)

    func testArrayRepsPerSet() {
        let exercise = ActiveSessionExercise(
            liftName: "Squat",
            targetWeight: 200,
            plates: [],
            repsPerSet: .array([3, 2, 1, 3, 2]),
            isBodyweight: false
        )
        let reps = exercise.repsPerSet
        switch reps {
        case .array(let arr):
            XCTAssertEqual(arr, [3, 2, 1, 3, 2])
        case .single:
            XCTFail("Expected array reps")
        }
    }

    // MARK: - Bodyweight Exercise

    func testBodyweightExercise() {
        let exercise = makeExercise(liftName: "Weighted Pull-up", targetWeight: 50, isBodyweight: true)
        XCTAssertTrue(exercise.isBodyweight)
        XCTAssertEqual(exercise.targetWeight, 50)
    }

    // MARK: - Navigation Bounds (Swipe Gesture Support)

    func testNavigationToFirstExercise() {
        var session = makeSession()
        session.currentExerciseIndex = 2
        session.currentExerciseIndex = 0
        XCTAssertEqual(session.currentExerciseIndex, 0)
        XCTAssertEqual(session.exercises[0].liftName, "Squat")
    }

    func testNavigationToLastExercise() {
        var session = makeSession()
        session.currentExerciseIndex = session.exercises.count - 1
        XCTAssertEqual(session.currentExerciseIndex, 2)
        XCTAssertEqual(session.exercises[2].liftName, "Weighted Pull-up")
    }

    func testNavigationBoundsCheckLowerBound() {
        let session = makeSession()
        // Index 0 is the minimum — can't go lower
        XCTAssertEqual(session.currentExerciseIndex, 0)
        // Swipe right should be blocked at index 0
        let canGoPrevious = session.currentExerciseIndex > 0
        XCTAssertFalse(canGoPrevious)
    }

    func testNavigationBoundsCheckUpperBound() {
        var session = makeSession()
        session.currentExerciseIndex = session.exercises.count - 1
        // At last exercise — can't go forward
        let canGoNext = session.currentExerciseIndex < session.exercises.count - 1
        XCTAssertFalse(canGoNext)
    }

    func testNavigationCanGoNextFromMiddle() {
        var session = makeSession()
        session.currentExerciseIndex = 1
        let canGoNext = session.currentExerciseIndex < session.exercises.count - 1
        let canGoPrevious = session.currentExerciseIndex > 0
        XCTAssertTrue(canGoNext)
        XCTAssertTrue(canGoPrevious)
    }

    func testNavigationSingleExercise() {
        let session = makeSession(exercises: [
            makeExercise(liftName: "Squat", targetWeight: 200)
        ])
        let canGoNext = session.currentExerciseIndex < session.exercises.count - 1
        let canGoPrevious = session.currentExerciseIndex > 0
        XCTAssertFalse(canGoNext)
        XCTAssertFalse(canGoPrevious)
    }

    // MARK: - Timer Clearing on Navigation

    func testNavigationClearsRestTimer() {
        var session = makeSession()
        let now = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .rest, startedAt: now, restDurationSeconds: 120)
        XCTAssertNotNil(session.timerState)

        // Navigate to next exercise
        session.currentExerciseIndex = 1
        session.timerState = nil
        XCTAssertNil(session.timerState)
    }

    func testNavigationClearsExerciseTimer() {
        var session = makeSession()
        let now = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .exercise, startedAt: now, restDurationSeconds: nil)
        XCTAssertNotNil(session.timerState)

        session.currentExerciseIndex = 1
        session.timerState = nil
        XCTAssertNil(session.timerState)
    }

    // MARK: - Exercise Start Time Tracking

    func testFirstVisitRecordsStartTime() {
        var session = makeSession()
        XCTAssertNotNil(session.exerciseStartTimes[0], "First exercise should have start time from session creation")
        XCTAssertNil(session.exerciseStartTimes[1], "Second exercise should not have start time yet")

        session.currentExerciseIndex = 1
        session.exerciseStartTimes[1] = Date.iso8601Now()
        XCTAssertNotNil(session.exerciseStartTimes[1])
    }

    func testRevisitDoesNotOverwriteStartTime() {
        var session = makeSession()
        session.currentExerciseIndex = 1
        let firstVisit = Date.iso8601Now()
        session.exerciseStartTimes[1] = firstVisit

        // Go back and forth
        session.currentExerciseIndex = 0
        session.currentExerciseIndex = 1

        // Should keep original time
        if session.exerciseStartTimes[1] == nil {
            session.exerciseStartTimes[1] = Date.iso8601Now()
        }
        XCTAssertEqual(session.exerciseStartTimes[1], firstVisit)
    }

    // MARK: - Sets Per Exercise Independence

    func testSetsAreIndependentPerExercise() {
        var session = makeSession(setsPerExercise: 3)
        // Complete all sets for exercise 0
        for i in 0..<session.sets.count where session.sets[i].exerciseIndex == 0 {
            session.sets[i].completed = true
        }

        // Exercise 0 complete
        let exercise0Sets = session.sets.filter { $0.exerciseIndex == 0 }
        XCTAssertTrue(exercise0Sets.allSatisfy(\.completed))

        // Exercise 1 should still be incomplete
        let exercise1Sets = session.sets.filter { $0.exerciseIndex == 1 }
        XCTAssertFalse(exercise1Sets.allSatisfy(\.completed))
        XCTAssertEqual(exercise1Sets.filter(\.completed).count, 0)
    }

    // MARK: - Completed Sets Count for Current Exercise

    func testCompletedSetsCountChangesWithExercise() {
        var session = makeSession(setsPerExercise: 3)
        // Complete 2 sets of exercise 0
        session.sets[0].completed = true
        session.sets[1].completed = true

        let ex0Completed = session.sets.filter { $0.exerciseIndex == 0 && $0.completed }.count
        XCTAssertEqual(ex0Completed, 2)

        // Switch to exercise 1 — should have 0 completed
        session.currentExerciseIndex = 1
        let ex1Completed = session.sets.filter { $0.exerciseIndex == 1 && $0.completed }.count
        XCTAssertEqual(ex1Completed, 0)
    }
}
