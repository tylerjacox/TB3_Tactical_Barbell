// TB3 iOS — Custom Tab Bar (opaque, no iOS 26 floating glass)

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String, tag: Int)] = [
        ("house", "Dashboard", 0),
        ("calendar", "Program", 1),
        ("clock", "History", 2),
        ("person", "Profile", 3),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Color.tb3Border.frame(height: 1)

            HStack {
                ForEach(tabs, id: \.tag) { tab in
                    Button {
                        selectedTab = tab.tag
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.label)
                                .font(.caption2)
                        }
                        .foregroundStyle(selectedTab == tab.tag ? Color.tb3Accent : Color.tb3TabInactive)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
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
