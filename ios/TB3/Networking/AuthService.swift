// TB3 iOS — Auth Service (mirrors services/auth.ts)
// Handles login (via AWS SDK USER_PASSWORD_AUTH), Google OAuth (via ASWebAuthenticationSession),
// signup, email confirmation, forgot password, and sign out.

import Foundation
import AuthenticationServices
import CryptoKit
import AWSCognitoIdentityProvider

enum AuthError: LocalizedError {
    case incorrectCredentials
    case userNotConfirmed
    case passwordResetRequired
    case invalidPassword
    case usernameExists
    case invalidParameter
    case limitExceeded
    case networkError
    case missingPKCEVerifier
    case tokenExchangeFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .incorrectCredentials: return "Incorrect email or password."
        case .userNotConfirmed: return "Please verify your email before signing in."
        case .passwordResetRequired: return "You need to reset your password."
        case .invalidPassword: return "Password must be at least 8 characters with uppercase, lowercase, and numbers."
        case .usernameExists: return "An account with this email already exists."
        case .invalidParameter: return "Please check your input and try again."
        case .limitExceeded: return "Too many attempts. Please try again later."
        case .networkError: return "No internet connection. Please try again."
        case .missingPKCEVerifier: return "Missing PKCE verifier. Please try signing in again."
        case .tokenExchangeFailed: return "Sign-in failed. Please try again."
        case .unknown(let msg): return msg
        }
    }
}

@MainActor
final class AuthService: NSObject {
    private let tokenManager: TokenManager
    private let authState: AuthState
    private let cognitoDomain: String
    private let clientId: String
    private let callbackScheme: String
    private let cognitoClient: CognitoIdentityProviderClient

    // PKCE state for Google OAuth
    private var pkceVerifier: String?

    init(
        tokenManager: TokenManager = TokenManager(),
        authState: AuthState,
        cognitoDomain: String = AppConfig.cognitoDomain,
        clientId: String = AppConfig.cognitoClientId,
        callbackScheme: String = AppConfig.oauthCallbackScheme
    ) {
        self.tokenManager = tokenManager
        self.authState = authState
        self.cognitoDomain = cognitoDomain
        self.clientId = clientId
        self.callbackScheme = callbackScheme

        let config = try! CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration(
            region: AppConfig.cognitoRegion
        )
        self.cognitoClient = CognitoIdentityProviderClient(config: config)
    }

    // MARK: - Initialize Auth (app launch)

    func initAuth() async {
        authState.isLoading = true

        let tokens = await tokenManager.getStoredTokens()
        guard tokens != nil else {
            authState.isAuthenticated = false
            authState.isLoading = false
            return
        }

        // Try online token refresh
        if await isOnline() {
            if let _ = await tokenManager.refreshTokens() {
                if let idToken = await tokenManager.getIdToken(),
                   let payload = tokenManager.parseJwt(idToken) {
                    authState.isAuthenticated = true
                    authState.email = payload["email"] as? String
                    authState.userId = payload["sub"] as? String
                    authState.isLoading = false
                    return
                }
            }
        }

        // Offline grace period
        if await tokenManager.isWithinOfflineGrace() {
            if let idToken = await tokenManager.getIdToken(),
               let payload = tokenManager.parseJwt(idToken) {
                authState.isAuthenticated = true
                authState.email = payload["email"] as? String
                authState.userId = payload["sub"] as? String
                authState.isLoading = false
                return
            }
        }

        // Tokens expired and outside grace
        await tokenManager.clearTokens()
        authState.isAuthenticated = false
        authState.isLoading = false
    }

    // MARK: - Email/Password Sign In (USER_PASSWORD_AUTH)

