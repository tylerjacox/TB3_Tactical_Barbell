// TB3 iOS — Sign Up View

import SwiftUI

struct SignUpView: View {
    @Bindable var vm: AuthViewModel
    @Environment(AppState.self) var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Create Account")
                    .font(.title.bold())
                    .padding(.top, 40)

                if let error = vm.localError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.tb3Error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    TextField("Email", text: $vm.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

                    SecureField("Password (min 8 characters)", text: $vm.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

                    SecureField("Confirm Password", text: $vm.confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

                    Button {
                        Task { await vm.signUp() }
                    } label: {
                        if appState.authState.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.authState.isLoading)
                }
                .padding(.horizontal)

                Button("Already have an account? Sign In") {
                    vm.resetToLogin()
                }
                .font(.subheadline)
            }
            .padding(.bottom, 40)
        }
    }
}
