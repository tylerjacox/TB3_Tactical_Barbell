// TB3 iOS Tests — Strava Service Tests

import XCTest
@testable import TB3

final class StravaActivityFormatterTests: XCTestCase {

    // MARK: - Helpers

    private func makeSessionLog(
        templateId: String = "operator",
        week: Int = 3,
        sessionNumber: Int = 2,
        startedAt: String = "2024-06-15T09:00:00Z",
        completedAt: String = "2024-06-15T09:42:00Z",
        exercises: [SyncExerciseLog] = []
    ) -> SyncSessionLog {
        SyncSessionLog(
            id: generateId(),
            date: "2024-06-15",
            templateId: templateId,
            week: week,
            sessionNumber: sessionNumber,
            status: "completed",
            startedAt: startedAt,
            completedAt: completedAt,
            exercises: exercises,
            notes: "",
            durationSeconds: nil,
            lastModified: "2024-06-15T09:42:00Z"
        )
    }

    private func makeExerciseLog(
        liftName: String = "Squat",
        targetWeight: Double = 225,
        sets: [SyncExerciseSet] = []
    ) -> SyncExerciseLog {
        SyncExerciseLog(
            liftName: liftName,
            targetWeight: targetWeight,
            actualWeight: targetWeight,
            sets: sets,
            durationSeconds: nil
        )
    }

    private func makeSet(targetReps: Int = 5, actualReps: Int = 5, completed: Bool = true) -> SyncExerciseSet {
        SyncExerciseSet(targetReps: targetReps, actualReps: actualReps, completed: completed)
    }

    // MARK: - Activity Name

    func testActivityNameFormat() {
        let session = makeSessionLog(templateId: "operator", week: 3, sessionNumber: 2)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.name, "TB3 Operator — W3/S2")
    }

    func testActivityNameWithZulu() {
        let session = makeSessionLog(templateId: "zulu", week: 1, sessionNumber: 4)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.name, "TB3 Zulu — W1/S4")
    }

    func testActivityNameWithUnknownTemplate() {
        let session = makeSessionLog(templateId: "custom-program", week: 1, sessionNumber: 1)
        let activity = StravaActivityFormatter.format(session: session)

        // Falls back to capitalized templateId
        XCTAssertEqual(activity.name, "TB3 Custom-program — W1/S1")
    }

    // MARK: - Sport Type & Trainer

    func testSportTypeIsWeightTraining() {
        let session = makeSessionLog()
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.sportType, "WeightTraining")
        XCTAssertTrue(activity.trainer)
    }

    // MARK: - Duration

    func testDurationCalculation() {
        // 42 minutes = 2520 seconds
        let session = makeSessionLog(
            startedAt: "2024-06-15T09:00:00Z",
            completedAt: "2024-06-15T09:42:00Z"
        )
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.elapsedTime, 2520)
    }

    func testMinimumDuration() {
        // Very short session (10 seconds) should be clamped to 60
        let session = makeSessionLog(
            startedAt: "2024-06-15T09:00:00Z",
            completedAt: "2024-06-15T09:00:10Z"
        )
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.elapsedTime, 60)
    }

    // MARK: - Description

    func testDescriptionWithExercises() {
        let exercises = [
            makeExerciseLog(liftName: "Squat", targetWeight: 225, sets: [
                makeSet(targetReps: 5, actualReps: 5),
                makeSet(targetReps: 5, actualReps: 5),
                makeSet(targetReps: 5, actualReps: 5),
            ]),
            makeExerciseLog(liftName: "Bench", targetWeight: 185, sets: [
                makeSet(targetReps: 5, actualReps: 5),
                makeSet(targetReps: 5, actualReps: 5),
                makeSet(targetReps: 5, actualReps: 5),
            ]),
        ]

        let session = makeSessionLog(exercises: exercises)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertTrue(activity.description.contains("Squat: 225 lb"))
        XCTAssertTrue(activity.description.contains("3×5"))
        XCTAssertTrue(activity.description.contains("Bench Press: 185 lb"))
    }

    func testDescriptionPartialSession() {
        let exercises = [
            makeExerciseLog(liftName: "Squat", targetWeight: 225, sets: [
                makeSet(targetReps: 5, actualReps: 5, completed: true),
                makeSet(targetReps: 5, actualReps: 5, completed: true),
                makeSet(targetReps: 5, actualReps: 0, completed: false),
            ]),
        ]

        let session = makeSessionLog(exercises: exercises)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertTrue(activity.description.contains("(partial)"))
        XCTAssertTrue(activity.description.contains("2×5"))
    }

    func testDescriptionIncludesFooter() {
        let session = makeSessionLog(templateId: "operator", week: 3, sessionNumber: 2)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertTrue(activity.description.contains("TB3 Operator"))
        XCTAssertTrue(activity.description.contains("Week 3 Session 2"))
    }

    // MARK: - Start Date

    func testStartDatePassedThrough() {
        let session = makeSessionLog(startedAt: "2024-06-15T09:00:00Z")
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertEqual(activity.startDateLocal, "2024-06-15T09:00:00Z")
    }

    // MARK: - Display Names

    func testLiftDisplayNames() {
        let exercises = [
            makeExerciseLog(liftName: "Weighted Pull-up", targetWeight: 45, sets: [
                makeSet(targetReps: 5, actualReps: 5),
            ]),
            makeExerciseLog(liftName: "Military Press", targetWeight: 95, sets: [
                makeSet(targetReps: 5, actualReps: 5),
            ]),
        ]

        let session = makeSessionLog(exercises: exercises)
        let activity = StravaActivityFormatter.format(session: session)

        XCTAssertTrue(activity.description.contains("Weighted Pull-Up"))
        XCTAssertTrue(activity.description.contains("Overhead Press"))
    }

    // MARK: - PKCE Helper

    func testPKCEVerifierLength() {
        let verifier = PKCEHelper.generateCodeVerifier()
        XCTAssertEqual(verifier.count, 43)
    }

    func testPKCEChallengeIsDeterministic() {
        let verifier = "test-verifier-string-for-pkce-challenge"
        let challenge1 = PKCEHelper.generateCodeChallenge(verifier: verifier)
        let challenge2 = PKCEHelper.generateCodeChallenge(verifier: verifier)

        XCTAssertEqual(challenge1, challenge2)
        XCTAssertFalse(challenge1.isEmpty)
    }

    func testPKCEChallengeNoSpecialChars() {
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.generateCodeChallenge(verifier: verifier)

        XCTAssertFalse(challenge.contains("+"))
        XCTAssertFalse(challenge.contains("/"))
        XCTAssertFalse(challenge.contains("="))
    }
}
