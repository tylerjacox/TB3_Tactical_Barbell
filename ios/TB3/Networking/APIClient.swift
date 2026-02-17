// TB3 iOS — API Client (URLSession wrapper with auth header injection)
// Handles JWT Bearer token injection and 401 retry with token refresh.

import Foundation

actor APIClient {
    private let baseURL: String
    private let tokenManager: TokenManager

    init(baseURL: String = AppConfig.apiURL, tokenManager: TokenManager = TokenManager()) {
        self.baseURL = baseURL
        self.tokenManager = tokenManager
    }

    // MARK: - Authenticated POST

    /// Perform an authenticated POST request with JSON body.
    /// Automatically injects Bearer token and retries once on 401.
    func post<T: Encodable, R: Decodable>(
        path: String,
        body: T,
        responseType: R.Type
    ) async throws -> R {
        var token = await tokenManager.getAccessToken()
        if token == nil {
            token = await tokenManager.refreshTokens()
        }
        guard let token else {
            throw APIError.unauthorized
        }

        // First attempt
        let (data, statusCode) = try await performRequest(path: path, body: body, token: token)

        // On 401, refresh token and retry once
        if statusCode == 401 {
            guard let newToken = await tokenManager.refreshTokens() else {
                throw APIError.sessionExpired
            }
            let (retryData, retryStatus) = try await performRequest(path: path, body: body, token: newToken)
            guard retryStatus == 200 else {
                throw APIError.httpError(retryStatus)
            }
            return try JSONDecoder().decode(R.self, from: retryData)
        }

        guard statusCode == 200 else {
            throw APIError.httpError(statusCode)
        }

        return try JSONDecoder().decode(R.self, from: data)
    }

    // MARK: - Internal

    private func performRequest<T: Encodable>(
        path: String,
        body: T,
        token: String
    ) async throws -> (Data, Int) {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (data, statusCode)
    }
}

enum APIError: LocalizedError {
    case unauthorized
    case sessionExpired
    case httpError(Int)
    case invalidURL
    case decodingError

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Not authenticated."
        case .sessionExpired: return "Session expired. Please sign out and sign in again."
        case .httpError(let code): return "Request failed (\(code))."
        case .invalidURL: return "Invalid API URL."
        case .decodingError: return "Failed to decode response."
        }
    }
}
