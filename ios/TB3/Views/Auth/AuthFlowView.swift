// TB3 iOS — Auth Flow Container (routes between login/signup/confirm/forgot)

import SwiftUI

struct AuthFlowView: View {
    @State private var vm: AuthViewModel

    init(authService: AuthService) {
        _vm = State(initialValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        Group {
            if vm.showConfirmEmail {
                ConfirmEmailView(vm: vm)
            } else if vm.showSignUp {
                SignUpView(vm: vm)
            } else if vm.showForgotPassword {
                ForgotPasswordView(vm: vm)
            } else {
                LoginView(vm: vm)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.showSignUp)
        .animation(.easeInOut(duration: 0.2), value: vm.showForgotPassword)
        .animation(.easeInOut(duration: 0.2), value: vm.showConfirmEmail)
    }
}
