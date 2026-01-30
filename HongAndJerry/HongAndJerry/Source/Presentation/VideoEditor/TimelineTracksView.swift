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
            viewModel.handleTimelineScroll(to: offset)
          }
        }
        .onChange(of: viewModel.playerController.isPlaying) { _, isPlaying in
          viewModel.handlePlayingStateChanged(isPlaying: isPlaying)
        }
        .onChange(of: viewModel.playerController.currentTime) { _, _ in
          viewModel.handleCurrentTimeChanged()
        }
        .onAppear { viewModel.updateScreenWidth(geometry.size.width) }
    }
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          if !viewModel.isTimelineDragging {
            viewModel.handleTimelineDragStarted()
          }
          
          viewModel.handleTimelineDragChanged(translation: value.translation.width)
        }
        .onEnded { _ in
          viewModel.handleTimelineDragEnded()
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
  
  @ViewBuilder
  private func audioControlButton(segment: VideoSegment) -> some View {
    Button {
      let operation = AudioOperation(segmentID: segment.id, isMuted: !segment.isMuted)
      
      Task {
        await viewModel.editVideo(operation: operation)
      }
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
