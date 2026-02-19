// TB3 iOS — Now Playing View (compact Spotify bar for session screen)

import SwiftUI

struct NowPlayingView: View {
    let nowPlaying: SpotifyNowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onToggleLike: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Album art
            if let urlString = nowPlaying?.albumArtURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.tb3Card)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.tb3Card)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(Color.tb3Muted)
                    }
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlaying?.trackName ?? "")
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text(nowPlaying?.artistName ?? "")
                    .font(.caption)
                    .foregroundStyle(Color.tb3Muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Like button
            Button { onToggleLike() } label: {
                Image(systemName: nowPlaying?.isLiked == true ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(nowPlaying?.isLiked == true ? Color(red: 0.12, green: 0.84, blue: 0.38) : Color.tb3Muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(nowPlaying?.isLiked == true ? "Unlike song" : "Like song")

            // Playback controls
            HStack(spacing: 0) {
                Button { onPrevious() } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundStyle(Color.tb3Text)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous track")

                Button { onPlayPause() } label: {
                    Image(systemName: nowPlaying?.isPlaying == true ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(Color.tb3Text)
                        .frame(width: 48, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(nowPlaying?.isPlaying == true ? "Pause" : "Play")

                Button { onNext() } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(Color.tb3Text)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next track")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
