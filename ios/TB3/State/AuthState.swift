// TB3 iOS — Auth State (mirrors services/auth.ts authState signal)

import Foundation

@Observable
final class AuthState {
    var isAuthenticated = false
    var isLoading = true
    var userId: String?
    var email: String?
    var error: String?
}
