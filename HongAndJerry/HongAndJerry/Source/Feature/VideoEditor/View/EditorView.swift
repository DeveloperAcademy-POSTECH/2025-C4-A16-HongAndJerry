import AVKit
import SwiftUI
import Photos

struct EditorView: View {
  @State private var viewModel: EditorViewModel
  @Namespace private var videoAnimation
  
  init(crops: [Crop]) {
    _viewModel = State(initialValue: EditorViewModel(crops: crops))
  }

  init(segments: [VideoSegment]) {
    _viewModel = State(initialValue: EditorViewModel(segments: segments))
  }
  
  private var currentSegment: VideoSegment? {
    guard let selectedID = viewModel.selectedSegmentID else { return nil }
    return viewModel.segments.first(where: { $0.id == selectedID })
  }
  
  private var snapEndTimes: [Double] {
    guard let selectedID = viewModel.selectedSegmentID else { return [] }
    return viewModel.getSegmentEndTimes(excluding: selectedID)
  }
  
  var body: some View {
    ZStack {
      VStack {
        if viewModel.isFullScreen {
          fullScreenView()
        } else {
          EditorHeaderView()
          previewSection()
          timelineSection()
        }
      }
      .environment(viewModel)
      .navigationBarHidden(true)

      if viewModel.exportIsLoading {
        exportProgressOverlay()
      }
    }
  }

  @ViewBuilder
  private func exportProgressOverlay() -> some View {
    ZStack {
      Color.black.opacity(0.6)
        .ignoresSafeArea()

      HJProgressView(progress: viewModel.exportProgress)
    }
    .allowsHitTesting(true)
  }
  
  @ViewBuilder
  private func fullScreenView() -> some View {
    VStack(spacing: 0) {
      VideoPlayerView()
        .matchedGeometryEffect(id: "videoPlayer", in: videoAnimation)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      FullScreenControlsView()
    }
    .background(Color.black.ignoresSafeArea())
  }
  
  @ViewBuilder
  private func previewSection() -> some View {
    VideoPlayerView()
      .matchedGeometryEffect(id: "videoPlayer", in: videoAnimation)
      .frame(height: UIScreen.main.bounds.height * 0.4)
      .padding(.bottom, 12)

    playbackControlSection()
  }
  
  private func playbackControlSection() -> some View {
    HStack {
      Spacer().frame(width: 20)
      
      Spacer()
      playButton()
      Spacer()
      fullScreenButton()
    }
    .padding(.horizontal, 20)
  }
  
  private func playButton() -> some View {
    Button {
      if viewModel.isPlaying {
        viewModel.pause()
      } else {
        viewModel.play()
      }
    } label: {
      Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
        .font(.system(size: 20))
        .foregroundColor(.white)
    }
  }
  
  private func fullScreenButton() -> some View {
    Button {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
        viewModel.isFullScreen = true
      }
    } label: {
      Image(systemName: "arrow.up.left.and.arrow.down.right")
        .font(.system(size: 20))
        .foregroundColor(.white)
    }
  }
  
  @ViewBuilder
  private func timelineSection() -> some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
          TimelineTracksView()
          playheadView()
          timeDisplayView()
        }
        
        ZStack {
          if viewModel.selectedSegmentID != nil {
            TrimmingTrackViewRepresentable(
              segment: currentSegment,
              snapEndTimes: snapEndTimes,
              shouldShake: viewModel.shouldShakeCheckButton,
              isTrimming: viewModel.isTrimming,
              onTrimStarted: { handleType in
                viewModel.startTrimming(handleType: handleType)
                
                if let offset = viewModel.scrollOffsetForTrimStart() {
                  NotificationCenter.default.post(
                    name: .timelineScrollToOffset,
                    object: offset
                  )
                }
              },
              onTrimChanged: { startTime, endTime, handleType in
                Task {
                  await viewModel.updateTrimRange(start: startTime, end: endTime)
                }
                
                let seekTime = handleType == .left ? startTime : endTime
                viewModel.seek(
                  to: CMTime(seconds: seekTime, preferredTimescale: 600)
                )
              },
              onTrimEnded: {
                viewModel.endTrimming()
              },
              onTrimConfirmed: {
                Task {
                  await viewModel.confirmTrimming()
                }
              }
            )
            .padding(.leading, 12)
            .padding(.trailing, 24)
            .transition(
              .asymmetric(
                insertion: .offset(y: -15).combined(with: .opacity),
                removal: .offset(y: -15).combined(with: .opacity)
              )
            )
          }
        }
        .frame(height: 60)
        .animation(
          .spring(
            response: 0.3,
            dampingFraction: 0.8
          ),
          value: viewModel.selectedSegmentID
        )
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Color.black)
  }
  
  private func timeDisplayView() -> some View {
    Text("\(viewModel.currentTime.formattedString) / \(viewModel.totalDuration.formattedString)")
      .font(.SUITTimer)
      .foregroundColor(.white)
      .frame(height: EditConstants.rulerHeight)
      .background(Rectangle().fill(.black))
      .padding(.leading, 16)
  }
  
  private func playheadView() -> some View {
    Rectangle()
      .fill(.white)
      .frame(width: 2)
      .padding(.vertical, EditConstants.rulerHeight)
      .frame(maxWidth: .infinity)
  }
}
