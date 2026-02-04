import SwiftUI
import AVKit

struct VideoController: View {
  let isPlaying: Bool
  let currentTime: CMTime
  let totalDuration: CMTime
  let onPlayPause: () -> Void
  let onSeek: (CMTime) -> Void
  let showFullScreenButton: Bool
  let onFullScreenToggle: (() -> Void)?

  @State private var isSeeking = false
  @State private var sliderValue: Double = 0
  @State private var lastSeekTime: TimeInterval = 0

  private let throttleInterval: TimeInterval = 0.1

  init(
    isPlaying: Bool,
    currentTime: CMTime,
    totalDuration: CMTime,
    onPlayPause: @escaping () -> Void,
    onSeek: @escaping (CMTime) -> Void,
    showFullScreenButton: Bool = false,
    onFullScreenToggle: (() -> Void)? = nil
  ) {
    self.isPlaying = isPlaying
    self.currentTime = currentTime
    self.totalDuration = totalDuration
    self.onPlayPause = onPlayPause
    self.onSeek = onSeek
    self.showFullScreenButton = showFullScreenButton
    self.onFullScreenToggle = onFullScreenToggle
  }

  var body: some View {
    HStack(spacing: 15) {
      Button {
        onPlayPause()
      } label: {
        Image(systemName: shouldShowPlayButton ? "play.fill" : "pause.fill")
          .foregroundColor(.white)
          .font(.system(size: 17))
      }
      Text(currentTime.formattedString)
        .font(.caption.monospacedDigit())
        .foregroundColor(.font)
      VideoControlSlider(
        value: $sliderValue,
        range: 0...totalDuration.seconds,
        onEditingChanged: { isEditing in
          self.isSeeking = isEditing
          if !isEditing {
            onSeek(CMTime(seconds: sliderValue, preferredTimescale: 600))
          }
        }
      )
      Text(totalDuration.formattedString)
        .font(.caption.monospacedDigit())
        .foregroundColor(.white)

      if showFullScreenButton, let onFullScreenToggle = onFullScreenToggle {
        Button {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            onFullScreenToggle()
          }
        } label: {
          Image(systemName: "arrow.down.right.and.arrow.up.left")
            .foregroundColor(.white)
            .font(.system(size: 17))
        }
      }
    }
    .padding(.horizontal, 14)
    .onChange(of: currentTime) {
      if !isSeeking {
        sliderValue = currentTime.seconds
      }

      if currentTime.seconds >= totalDuration.seconds - 0.1 && isPlaying {
        onPlayPause()
      }
    }
    .onChange(of: sliderValue) {
      let now = Date.now.timeIntervalSinceReferenceDate
      if now - lastSeekTime > throttleInterval {
        if isSeeking {
          onSeek(CMTime(seconds: sliderValue, preferredTimescale: 600))
          lastSeekTime = now
        }
      }
    }
  }

  private var shouldShowPlayButton: Bool {
    !isPlaying || currentTime.seconds >= totalDuration.seconds - 0.1
  }
}
