// TB3 iOS — Strava Token Manager (mirrors TokenManager pattern for Strava OAuth tokens)
// Actor-based, Keychain storage, automatic token refresh via backend proxy.

import Foundation

struct StravaTokens: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Double // seconds since epoch
    var athleteId: Int
    var athleteName: String?
}

actor StravaTokenManager {
    private static let tokensKey = "tb3_strava_tokens"
    private var isRefreshing = false

    // MARK: - Store / Load / Clear

    func storeTokens(_ tokens: StravaTokens) {
        if let data = try? JSONEncoder().encode(tokens) {
            try? Keychain.save(key: Self.tokensKey, data: data)
        }
    }

    func getStoredTokens() -> StravaTokens? {
        guard let data = try? Keychain.load(key: Self.tokensKey) else { return nil }
        return try? JSONDecoder().decode(StravaTokens.self, from: data)
    }

    func clearTokens() {
        Keychain.delete(key: Self.tokensKey)
    }

    // MARK: - Access Token (auto-refresh if expired)

    func getValidAccessToken() async -> String? {
        guard let tokens = getStoredTokens() else { return nil }

        // If token is still valid (with 5 min buffer), use it
        if Date().timeIntervalSince1970 < tokens.expiresAt - 300 {
            return tokens.accessToken
        }

        // Refresh
        return await refreshTokens()
    }

    // MARK: - Token Refresh (via backend proxy)

    func refreshTokens() async -> String? {
        guard !isRefreshing else { return nil }
        guard let tokens = getStoredTokens(), !tokens.refreshToken.isEmpty else { return nil }

        isRefreshing = true
        defer { isRefreshing = false }

        guard let url = URL(string: "\(AppConfig.apiURL)/strava/token") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": tokens.refreshToken,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresAt = json["expires_at"] as? Double else {
                return nil
            }

            let refreshToken = (json["refresh_token"] as? String) ?? tokens.refreshToken

            let newTokens = StravaTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                athleteId: tokens.athleteId,
                athleteName: tokens.athleteName
            )

            storeTokens(newTokens)
            return accessToken
        } catch {
            return nil
        }
    }
}
