//
//  VideoViewModel.swift
//  HongAndJerry
//
//  Created by Gemini on 7/18/25.
//

import AVKit
import Observation

@MainActor
@Observable
final class VideoViewModel {
    var segments: [VideoSegment] = []
    private var playerItem: AVPlayerItem?
    var isLoading: Bool = true
    var isTrimming: Bool = false
    
    var draggingHandleType: HandleType = .none
    var handleDragTranslation: CGFloat = .zero
    var selectedSegmentID: UUID?
    var scrollOffset: CGFloat = 0
    var screenWidth: CGFloat = 0
    
    var isFullScreen: Bool = false
    
    var isDraggingPlayhead: Bool = false
    var playheadDragTranslation: CGFloat = 0
    
    var segmentHandleOffsets: [UUID: (left: CGFloat, right: CGFloat)] = [:]
    
    private var initialLeftHandleOffset: CGFloat = 0
    private var initialRightHandleOffset: CGFloat = 0
    
    let playerController = PlayerController()
    
    private let trimController = TrimController()
    
    private let compositionBuilder = CompositionBuilder()
    
    init(segments: [VideoSegment]) {
        Task {
            self.segments = segments
            await initializePlayer()
        }
    }
    
    private func initializePlayer() async {
        isLoading = true
        
        guard !segments.isEmpty else {
            isLoading = false
            return
        }
        
        setHandleOffsets()
        
        if let firstSegment = segments.first {
            selectSegment(firstSegment.id)
        }
        
        await rebuildPlayerItem()
        isLoading = false
    }
    
    private func rebuildPlayerItem() async {
        do {
            guard !segments.isEmpty else {
                playerController.replaceCurrentItem(with: nil)
                return
            }
            
            let buildResult = try await compositionBuilder.build(from: segments)
            self.playerItem = buildResult.playerItem
            
            playerController.replaceCurrentItem(with: buildResult.playerItem)
        } catch {
            print("Error rebuilding player item: \(error)")
        }
    }
    
    func updateScreenWidth(_ width: CGFloat) {
        screenWidth = width
    }
    
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset - (screenWidth / 2)
    }
    
    func selectSegment(_ segmentID: UUID) {
        selectedSegmentID = segmentID
        guard let offsets = segmentHandleOffsets[segmentID] else {
            initialLeftHandleOffset = 0
            initialRightHandleOffset = 0
            return
        }
        
        initialLeftHandleOffset = offsets.left
        initialRightHandleOffset = offsets.right
    }
    
    private func setHandleOffsets() {
        for segment in segments {
            let offsets = trimController.initializeHandleOffsets(
                segmentID: segment.id,
                segments: segments
            )
            segmentHandleOffsets[segment.id] = offsets
        }
    }
    
    func onHandleDrag(type: HandleType, translation: CGFloat) {
        if draggingHandleType == .none {
            draggingHandleType = type
        }
        handleDragTranslation = translation
        
        guard let selectedID = selectedSegmentID,
              let selectedSegment = segments.first(where: { $0.id == selectedID }) else {
            return
        }
        
        let initialTrackWidth = EditConstants.convertTimeToOffset(selectedSegment.source.duration)
        
        let newOffsets = trimController.dragHandle(
            initialOffsets: (
                left: initialLeftHandleOffset,
                right: initialRightHandleOffset
            ),
            handleType: type,
            translation: translation,
            initialTrackWidth: initialTrackWidth
        )
        
        segmentHandleOffsets[selectedID] = newOffsets
    }
    
    
    func onHandleDragEnd() async {
        guard let selectedID = selectedSegmentID,
              let currentOffsets = segmentHandleOffsets[selectedID] else {
            draggingHandleType = .none
            handleDragTranslation = .zero
            return
        }
        
        let newStartTime = EditConstants.convertOffsetToTime(currentOffsets.left)
        let newDuration = EditConstants.convertOffsetToTime(currentOffsets.right - currentOffsets.left)
        
        let trimOperation = TrimOperation(
            segmentID: selectedID,
            newStartTime: newStartTime,
            newDuration: newDuration
        )
        
        do {
            let result = try await trimOperation.apply(on: segments)
            
            if case .segmentsUpdated(let updatedSegments) = result {
                segments = updatedSegments
            
                await rebuildPlayerItem()
            }
        } catch {
            print("@log - failed Trimming: \(error)")
        }
        
        if let finalOffsets = segmentHandleOffsets[selectedID] {
            initialLeftHandleOffset = finalOffsets.left
            initialRightHandleOffset = finalOffsets.right
        }
        
        draggingHandleType = .none
        handleDragTranslation = .zero
    }
    
    func editVideo(operation: EditOperation) async {
        do {
            // 1. 전달받은 operation을 현재 segments에 적용합니다.
            let result = try await operation.apply(on: segments)
            
            // 2. operation의 실행 결과를 처리합니다.
            switch result {
            case .segmentsUpdated(let updatedSegments):
                // 3. 결과로 받은 segments로 교체합니다.
                self.segments = updatedSegments
                
                // 4. 변경된 segments를 기반으로 플레이어를 다시 빌드합니다.
                await rebuildPlayerItem()
                
            case .exportCompleted(let url):
                // 비디오 익스포트가 완료되었을 때의 로직 (필요시 구현)
                print("Export completed at: \(url)")
                
            case .noChange:
                // 변경 사항이 없을 경우 아무것도 하지 않습니다.
                break
            }
        } catch {
            // operation 적용 중 에러가 발생하면 로그를 출력합니다.
            print("Failed to perform edit operation: \(error)")
        }
    }
    
    func getFinalVideoAsset() -> AVAsset? {
        if let playerItem = self.playerItem {
            return playerItem.asset
        } else {
            return nil
        }
    }
    
    func getFinalVideoComposition() -> AVVideoComposition? {
        if let playerItem = self.playerItem {
            return playerItem.videoComposition
        } else {
            return nil
        }
    }
    
    func activateTrimming(segmentID: UUID) async {
        selectedSegmentID = segmentID
        isTrimming = true
        
        if let segment = segments.first(where: { $0.id == segmentID }) {
            let singlePlayerItem = AVPlayerItem(asset: segment.source.asset)
            playerController.replaceCurrentItem(with: singlePlayerItem)
        }
    }
    
    func confirmTrimming() async {
        await onHandleDragEnd()
        isTrimming = false
        
        await rebuildPlayerItem()
    }
    
    func onPlayheadDrag(translation: CGFloat, trackWidth: CGFloat) {
        isDraggingPlayhead = true
        playheadDragTranslation = translation
        
        guard let selectedID = selectedSegmentID,
              let segment = segments.first(where: { $0.id == selectedID }) else {
            return
        }
        
        // 현재 재생 위치를 기준으로 새로운 시간 계산
        let currentOffset = (playerController.currentTime.seconds / segment.source.duration.seconds) * trackWidth
        let newOffset = currentOffset + translation
        
        // offset을 시간으로 변환
        let newTime = (newOffset / trackWidth) * segment.source.duration.seconds
        
        // 트리밍된 범위 내로 제한
        let clampedTime = max(segment.startTime.seconds, min(newTime, segment.endTime.seconds))
        
        // 플레이어 시간 업데이트
        playerController.seek(to: CMTime(seconds: clampedTime, preferredTimescale: 600))
    }

    func onPlayheadDragEnd() {
        isDraggingPlayhead = false
        playheadDragTranslation = 0
    }
}
