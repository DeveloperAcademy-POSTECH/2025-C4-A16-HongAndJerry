import SwiftUI
import AVFoundation

struct TimelineTracksView: View {
  @Environment(EditorViewModel.self) private var viewModel

  var body: some View {
    GeometryReader { geometry in
      let viewWidth = geometry.size.width
      let halfViewWidth = viewWidth / 2

      timelineSection()
        .padding(.horizontal, halfViewWidth)
        .offset(x: viewModel.currentTimelineOffset)
        .onReceive(
          NotificationCenter.default.publisher(for: .timelineScrollToOffset)
        ) { notification in
          if let offset = notification.object as? CGFloat {
            viewModel.send(.timelineScroll(to: offset))
          }
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
          viewModel.send(.playingStateChanged(isPlaying: isPlaying))
        }
        .onChange(of: viewModel.currentTime) { _, _ in
          viewModel.send(.currentTimeChanged)
        }
        .onAppear { viewModel.send(.updateScreenWidth(geometry.size.width)) }
    }
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          if !viewModel.isTimelineDragging {
            viewModel.send(.timelineDragStarted)
          }

          viewModel.send(.timelineDragChanged(translation: value.translation.width))
        }
        .onEnded { _ in
          viewModel.send(.timelineDragEnded)
        }
    )
    .clipped()
  }

  @ViewBuilder
  private func timelineSection() -> some View{
    VStack(alignment: .leading, spacing: 4) {
      TrackRulerView()
        .frame(height: EditConstants.rulerHeight)
        .offset(x: -EditConstants.pixelsPerSecond / 2)

      if viewModel.isLoading && viewModel.segments.isEmpty {
        // Skeleton
        ForEach(0..<3, id: \.self) { _ in
          HStack(spacing: 16) {
            Image(systemName: "speaker.wave.2.fill")
              .font(.system(size: 16))
              .foregroundStyle(.white)
              .frame(width: 30, height: 30)

            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.3))
              .frame(width: 300, height: EditConstants.thumbnailHeight)
          }
          .offset(x: -45)
        }
      } else {
        ForEach(viewModel.segments) { segment in
          HStack(spacing: 16) {
            audioControlButton(segment: segment)

            TrackView(segment: segment)
              .clipped()
          }
          .offset(x: -45)
        }
      }
    }
  }

  @ViewBuilder
  private func audioControlButton(segment: VideoSegment) -> some View {
    Button {
      viewModel.send(.toggleAudioMute(segmentID: segment.id))
    } label: {
      Image(systemName: segment.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
      )
      .font(.system(size: 16))
      .foregroundStyle(.white)
    }
    .frame(width: 30, height: 30)
    .contentShape(Rectangle())
  }
}

extension Notification.Name {
  static let timelineScrollToOffset =
  Notification.Name("timelineScrollToOffset")
}
