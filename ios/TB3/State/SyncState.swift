// TB3 iOS — Sync State (mirrors services/sync.ts syncState signal)

import Foundation

@Observable
final class SyncState {
    var isSyncing = false
    var lastSyncedAt: String?
    var error: String?
}
