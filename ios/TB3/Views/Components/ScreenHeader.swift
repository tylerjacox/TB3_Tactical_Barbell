// TB3 iOS — Screen Header (matches web .screen-header h1)

import SwiftUI

struct ScreenHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)

            Spacer()

            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}
