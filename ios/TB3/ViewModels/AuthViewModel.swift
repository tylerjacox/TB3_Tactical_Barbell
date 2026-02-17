// TB3 iOS — Auth ViewModel

import Foundation

@MainActor @Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var verificationCode = ""
    var newPassword = ""
    var localError: String?

    // Flow state
    var needsNewPassword = false
    var showForgotPassword = false
    var showSignUp = false
    var showConfirmEmail = false
    var pendingEmail = "" // email to confirm after signup

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Sign In

    func signIn() async {
        localError = nil
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            localError = "Please enter your email and password."
            return
        }
        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces).lowercased(), password: password)
        } catch {
            localError = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        localError = nil
        do {
            try await authService.signInWithGoogle()
        } catch {
            // User cancelled ASWebAuthenticationSession — ignore
            if (error as NSError).code == 1 { return }
            localError = error.localizedDescription
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedEmail.isEmpty else {
            localError = "Please enter your email."
            return
        }
        guard password.count >= 8 else {
            localError = "Password must be at least 8 characters."
            return
        }
        guard password == confirmPassword else {
            localError = "Passwords don't match."
            return
        }
        do {
            try await authService.signUp(email: trimmedEmail, password: password)
            pendingEmail = trimmedEmail
            showSignUp = false
            showConfirmEmail = true
        } catch {
            localError = error.localizedDescription
        }
    }

    // MARK: - Confirm Email

    func confirmEmail() async {
        localError = nil
        guard !verificationCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter the verification code."
            return
        }
        do {
            try await authService.confirmEmail(email: pendingEmail, code: verificationCode.trimmingCharacters(in: .whitespaces))
            showConfirmEmail = false
            // User can now sign in
        } catch {
            localError = error.localizedDescription
        }
    }

    // MARK: - Forgot Password

    func sendResetCode() async {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedEmail.isEmpty else {
            localError = "Please enter your email."
            return
        }
        do {
            try await authService.forgotPassword(email: trimmedEmail)
            pendingEmail = trimmedEmail
            needsNewPassword = true
        } catch {
            localError = error.localizedDescription
        }
    }

    func confirmNewPassword() async {
        localError = nil
        guard !verificationCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter the verification code."
            return
        }
        guard newPassword.count >= 8 else {
            localError = "Password must be at least 8 characters."
            return
        }
        do {
            try await authService.confirmPassword(
                email: pendingEmail,
                code: verificationCode.trimmingCharacters(in: .whitespaces),
                newPassword: newPassword
            )
            showForgotPassword = false
            needsNewPassword = false
        } catch {
            localError = error.localizedDescription
        }
    }

    // MARK: - Reset

    func resetToLogin() {
        showSignUp = false
        showForgotPassword = false
        showConfirmEmail = false
        needsNewPassword = false
        localError = nil
        password = ""
        confirmPassword = ""
        verificationCode = ""
        newPassword = ""
    }
}
