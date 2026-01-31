import SwiftUI
import AVKit


struct FullScreenControlsView: View {
  @Environment(EditorViewModel.self) private var viewModel
  @State private var isSeeking = false
  @State private var sliderValue: Double = 0
  @State private var lastSeekTime: TimeInterval = 0
  
  private let throttleInterval: TimeInterval = 0.1
  
  var body: some View {
    HStack(spacing: 15) {
      Button {
        if viewModel.isPlaying {
          viewModel.pause()
        } else {
          viewModel.play()
        }
      } label: {
        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
          .foregroundColor(.white)
          .font(.system(size: 17))
      }
      Text(viewModel.currentTime.formattedString)
        .font(.caption.monospacedDigit())
        .foregroundColor(.font)
      Slider(
        value: $sliderValue
        , in: 0...viewModel.totalDuration.seconds
      ) {
        isEditing in
        self.isSeeking = isEditing
        if isEditing {
          viewModel.pause()
        }
      }
      Text(viewModel.totalDuration.formattedString)
        .font(.caption.monospacedDigit())
        .foregroundColor(.white)
      Button {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
          viewModel.isFullScreen = false
        }
      } label: {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
          .foregroundColor(.white)
          .font(.system(size: 17))
      }
    }
    .padding(.horizontal, 14)
    .onChange(of: viewModel.currentTime) {
      if !isSeeking {
        sliderValue = viewModel.currentTime.seconds
      }
    }
    .onChange(of: sliderValue) {
      let now = Date.now.timeIntervalSinceReferenceDate
      if now - lastSeekTime > throttleInterval {
        if isSeeking {
          viewModel.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 600))
          lastSeekTime = now
        }
      }
    }
  }
}