    func signIn(email: String, password: String) async throws {
        authState.isLoading = true
        authState.error = nil

        do {
            let input = InitiateAuthInput(
                authFlow: .userPasswordAuth,
                authParameters: [
                    "USERNAME": email,
                    "PASSWORD": password,
                ],
                clientId: clientId
            )

            let output = try await cognitoClient.initiateAuth(input: input)

            guard let result = output.authenticationResult,
                  let idToken = result.idToken,
                  let accessToken = result.accessToken,
                  let refreshToken = result.refreshToken else {
                throw AuthError.tokenExchangeFailed
            }

            let expiresIn = result.expiresIn ?? 3600
            let tokens = StoredTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: Date().timeIntervalSince1970 * 1000 + Double(expiresIn) * 1000
            )

            await tokenManager.storeTokens(tokens)

            if let payload = tokenManager.parseJwt(idToken) {
                authState.isAuthenticated = true
                authState.email = payload["email"] as? String
                authState.userId = payload["sub"] as? String
            }
            authState.isLoading = false
        } catch {
            authState.isLoading = false
            let mapped = mapError(error)
            authState.error = mapped.localizedDescription
            throw mapped
        }
    }

    // MARK: - Google OAuth (ASWebAuthenticationSession)

    func signInWithGoogle() async throws {
        authState.isLoading = true
        authState.error = nil

        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(verifier: verifier)
        self.pkceVerifier = verifier

        var components = URLComponents(string: "\(cognitoDomain)/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "identity_provider", value: "Google"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: AppConfig.oauthCallbackURL),
            URLQueryItem(name: "scope", value: "email openid profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        guard let authorizeURL = components.url else {
            authState.isLoading = false
            throw AuthError.unknown("Failed to build authorization URL")
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AuthError.unknown("No callback URL received"))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            authState.isLoading = false
            throw AuthError.tokenExchangeFailed
        }

        guard let verifier = self.pkceVerifier else {
            authState.isLoading = false
            throw AuthError.missingPKCEVerifier
        }

        try await exchangeCodeForTokens(code: code, verifier: verifier)
        self.pkceVerifier = nil
    }

    private func exchangeCodeForTokens(code: String, verifier: String) async throws {
        guard let url = URL(string: "\(cognitoDomain)/oauth2/token") else {
            throw AuthError.tokenExchangeFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "redirect_uri": AppConfig.oauthCallbackURL,
            "code": code,
            "code_verifier": verifier,
        ]
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            authState.isLoading = false
            throw AuthError.tokenExchangeFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String,
              let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Double else {
            authState.isLoading = false
            throw AuthError.tokenExchangeFailed
        }

        let refreshTok = (json["refresh_token"] as? String) ?? ""
        let tokens = StoredTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshTok,
            expiresAt: Date().timeIntervalSince1970 * 1000 + expiresIn * 1000
        )
        await tokenManager.storeTokens(tokens)

        guard let payload = tokenManager.parseJwt(idToken) else {
            authState.isLoading = false
            throw AuthError.tokenExchangeFailed
        }

        authState.isAuthenticated = true
        authState.email = payload["email"] as? String
        authState.userId = payload["sub"] as? String
        authState.isLoading = false
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        authState.isLoading = true
        authState.error = nil

        do {
            let input = SignUpInput(
                clientId: clientId,
                password: password,
                userAttributes: [
                    CognitoIdentityProviderClientTypes.AttributeType(name: "email", value: email),
                ],
                username: email
            )

            _ = try await cognitoClient.signUp(input: input)
            authState.isLoading = false
        } catch {
            authState.isLoading = false
            let mapped = mapError(error)
            authState.error = mapped.localizedDescription
            throw mapped
        }
    }

    // MARK: - Confirm Email

    func confirmEmail(email: String, code: String) async throws {
        do {
            let input = ConfirmSignUpInput(
                clientId: clientId,
                confirmationCode: code,
                username: email
            )
            _ = try await cognitoClient.confirmSignUp(input: input)
        } catch {
            let mapped = mapError(error)
            authState.error = mapped.localizedDescription
            throw mapped
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async throws {
        do {
            let input = ForgotPasswordInput(
                clientId: clientId,
                username: email
            )
            _ = try await cognitoClient.forgotPassword(input: input)
        } catch {
            let mapped = mapError(error)
            authState.error = mapped.localizedDescription
            throw mapped
        }
    }

    func confirmPassword(email: String, code: String, newPassword: String) async throws {
        do {
            let input = ConfirmForgotPasswordInput(
                clientId: clientId,
                confirmationCode: code,
                password: newPassword,
                username: email
            )
            _ = try await cognitoClient.confirmForgotPassword(input: input)
        } catch {
            let mapped = mapError(error)
            authState.error = mapped.localizedDescription
            throw mapped
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        await tokenManager.clearTokens()
        authState.isAuthenticated = false
        authState.userId = nil
        authState.email = nil
        authState.error = nil
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(43)
            .description
    }

    private func generateCodeChallenge(verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> AuthError {
        let message = String(describing: error)
        if message.contains("NotAuthorized") || message.contains("UserNotFound") {
            return .incorrectCredentials
        }
        if message.contains("UserNotConfirmed") {
            return .userNotConfirmed
        }
        if message.contains("PasswordResetRequired") {
            return .passwordResetRequired
        }
        if message.contains("InvalidPassword") {
            return .invalidPassword
        }
        if message.contains("UsernameExists") {
            return .usernameExists
        }
        if message.contains("InvalidParameter") {
            return .invalidParameter
        }
        if message.contains("LimitExceeded") || message.contains("TooManyRequests") {
            return .limitExceeded
        }
        if error is URLError {
            return .networkError
        }
        return .unknown(error.localizedDescription)
    }

    // MARK: - Network Check

    private func isOnline() async -> Bool {
        guard let url = URL(string: "https://cognito-idp.\(AppConfig.cognitoRegion).amazonaws.com") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode != nil
        } catch {
            return false
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
