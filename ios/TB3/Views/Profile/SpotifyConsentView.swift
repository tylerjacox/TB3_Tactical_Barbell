// TB3 iOS — Spotify Consent View (shown before OAuth)

import SwiftUI

struct SpotifyConsentView: View {
    let onConnect: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(Color(hex: 0x1DB954))
                Text("Connect to Spotify")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("TB3 will access the following during workouts:")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)

                bulletList([
                    "Current song title, artist, and album art",
                    "Skip to next or previous track",
                ])

                Text("TB3 will NOT:")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
                    .padding(.top, 4)

                bulletList([
                    "Access your playlists or listening history",
                    "Play music or modify your library",
                ])
            }

            Text("Requires Spotify Premium for playback controls. You can disconnect at any time from Settings.")
                .font(.caption)
                .foregroundStyle(Color.tb3Disabled)

            HStack(spacing: 12) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Connect") { onConnect() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x1DB954))
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.tb3Card)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Muted)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding(.leading, 8)
    }
}
