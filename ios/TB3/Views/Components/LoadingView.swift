// TB3 iOS — Loading View

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("TB3")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.tb3Text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tb3Background)
    }
}

#Preview {
    LoadingView()
}
