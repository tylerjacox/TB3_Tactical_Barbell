// TB3 iOS Tests — CastService (message serialization, connection lifecycle, muting)

import XCTest
@testable import TB3

// Mock CastSession to capture sent messages
final class MockCastSession: CastSessionProtocol, @unchecked Sendable {
    var sentMessages: [(message: String, namespace: String)] = []
    var shouldThrow = false

    func sendMessage(_ message: String, namespace: String) throws {
        if shouldThrow { throw NSError(domain: "CastTest", code: 1) }
        sentMessages.append((message, namespace))
    }

    var lastMessage: String? { sentMessages.last?.message }

    func lastPayload() -> [String: Any]? {
        guard let msg = lastMessage,
              let data = msg.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }
}

@MainActor
final class CastServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT() -> (service: CastService, castState: CastState, mockSession: MockCastSession) {
        let castState = CastState()
        let service = CastService(castState: castState)
        let mockSession = MockCastSession()
        return (service, castState, mockSession)
    }

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
        currentIndex: Int = 0
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
            week: 1,
            session: 1,
            exercises: exercises,
            sets: sets,
            currentExerciseIndex: currentIndex,
            timerState: nil,
            startedAt: Date.iso8601Now(),
            exerciseStartTimes: [0: Date.iso8601Now()],
            weekPercentage: 70,
            minSets: 3,
            maxSets: setsPerExercise
        )
    }

    // MARK: - Connection Lifecycle

    func testOnSessionConnectedSetsCastState() {
        let (service, castState, mockSession) = makeSUT()
        XCTAssertFalse(castState.connected)
        service.onSessionConnected(mockSession)
        XCTAssertTrue(castState.connected)
    }

    func testOnSessionDisconnectedClearsCastState() {
        let (service, castState, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        XCTAssertTrue(castState.connected)

        service.onSessionDisconnected()
        XCTAssertFalse(castState.connected)
        XCTAssertNil(castState.deviceName)
    }

    func testUpdateDeviceName() {
        let (service, castState, _) = makeSUT()
        service.updateDeviceName("Living Room TV")
        XCTAssertEqual(castState.deviceName, "Living Room TV")
    }

    func testUpdateDeviceNameNil() {
        let (service, castState, _) = makeSUT()
        service.updateDeviceName("Living Room TV")
        service.updateDeviceName(nil)
        XCTAssertNil(castState.deviceName)
    }

    func testSetAvailable() {
        let (service, castState, _) = makeSUT()
        XCTAssertFalse(castState.available)
        service.setAvailable(true)
        XCTAssertTrue(castState.available)
        service.setAvailable(false)
        XCTAssertFalse(castState.available)
    }

    // MARK: - Idle Message

    func testSendNilSessionSendsIdle() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        service.sendSessionStateImmediate(nil)

        let payload = mockSession.lastPayload()
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?["idle"] as? Bool, true)
    }

    // MARK: - Workout State Message

    func testSendSessionStateIncludesExerciseName() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertNotNil(payload)
        let name = payload?["exerciseName"] as? String ?? ""
        XCTAssertFalse(name.isEmpty, "Exercise name should not be empty")
    }

    func testSendSessionStateIncludesWeight() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["weight"] as? Double, 200)
    }

    func testSendSessionStateIncludesUnit() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["unit"] as? String, "lb")
    }

    func testSendSessionStateIncludesSetCounts() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession(setsPerExercise: 5)
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["totalSets"] as? Int, 5)
        XCTAssertEqual(payload?["completedSets"] as? Int, 0)
    }

    func testSendSessionStateIncludesExercises() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        let exercises = payload?["exercises"] as? [[String: Any]]
        XCTAssertEqual(exercises?.count, 3)
    }

    func testSendSessionStateIncludesWeekAndSession() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["week"] as? Int, 1)
        XCTAssertEqual(payload?["session"] as? Int, 1)
    }

    func testSendSessionStateIncludesTemplateId() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession()
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["templateId"] as? String, "operator")
    }

    func testSendSessionStateIncludesCurrentExerciseIndex() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession(currentIndex: 2)
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["currentExerciseIndex"] as? Int, 2)
    }

    func testSendSessionStateIncludesBodyweightFlag() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession(currentIndex: 2) // Pull-up is bodyweight
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["isBodyweight"] as? Bool, true)
    }

    func testSendSessionStateIncludesTimerWhenActive() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        var session = makeSession()
        let now = Date().timeIntervalSince1970 * 1000
        session.timerState = TimerState(phase: .rest, startedAt: now, restDurationSeconds: 120)
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        let timer = payload?["timer"] as? [String: Any]
        XCTAssertNotNil(timer)
        XCTAssertEqual(timer?["phase"] as? String, "rest")
        XCTAssertEqual(timer?["restDurationSeconds"] as? Int, 120)
    }

    func testSendSessionStateWithCompletedSets() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        var session = makeSession(setsPerExercise: 3)
        session.sets[0].completed = true
        session.sets[1].completed = true
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["completedSets"] as? Int, 2)
        XCTAssertEqual(payload?["totalSets"] as? Int, 3)
    }

    func testSendSessionStateTargetRepsForNextSet() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        let session = makeSession(setsPerExercise: 3)
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        XCTAssertEqual(payload?["targetReps"] as? Int, 5)
    }

    // MARK: - Guard: No Session = No Send

    func testSendWithoutConnectionDoesNotSend() {
        let (service, _, mockSession) = makeSUT()
        let session = makeSession()
        service.sendSessionStateImmediate(session)
        XCTAssertTrue(mockSession.sentMessages.isEmpty)
    }

    func testSendAfterDisconnectDoesNotSend() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        service.onSessionDisconnected()

        let session = makeSession()
        service.sendSessionStateImmediate(session)
        XCTAssertTrue(mockSession.sentMessages.isEmpty)
    }

    // MARK: - Exercise Summaries

    func testExerciseSummariesTrackCompletion() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        var session = makeSession(setsPerExercise: 3)
        for i in 0..<3 {
            session.sets[i].completed = true
        }
        service.sendSessionStateImmediate(session)

        let payload = mockSession.lastPayload()
        let exercises = payload?["exercises"] as? [[String: Any]]
        XCTAssertEqual(exercises?[0]["completedSets"] as? Int, 3)
        XCTAssertEqual(exercises?[0]["totalSets"] as? Int, 3)
        XCTAssertEqual(exercises?[1]["completedSets"] as? Int, 0)
    }

    // MARK: - Error Handling

    func testSendMessageErrorDoesNotCrash() {
        let (service, _, mockSession) = makeSUT()
        service.onSessionConnected(mockSession)
        mockSession.shouldThrow = true

        let session = makeSession()
        service.sendSessionStateImmediate(session)
        // Should not crash — error is silently caught
    }
}
