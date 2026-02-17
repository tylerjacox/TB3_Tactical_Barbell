// TB3 iOS — Confirm Dialog Modifier

import SwiftUI

struct ConfirmDialogConfig {
    var title: String
    var message: String
    var confirmLabel: String = "Confirm"
    var cancelLabel: String = "Cancel"
    var isDanger: Bool = false
    var onConfirm: () -> Void = {}
}

struct ConfirmDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let config: ConfirmDialogConfig

    func body(content: Content) -> some View {
        content
            .alert(config.title, isPresented: $isPresented) {
                Button(config.cancelLabel, role: .cancel) {}
                Button(config.confirmLabel, role: config.isDanger ? .destructive : nil) {
                    config.onConfirm()
                }
            } message: {
                Text(config.message)
            }
    }
}

extension View {
    func confirmDialog(isPresented: Binding<Bool>, config: ConfirmDialogConfig) -> some View {
        modifier(ConfirmDialogModifier(isPresented: isPresented, config: config))
    }
}
