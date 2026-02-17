// TB3 iOS — Login View

import SwiftUI

struct LoginView: View {
    @Bindable var vm: AuthViewModel
    @Environment(AppState.self) var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("TB3")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                    Text("Tactical Barbell Tracker")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Muted)
                }
                .padding(.top, 60)

                // Error
                if let error = vm.localError ?? appState.authState.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.tb3Error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Form
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

                    SecureField("Password", text: $vm.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tb3Border, lineWidth: 1))

                    Button {
                        Task { await vm.signIn() }
                    } label: {
                        if appState.authState.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.authState.isLoading)
                }
                .padding(.horizontal)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color.tb3Border)
                    Text("or").font(.caption).foregroundStyle(Color.tb3Muted)
                    Rectangle().frame(height: 1).foregroundStyle(Color.tb3Border)
                }
                .padding(.horizontal)

                // Google Sign In
                Button {
                    Task { await vm.signInWithGoogle() }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(appState.authState.isLoading)

                // Links
                VStack(spacing: 12) {
                    Button("Forgot Password?") {
                        vm.resetToLogin()
                        vm.showForgotPassword = true
                    }
                    .font(.subheadline)

                    Button("Create Account") {
                        vm.resetToLogin()
                        vm.showSignUp = true
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
    }
}
