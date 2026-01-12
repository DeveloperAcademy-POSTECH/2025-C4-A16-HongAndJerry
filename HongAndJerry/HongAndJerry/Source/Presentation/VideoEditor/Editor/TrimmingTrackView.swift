//
//  TrimmingTrackView.swift
//  HongAndJerry
//
//  Created by Rama on 12/20/25.
//

import SwiftUI
import AVKit

struct TrimmingTrackView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    private let trackWidth: CGFloat = UIScreen.main.bounds.width - 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 1. 전체 비디오 썸네일 트랙
                VideoThumbnailsTrack(
                    segment: currentSegment,
                    trackWidth: trackWidth
                )
                
                // 2. 트리밍 마스크 오버레이 (어두운 영역)
                TrimMaskOverlay(
                    segment: currentSegment,
                    trackWidth: trackWidth
                )
                
                // 3. 핸들들
                TrimHandlesOverlay(
                    segment: currentSegment,
                    trackWidth: trackWidth
                )
                
                // 4. 재생바
                PlayheadIndicator(
                    segment: currentSegment,
                    trackWidth: trackWidth
                )
            }
            .frame(width: trackWidth, height: geometry.size.height)
            .frame(maxWidth: .infinity) // 중앙 정렬
        }
    }
    
    private var currentSegment: VideoSegment? {
        guard let selectedID = viewModel.selectedSegmentID else { return nil }
        return viewModel.segments.first(where: { $0.id == selectedID })
    }
}

// MARK: - 1. 비디오 썸네일 트랙
struct VideoThumbnailsTrack: View {
    let segment: VideoSegment?
    let trackWidth: CGFloat
    
    private var thumbnails: [UIImage] {
        segment?.thumbnails ?? []
    }
    
    private var thumbnailWidth: CGFloat {
        guard !thumbnails.isEmpty else { return trackWidth }
        return trackWidth / CGFloat(thumbnails.count)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(thumbnails.indices, id: \.self) { index in
                Image(uiImage: thumbnails[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbnailWidth, height: 60)
                    .clipped()
            }
        }
        .frame(width: trackWidth, height: 60)
    }
}

// MARK: - 2. 트리밍 마스크 오버레이
struct TrimMaskOverlay: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let segment: VideoSegment?
    let trackWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 왼쪽 어두운 영역
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: leftMaskWidth)
                
                // 오른쪽 어두운 영역
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: rightMaskWidth)
                    .offset(x: trackWidth - rightMaskWidth)
                
                // 트리밍된 영역 테두리 (선택 사항)
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: trimmedWidth)
                    .offset(x: leftMaskWidth)
            }
        }
    }
    
    private var leftMaskWidth: CGFloat {
        guard let segment = segment,
              let offsets = viewModel.segmentHandleOffsets[segment.id] else {
            return 0
        }
        
        let totalDuration = segment.source.duration.seconds
        let startTime = segment.startTime.seconds
        
        return (startTime / totalDuration) * trackWidth
    }
    
    private var rightMaskWidth: CGFloat {
        guard let segment = segment,
              let offsets = viewModel.segmentHandleOffsets[segment.id] else {
            return 0
        }
        
        let totalDuration = segment.source.duration.seconds
        let endTime = segment.endTime.seconds
        
        return ((totalDuration - endTime) / totalDuration) * trackWidth
    }
    
    private var trimmedWidth: CGFloat {
        trackWidth - leftMaskWidth - rightMaskWidth
    }
}

// MARK: - 3. 트리밍 핸들 오버레이
struct TrimHandlesOverlay: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let segment: VideoSegment?
    let trackWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 왼쪽 핸들
                TrimHandleView(type: .left)
                    .offset(x: leftHandleOffset)
                
                // 오른쪽 핸들
                TrimHandleView(type: .right)
                    .offset(x: rightHandleOffset)
            }
        }
    }
    
    private var leftHandleOffset: CGFloat {
        guard let segment = segment,
              let offsets = viewModel.segmentHandleOffsets[segment.id] else {
            return 0
        }
        
        let totalDuration = segment.source.duration.seconds
        let startTime = segment.startTime.seconds
        
        let baseOffset = (startTime / totalDuration) * trackWidth
        
        // 드래그 중이면 translation 추가
        if viewModel.draggingHandleType == .left {
            return baseOffset + viewModel.handleDragTranslation
        }
        
        return baseOffset
    }
    
    private var rightHandleOffset: CGFloat {
        guard let segment = segment,
              let offsets = viewModel.segmentHandleOffsets[segment.id] else {
            return trackWidth
        }
        
        let totalDuration = segment.source.duration.seconds
        let endTime = segment.endTime.seconds
        
        let baseOffset = (endTime / totalDuration) * trackWidth
        
        // 드래그 중이면 translation 추가
        if viewModel.draggingHandleType == .right {
            return baseOffset + viewModel.handleDragTranslation
        }
        
        return baseOffset
    }
}

// MARK: - 핸들 뷰
struct TrimHandleView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let type: HandleType
    
    var body: some View {
        VStack(spacing: 0) {
            // 핸들 상단 (둥근 모서리)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 12, height: 6)
            
            // 핸들 세로 바
            Rectangle()
                .fill(Color.white)
                .frame(width: 4)
            
            // 핸들 하단 (둥근 모서리)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 12, height: 6)
        }
        .frame(height: 60)
        .contentShape(Rectangle().size(width: 44, height: 60)) // 터치 영역 확장
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.onHandleDrag(
                        type: type,
                        translation: value.translation.width
                    )
                }
                .onEnded { _ in
                    Task {
                        await viewModel.onHandleDragEnd()
                    }
                }
        )
    }
}

// MARK: - 4. 재생바 인디케이터
struct PlayheadIndicator: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let segment: VideoSegment?
    let trackWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: geometry.size.height)
                .offset(x: playheadOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewModel.onPlayheadDrag(
                                translation: value.translation.width,
                                trackWidth: trackWidth
                            )
                        }
                        .onEnded { _ in
                            viewModel.onPlayheadDragEnd()
                        }
                )
        }
    }
    
    private var playheadOffset: CGFloat {
        guard let segment = segment else { return 0 }
        
        let currentTime = viewModel.playerController.currentTime.seconds
        let totalDuration = segment.source.duration.seconds
        
        // 현재 재생 시간을 트랙 너비 기준으로 변환
        let normalizedPosition = currentTime / totalDuration
        let offset = normalizedPosition * trackWidth
        
        // 드래그 중이면 translation 추가
        if viewModel.isDraggingPlayhead {
            return offset + viewModel.playheadDragTranslation
        }
        
        return offset
    }
}
