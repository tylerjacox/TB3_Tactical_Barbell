// TB3 iOS — Custom Button Styles
// Press-scale effect for CTA buttons (Begin Set, Complete Set, Start Workout, etc.)

import SwiftUI

/// A button style that adds a subtle scale-down effect on press.
/// Apply to large CTA buttons for tactile visual feedback.
/// **Important:** Background/foreground styling must be applied to the button's label,
/// not as modifiers after `.buttonStyle(.tb3Press)`, to keep the full area tappable.
struct TB3PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TB3PressStyle {
    /// A button style with a subtle scale-down press effect.
    static var tb3Press: TB3PressStyle { TB3PressStyle() }
}
