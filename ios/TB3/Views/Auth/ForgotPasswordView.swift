// TB3 iOS — Forgot Password View

import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var vm: AuthViewModel
    @Environment(AppState.self) var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.title.bold())
                    .padding(.top, 40)

                if let error = vm.localError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.tb3Error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if vm.needsNewPassword {
                    // Step 2: Enter code + new password
                    newPasswordForm
                } else {
                    // Step 1: Enter email to receive code
                    emailForm
                }

                Button("Back to Sign In") {
                    vm.resetToLogin()
                }
                .font(.subheadline)
            }
            .padding(.bottom, 40)
        }
    }

    private var emailForm: some View {
        VStack(spacing: 16) {
            Text("Enter your email to receive a reset code.")
                .font(.subheadline)
                .foregroundStyle(Color.tb3Muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Email", text: $vm.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.tb3Card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

            Button {
                Task { await vm.sendResetCode() }
            } label: {
                Text("Send Reset Code")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(appState.authState.isLoading)
        }
        .padding(.horizontal)
    }

    private var newPasswordForm: some View {
        VStack(spacing: 16) {
            Text("Enter the code sent to \(vm.pendingEmail) and your new password.")
                .font(.subheadline)
                .foregroundStyle(Color.tb3Muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Verification Code", text: $vm.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title2.monospaced())
                .padding()
                .background(Color.tb3Card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

            SecureField("New Password (min 8 characters)", text: $vm.newPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color.tb3Card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

            Button {
                Task { await vm.confirmNewPassword() }
            } label: {
                Text("Reset Password")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(appState.authState.isLoading)
        }
        .padding(.horizontal)
    }
}
