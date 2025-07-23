import SwiftUI
import AVFoundation

/// 타임라인 전체(눈금자, 비디오 트랙들)를 포함하고,
/// 중앙 고정 플레이헤드 방식의 스크롤을 관리하는 컨테이너 뷰입니다.
struct EditorTimelineView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    // --- 상태 변수 ---
    @State private var isDragging = false
    @State private var startDragOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    // --- 상수 ---
    private let pixelsPerSecond: CGFloat = 25.0

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let halfViewWidth = viewWidth / 2
            
            // 스크롤될 타임라인 콘텐츠
            HStack(spacing: 0) {
                // 왼쪽 Spacer: "0s"가 중앙에 올 수 있도록 스크롤 여유 공간을 확보합니다.
                Spacer().frame(width: halfViewWidth)
                
                // 실제 콘텐츠 (눈금자, 트랙 등)
                VStack(alignment: .leading, spacing: 4) { // 트랙 간 간격을 위해 spacing 추가
                    EditorRulerView(pixelsPerSecond: pixelsPerSecond)
                        .frame(height: 40) // 눈금자 뷰의 전체 높이
                        .offset(x: -pixelsPerSecond / 2)
                    
                    // viewModel의 segments 배열을 순회하며 각 트랙을 그립니다.
                    ForEach(viewModel.segments) { segment in
                        VideoTrackView(segment: segment, pixelsPerSecond: pixelsPerSecond)
                    }
                    .clipped()
                }
                
                // 오른쪽 Spacer: 마지막 부분이 중앙에 올 수 있도록 스크롤 여유 공간을 확보합니다.
                Spacer().frame(width: halfViewWidth)
            }
            .offset(x: currentOffset)
            .onChange(of: viewModel.playerController.currentTime) {
                // 사용자가 드래그하고 있지 않을 때만, 재생 시간에 맞춰 타임라인을 자동으로 스크롤합니다.
                if !isDragging {
                    self.currentOffset = -(viewModel.playerController.currentTime.seconds * pixelsPerSecond)
                }
            }
        }
        .contentShape(Rectangle()) // 제스처 인식을 위해 뷰의 모양을 사각형으로 정의합니다.
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startDragOffset = currentOffset
                    }
                    let newOffset = startDragOffset + value.translation.width
                    updateOffset(newOffset)
                }
                .onEnded { _ in isDragging = false }
        )
        .clipped()
    }
    
    /// 새로운 오프셋 값을 계산하고, 경계 체크 후 상태를 업데이트하며, ViewModel의 시간도 업데이트하는 함수
    private func updateOffset(_ newOffset: CGFloat) {
        let totalTimelineWidth = (viewModel.playerController.totalDuration.seconds * pixelsPerSecond)
        
        // 스크롤 가능한 최대/최소 오프셋을 계산합니다.
        let minOffset = -totalTimelineWidth
        let maxOffset: CGFloat = 0
        
        // 오프셋이 경계를 벗어나지 않도록 제한합니다.
        let clampedOffset = min(maxOffset, max(minOffset, newOffset))
        self.currentOffset = clampedOffset
        
        // 사용자가 드래그하는 동안에만 오프셋을 기반으로 시간을 역으로 계산하여 seek합니다.
        if isDragging {
            let newTimeInSeconds = -clampedOffset / pixelsPerSecond
            viewModel.playerController.seek(to: CMTime(seconds: newTimeInSeconds, preferredTimescale: 600))
        }
    }
}
