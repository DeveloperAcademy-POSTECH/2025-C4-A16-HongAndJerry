import SwiftUI
import AVFoundation

struct EditorTimelineView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    @State private var isTimelineDragging = false
    @State private var startDragOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var dragDirection: DragDirection = .none
    @State private var lastDragTranslation: CGFloat = 0
    
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var lastHapticSecond: Int = -1

    @State private var gestureVelocity: CGFloat = 0
    @State private var lastDragEvent: (time: Date, translation: CGSize)? = nil

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let halfViewWidth = viewWidth / 2
            
            HStack(spacing: 0) {
                Spacer().frame(width: halfViewWidth)
                
                VStack(alignment: .leading, spacing: 4) {
                    EditorRulerView()
                        .frame(height: EditConstants.rulerHeight)
                        .offset(x: -EditConstants.pixelsPerSecond / 2)
                    
                    ForEach(viewModel.segments) { segment in
                        HStack(spacing: 16) {
                            Button {
                                let operation = AudioOperation(segmentID: segment.id, isMuted: !segment.isMuted)
                                
                                Task {
                                    await viewModel.editVideo(operation: operation)
                                }
                            } label: {
                                Image(systemName:
                                        segment.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
                                )
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            }
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                            
                            VideoTrackView(segment: segment)
                                .clipped()
                        }
                        .offset(x: -45)
                    }
                }
                
                Spacer().frame(width: halfViewWidth)
            }
            .offset(x: currentOffset)
            .onReceive(
                NotificationCenter.default.publisher(for: .timelineScrollToOffset)
            ) { notification in
                if let offset = notification.object as? CGFloat {
                    self.currentOffset = clampOffset(offset)
                }
            }
            .onChange(of: viewModel.playerController.isPlaying) { _, isPlaying in
                if isPlaying && !isTimelineDragging {
                    let currentSeconds = viewModel.playerController.player.currentTime().seconds
                    self.currentOffset = -(currentSeconds * EditConstants.pixelsPerSecond)
                }
            }
            .onChange(of: viewModel.playerController.currentTime) { oldValue, newValue in
                if !isTimelineDragging {
                    checkPlaybackEnd()

                    let isTrimmingRightHandle = viewModel.isTrimming && viewModel.trimmingHandleType == .right
                    if isTrimmingRightHandle {
                        if let selectedID = viewModel.selectedSegmentID,
                           let segment = viewModel.segments.first(where: { $0.id == selectedID }) {
                            let visualRightEnd = viewModel.playerController.currentTime.seconds - segment.startTime.seconds
                            self.currentOffset = -(visualRightEnd * EditConstants.pixelsPerSecond)
                        }
                    } else if viewModel.playerController.isPlaying {
                        let newOffset = -(viewModel.playerController.currentTime.seconds * EditConstants.pixelsPerSecond)
                        self.currentOffset = newOffset
                    }
                }
            }
            .onAppear() {
                viewModel.updateScreenWidth(geometry.size.width)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isTimelineDragging {
                        viewModel.playerController.pause()
                        isTimelineDragging = true
                        startDragOffset = currentOffset
                        lastDragTranslation = 0
                    }

                    let currentTranslation = value.translation.width
                    let delta = currentTranslation - lastDragTranslation

                    if delta > 0 {
                        self.dragDirection = .backward
                    } else if delta < 0 {
                        self.dragDirection = .forward
                    } else {
                        self.dragDirection = .none
                    }

                    self.lastDragTranslation = currentTranslation

                    let newOffset = startDragOffset + currentTranslation
                    updateOffset(newOffset, isDragging: true, direction: self.dragDirection)
                }
                .onEnded { value in
                    isTimelineDragging = false
                    lastHapticSecond = -1
                    lastDragTranslation = 0

                    let clampedProjectedOffset = clampOffset(self.currentOffset)

                    seekToOffset(clampedProjectedOffset, direction: .none)
                }
        )
        .clipped()
    }
    
    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        let maxOffset: CGFloat = 0
        let minOffset: CGFloat

        if let selectedID = viewModel.selectedSegmentID,
           let segment = viewModel.segments.first(where: { $0.id == selectedID }) {
            let trimmedWidth = segment.trimmedDuration.seconds * EditConstants.pixelsPerSecond
            minOffset = -trimmedWidth
        } else {
            let totalTimelineWidth = viewModel.playerController.totalDuration.seconds * EditConstants.pixelsPerSecond
            minOffset = -totalTimelineWidth
        }

        return min(maxOffset, max(minOffset, offset))
    }
    
    private func updateOffset(_ newOffset: CGFloat, isDragging: Bool, direction: DragDirection) {
        let clampedOffset = clampOffset(newOffset)
        self.currentOffset = clampedOffset
        
        if isDragging {
            seekToOffset(clampedOffset, direction: direction)
        }
    }
    
    private func seekToOffset(_ offset: CGFloat, direction: DragDirection) {
        let newTimeInSeconds = -offset / EditConstants.pixelsPerSecond
        let clampedTime = max(0, newTimeInSeconds)

        let currentSecond = Int(clampedTime)
        if currentSecond != lastHapticSecond {
            feedbackGenerator.impactOccurred()
            lastHapticSecond = currentSecond
        }

        viewModel.playerController.seek(to: CMTime(seconds: clampedTime, preferredTimescale: 600), direction: direction)
    }

    private func checkPlaybackEnd() {
        guard viewModel.playerController.isPlaying else { return }

        let currentSeconds = viewModel.playerController.currentTime.seconds
        let threshold = 0.05

        if let selectedID = viewModel.selectedSegmentID,
           let segment = viewModel.segments.first(where: { $0.id == selectedID }) {
            let endTime = segment.startTime.seconds + segment.trimmedDuration.seconds
            if abs(currentSeconds - endTime) < threshold || currentSeconds >= endTime {
                viewModel.playerController.pause()
            }
        }
        else {
            let totalDuration = viewModel.playerController.totalDuration.seconds
            if abs(currentSeconds - totalDuration) < threshold || currentSeconds >= totalDuration {
                viewModel.playerController.pause()
            }
        }
    }
}

extension Notification.Name {
    static let timelineScrollToOffset =
        Notification.Name("timelineScrollToOffset")
}
