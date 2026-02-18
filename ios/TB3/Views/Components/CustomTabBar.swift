// TB3 iOS — Custom Tab Bar (opaque, no iOS 26 floating glass)

import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, iconFilled: String, label: String, tag: Int)] = [
        ("house", "house.fill", "Dashboard", 0),
        ("calendar", "calendar", "Program", 1),
        ("clock", "clock.fill", "History", 2),
        ("person", "person.fill", "Profile", 3),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Color.tb3Border.frame(height: 1)

            HStack {
                ForEach(tabs, id: \.tag) { tab in
                    Button {
                        if selectedTab != tab.tag {
                            // Haptic feedback on tab change
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            selectedTab = tab.tag
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab.tag ? tab.iconFilled : tab.icon)
                                .font(.system(size: 20))
                                .contentTransition(.symbolEffect(.replace))
                            Text(tab.label)
                                .font(.caption2)
                        }
                        .foregroundStyle(selectedTab == tab.tag ? Color.tb3Accent : Color.tb3TabInactive)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                    .accessibilityAddTraits(selectedTab == tab.tag ? .isSelected : [])
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
        }
        .background(Color.tb3Card)
        .padding(.bottom, safeAreaBottom)
        .background(Color.tb3Card)
    }

    private var safeAreaBottom: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
