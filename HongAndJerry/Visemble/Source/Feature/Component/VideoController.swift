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
        if isPlaybackFinished {
          onSeek(CMTime(seconds: 0, preferredTimescale: 600))
          onPlayPause()
        } else {
          onPlayPause()
        }
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

  private var isPlaybackFinished: Bool {
    !isPlaying && currentTime.seconds >= totalDuration.seconds - 0.1
  }

  private var shouldShowPlayButton: Bool {
    !isPlaying || currentTime.seconds >= totalDuration.seconds - 0.1
  }
}

struct VideoControlSlider: UIViewRepresentable {
  @Binding var value: Double
  let range: ClosedRange<Double>
  let onEditingChanged: (Bool) -> Void

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider()
    
    slider.minimumValue = Float(range.lowerBound)
    slider.maximumValue = Float(range.upperBound)
    slider.value = Float(value)

    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.valueChanged(_:)),
      for: .valueChanged
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchDown(_:)),
      for: .touchDown
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchUpInside(_:)),
      for: .touchUpInside
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchUpOutside(_:)),
      for: .touchUpOutside
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchCancel(_:)),
      for: .touchCancel
    )

    return slider
  }

  func updateUIView(_ uiView: UISlider, context: Context) {
    uiView.minimumValue = Float(range.lowerBound)
    uiView.maximumValue = Float(range.upperBound)

    if !context.coordinator.isDragging {
      uiView.value = Float(value)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(value: $value, onEditingChanged: onEditingChanged)
  }

  class Coordinator: NSObject {
    var value: Binding<Double>
    let onEditingChanged: (Bool) -> Void
    var isDragging = false

    init(value: Binding<Double>, onEditingChanged: @escaping (Bool) -> Void) {
      self.value = value
      self.onEditingChanged = onEditingChanged
    }

    @objc func touchDown(_ sender: UISlider) {
      isDragging = true
      onEditingChanged(true)
    }

    @objc func valueChanged(_ sender: UISlider) {
      value.wrappedValue = Double(sender.value)
    }

    @objc func touchUpInside(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }

    @objc func touchUpOutside(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }

    @objc func touchCancel(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }
  }
}
