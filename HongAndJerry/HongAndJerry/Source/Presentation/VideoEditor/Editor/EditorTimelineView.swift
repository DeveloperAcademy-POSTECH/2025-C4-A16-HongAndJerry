import SwiftUI
import AVFoundation

/// 타임라인 전체(눈금자, 비디오 트랙들)를 포함하고,
/// 중앙 고정 플레이헤드 방식의 스크롤을 관리하는 컨테이너 뷰입니다.
struct EditorTimelineView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    // 제스처 상태 관리
    @State private var isTimelineDragging = false
    @State private var isAnimatingScroll = false
    @State private var startDragOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    // 수동 속도 계산을 위한 상태
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
                
                // 오른쪽 Spacer: 마지막 부분이 중앙에 올 수 있도록 스크롤 여유 공간을 확보합니다.
                Spacer().frame(width: halfViewWidth)
            }
            .offset(x: currentOffset)
            .onChange(of: viewModel.playerController.currentTime) {
                // 사용자가 드래그하고 있지 않을 때만, 재생 시간에 맞춰 타임라인을 자동으로 스크롤합니다.
                if !isTimelineDragging {
                    let clampedOffset = clampOffset(self.currentOffset)
                    self.currentOffset = clampedOffset
                }
            }
            .onAppear() {
                viewModel.updateScreenWidth(geometry.size.width)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 드래그 시작 처리
                    if !isTimelineDragging {
                        viewModel.playerController.pause()
                        isTimelineDragging = true
                        startDragOffset = currentOffset
                    }
                    
                    // 오프셋 업데이트
                    let newOffset = startDragOffset + value.translation.width
                    updateOffset(newOffset, isDragging: true)
                }
                .onEnded { value in
                    isTimelineDragging = false
                    
                    let clampedProjectedOffset = clampOffset(self.currentOffset)
                    
                    seekToOffset(clampedProjectedOffset)
                }
        )
        .clipped()
    }
    
    /// 오프셋을 경계 내로 제한하는 함수
    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        let totalTimelineWidth = (viewModel.playerController.totalDuration.seconds * EditConstants.pixelsPerSecond)
        
        // 스크롤 가능한 최대/최소 오프셋을 계산합니다.
        let minOffset = -totalTimelineWidth
        let maxOffset: CGFloat = 0
        return min(maxOffset, max(minOffset, offset))
    }
    
    /// 오프셋을 업데이트하고, 필요한 경우 플레이어 시간을 업데이트하는 함수
    private func updateOffset(_ newOffset: CGFloat, isDragging: Bool) {
        let clampedOffset = clampOffset(newOffset)
        self.currentOffset = clampedOffset
        
        if isDragging {
            seekToOffset(clampedOffset)
        }
    }
    
    /// 주어진 오프셋에 해당하는 시간으로 플레이어를 이동시키는 함수
    private func seekToOffset(_ offset: CGFloat) {
        let newTimeInSeconds = -offset / EditConstants.pixelsPerSecond
        let clampedTime = max(0, newTimeInSeconds)
        viewModel.playerController.seek(to: CMTime(seconds: clampedTime, preferredTimescale: 600))
    }
}
