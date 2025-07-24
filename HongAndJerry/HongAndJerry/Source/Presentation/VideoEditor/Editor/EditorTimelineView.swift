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
                .frame(alignment: .leading)
            }
            .offset(x: currentOffset)
            .onChange(of: viewModel.playerController.currentTime) {
                if !isTimelineDragging && !isAnimatingScroll {
                    self.currentOffset = -(viewModel.playerController.currentTime.seconds * EditConstants.pixelsPerSecond)
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
                    // 진행 중인 관성 애니메이션 중단
                    if isAnimatingScroll {
                        isAnimatingScroll = false
                        self.currentOffset = self.currentOffset
                    }
                    
                    // 드래그 시작 처리
                    if !isTimelineDragging {
                        isTimelineDragging = true
                        startDragOffset = currentOffset
                        lastDragEvent = (time: value.time, translation: value.translation)
                    }
                    
                    // 속도 계산
                    if let last = lastDragEvent {
                        let timeInterval = value.time.timeIntervalSince(last.time)
                        if timeInterval > 0 {
                            let distance = value.translation.width - last.translation.width
                            self.gestureVelocity = distance / timeInterval // 단위: points/sec
                        }
                    }
                    self.lastDragEvent = (time: value.time, translation: value.translation)
                    
                    // 오프셋 업데이트
                    let newOffset = startDragOffset + value.translation.width
                    updateOffset(newOffset, isDragging: true)
                }
                .onEnded { value in
                    isTimelineDragging = false
                    
                    // 손가락을 떼기 전 잠시 멈췄는지 확인
                    let timeSinceLastDrag = value.time.timeIntervalSince(lastDragEvent?.time ?? value.time)
                    if timeSinceLastDrag > 0.05 { // 50ms 이상 움직임이 없으면 속도 0으로 처리
                        self.gestureVelocity = 0
                    }
                    self.lastDragEvent = nil // 상태 초기화
                    
                    // 계산된 속도를 기반으로 관성 적용
                    let projectedOffset = self.currentOffset + self.gestureVelocity * 0.4 // 관성 강도 조절
                    let clampedProjectedOffset = clampOffset(projectedOffset)
                    
                    // 속도에 기반해 애니메이션 시간 동적 조절
                    // 최소 0.5초, 최대 7초로 변경하여 관성 효과를 더 길게 유지
                    let animationDuration = min(max(abs(self.gestureVelocity) / 1000, 0.5), 7.0)
                    
                    // 관성 스크롤 애니메이션 시작
                    isAnimatingScroll = true
                    withAnimation(.easeOut(duration: animationDuration)) {
                        self.currentOffset = clampedProjectedOffset
                    }
                    
                    seekToOffset(clampedProjectedOffset)
                    
                    // 애니메이션이 끝나는 시점에 상태를 재설정합니다.
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        // 애니메이션이 끝난 후에도 사용자가 드래그를 시작하지 않았을 경우에만 상태를 변경합니다.
                        if !isTimelineDragging {
                            isAnimatingScroll = false
                        }
                    }
                }
        )
        .clipped()
    }
    
    /// 오프셋을 경계 내로 제한하는 함수
    private func clampOffset(_ offset: CGFloat) -> CGFloat {
        let totalTimelineWidth = (viewModel.playerController.totalDuration.seconds * EditConstants.pixelsPerSecond)
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
