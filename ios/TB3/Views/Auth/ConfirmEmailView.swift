// TB3 iOS — Confirm Email View

import SwiftUI

struct ConfirmEmailView: View {
    @Bindable var vm: AuthViewModel
    @Environment(AppState.self) var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Verify Email")
                    .font(.title.bold())
                    .padding(.top, 40)

                Text("Enter the verification code sent to \(vm.pendingEmail)")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let error = vm.localError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.tb3Error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    TextField("Verification Code", text: $vm.verificationCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.title2.monospaced())
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

                    Button {
                        Task { await vm.confirmEmail() }
                    } label: {
                        Text("Verify")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.authState.isLoading)
                }
                .padding(.horizontal)

                Button("Back to Sign In") {
                    vm.resetToLogin()
                }
                .font(.subheadline)
            }
            .padding(.bottom, 40)
        }
    }
}
