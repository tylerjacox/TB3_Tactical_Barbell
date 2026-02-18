// TB3 iOS Tests — FeedbackService (milestone labels + configuration)

import XCTest
@testable import TB3

@MainActor
final class FeedbackServiceTests: XCTestCase {

    // MARK: - Voice Milestones

    func testMilestoneAt60Seconds() {
        let service = FeedbackService()
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 60), "One minute")
    }

    func testMilestoneAt30Seconds() {
        let service = FeedbackService()
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 30), "Thirty seconds")
    }

    func testMilestoneAt15Seconds() {
        let service = FeedbackService()
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 15), "Fifteen seconds")
    }

    func testMilestoneCountdown() {
        let service = FeedbackService()
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 5), "Five")
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 4), "Four")
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 3), "Three")
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 2), "Two")
        XCTAssertEqual(service.voiceMilestoneLabel(secondsRemaining: 1), "One")
    }

    func testNoMilestoneAtNonThreshold() {
        let service = FeedbackService()
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: 45))
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: 20))
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: 10))
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: 7))
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: 0))
    }

    func testNoMilestoneAtNegativeSeconds() {
        let service = FeedbackService()
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: -1))
        XCTAssertNil(service.voiceMilestoneLabel(secondsRemaining: -60))
    }

    // MARK: - Configuration

    func testConfigureSetsValues() {
        let service = FeedbackService()
        service.configure(soundMode: "vibrate", voiceEnabled: true, voiceName: "Samantha")
        // Can't directly test private properties, but we can verify no crash
        // and the service doesn't throw
    }

    func testConfigureWithNilVoiceName() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: false, voiceName: nil)
        // Should not crash
    }

    func testConfigureOffMode() {
        let service = FeedbackService()
        service.configure(soundMode: "off", voiceEnabled: false, voiceName: nil)
        // Should not crash when calling feedback methods
        service.setComplete()
        service.exerciseComplete()
        service.undo()
        service.error()
    }

    // MARK: - All 8 Milestone Thresholds

    func testAllMilestoneThresholds() {
        let service = FeedbackService()
        let expected: [Int: String] = [
            60: "One minute",
            30: "Thirty seconds",
            15: "Fifteen seconds",
            5: "Five",
            4: "Four",
            3: "Three",
            2: "Two",
            1: "One",
        ]

        for (seconds, label) in expected {
            XCTAssertEqual(
                service.voiceMilestoneLabel(secondsRemaining: seconds), label,
                "Milestone at \(seconds)s should be '\(label)'"
            )
        }
    }

    func testMilestoneCount() {
        let service = FeedbackService()
        var count = 0
        for s in 0...120 {
            if service.voiceMilestoneLabel(secondsRemaining: s) != nil {
                count += 1
            }
        }
        XCTAssertEqual(count, 8, "There should be exactly 8 milestone thresholds")
    }

    // MARK: - Cast Connected Muting

    func testCastConnectedDoesNotCrashOnFeedback() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: true, voiceName: nil, castConnected: true)
        // All feedback methods should not crash even when cast-muted
        service.setComplete()
        service.exerciseComplete()
        service.restComplete()
        service.sessionComplete()
        service.undo()
        service.error()
    }

    func testCastDisconnectedDoesNotCrashOnFeedback() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: true, voiceName: nil, castConnected: false)
        service.setComplete()
        service.exerciseComplete()
        service.restComplete()
        service.sessionComplete()
        service.undo()
        service.error()
    }

    func testConfigureCastConnectedParameter() {
        let service = FeedbackService()
        // Default castConnected is false
        service.configure(soundMode: "on", voiceEnabled: false, voiceName: nil)
        // Should not crash

        // Explicitly set castConnected
        service.configure(soundMode: "on", voiceEnabled: false, voiceName: nil, castConnected: true)
        // Should not crash
    }

    func testCastConnectedWithVibrateModeStillWorks() {
        let service = FeedbackService()
        // Vibrate mode with cast connected: haptics should still fire (they're phone-only)
        service.configure(soundMode: "vibrate", voiceEnabled: false, voiceName: nil, castConnected: true)
        service.setComplete()
        service.exerciseComplete()
        service.undo()
        // No crash = haptics still work when cast connected
    }

    // MARK: - Sound Mode Variants

    func testVibrateModeFeedback() {
        let service = FeedbackService()
        service.configure(soundMode: "vibrate", voiceEnabled: false, voiceName: nil)
        service.setComplete()
        service.exerciseComplete()
        service.restComplete()
        service.sessionComplete()
        service.undo()
        service.error()
    }

    func testSpeakMilestoneDoesNotCrash() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: true, voiceName: nil)
        service.speakMilestone("One minute")
        service.speakMilestone("Thirty seconds")
        service.speakMilestone("5")
    }

    func testSpeakMilestoneWithCastConnectedDoesNotCrash() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: true, voiceName: nil, castConnected: true)
        // Should be silently muted — no crash
        service.speakMilestone("One minute")
    }

    func testSpeakTestDoesNotCrash() {
        let service = FeedbackService()
        service.configure(soundMode: "on", voiceEnabled: true, voiceName: nil)
        service.speakTest()
    }
}
