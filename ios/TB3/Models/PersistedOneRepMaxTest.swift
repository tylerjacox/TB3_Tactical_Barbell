// TB3 iOS — Persisted One Rep Max Test (SwiftData, mirrors types.ts OneRepMaxTest)

import Foundation
import SwiftData

@Model
final class PersistedOneRepMaxTest {
    @Attribute(.unique) var id: String = ""
    var date: String = ""
    var liftName: String = ""
    var weight: Double = 0
    var reps: Int = 0
    var calculatedMax: Double = 0
    var maxType: String = ""
    var workingMax: Double = 0
    var lastModified: String = ""

    init() {}

    init(from sync: SyncOneRepMaxTest) {
        self.id = sync.id
        self.date = sync.date
        self.liftName = sync.liftName
        self.weight = sync.weight
        self.reps = sync.reps
        self.calculatedMax = sync.calculatedMax
        self.maxType = sync.maxType
        self.workingMax = sync.workingMax
        self.lastModified = sync.lastModified
    }

    // MARK: - Conversion to sync payload

    func toSyncOneRepMaxTest() -> SyncOneRepMaxTest {
        SyncOneRepMaxTest(
            id: id,
            date: date,
            liftName: liftName,
            weight: weight,
            reps: reps,
            calculatedMax: calculatedMax,
            maxType: maxType,
            workingMax: workingMax,
            lastModified: lastModified
        )
    }

    var liftNameEnum: LiftName? {
        LiftName(rawValue: liftName)
    }

    var maxTypeEnum: MaxType? {
        MaxType(rawValue: maxType)
    }
}
