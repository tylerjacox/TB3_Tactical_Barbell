// TB3 iOS — Sync Service (mirrors services/sync.ts)
// Performs push/pull sync with the Lambda /sync endpoint.

import Foundation

actor SyncService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    /// Perform a full sync cycle: push local changes, pull remote changes.
    /// Returns the server time from the response for updating lastSyncedAt.
    func performSync(
        localChanges: SyncPushPayload,
        lastSyncedAt: String?
    ) async throws -> SyncResponse {
        // Always pass lastSyncedAt: nil for pull (client deduplicates by ID)
        // This matches the PWA behavior in sync.ts line 88
        let request = SyncRequest(
            lastSyncedAt: nil,
            push: localChanges
        )

        return try await apiClient.post(
            path: "/sync",
            body: request,
            responseType: SyncResponse.self
        )
    }
}
