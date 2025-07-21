//
//  TrimOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

import AVKit
import SwiftUI

final class TrimOperation: EditOperation {
    var trackWidth: CGFloat = 0
    private var isDragging: Bool = false
    private var handleType: HandleType = .none
    private(set) var screenWidth: CGFloat = 0
    
    var scrollOffset: CGFloat = 0
    var scrollTargetOffset: CGFloat = 0
    private var oldLeftHandleOffset: CGFloat = 0
    private var oldRightHandleOffset: CGFloat = 0
    private var newLeftHandleOffset: CGFloat = 0
    private var newRightHandleOffset: CGFloat = 0
    private var dragDirection: DragDirection = .none
    
    private let pixelsPerSecond: CGFloat = 25.0
    private let trimMinimumDurarion: Double = 1.0
    private var trackMinimumPixel: CGFloat {
        pixelsPerSecond * trimMinimumDurarion
    }
    
    func apply(on segments: [VideoSegment]) async throws -> EditResult {
        // TODO: 실제 트림 로직 구현 필요
        // 현재는 받은 세그먼트를 그대로 반환합니다.
        return .segmentsUpdated(segments)
    }
    
    /// 핸들 드래그 동작을 처리
    /// - Parameters:
    ///   - type: 드래그하는 핸들의 타입 (left/right)
    ///   - translation: 드래그 이동량

    func dragHandle(
        type: HandleType,
        translation: CGFloat
    ) {
        startDrag(type: type)
        
        let newOffset = calculateHandleOffset(
            type: type,
            translation: translation
        )
        
        setHandleOffset(
            type: type,
            offset: newOffset
        )
        
        startAutoScroll()
    }
    
    /// 드래그 시작 시 초기 상태를 설정
    /// - Parameter type: 드래그하는 핸들의 타입
    private func startDrag(type: HandleType) {
        guard !isDragging else { return }
        
        isDragging = true
        handleType = type
        oldLeftHandleOffset = newLeftHandleOffset
        oldRightHandleOffset = newRightHandleOffset
    }
    
    /// 드래그 종료 시 상태를 초기화합니다
    func endDrag() {
        isDragging = false
        handleType = .none
    }
    
    /// 핸들 드래그 후의 새로운 오프셋 값을 계산
    /// - Parameters:
    ///   - type: 핸들 타입
    ///   - translation: 드래그 이동량
    /// - Returns: 계산된 새로운 오프셋 값
    private func calculateHandleOffset(
        type: HandleType,
        translation: CGFloat
    ) -> CGFloat {
        switch type {
        case .left:
            return oldLeftHandleOffset + translation
            
        case .right:
            return oldRightHandleOffset + translation
            
        case .none:
            return 0
        }
    }
    
    /// 핸들의 오프셋을 제약 조건에 맞게 설정
    /// - Parameters:
    ///   - type: 핸들 타입
    ///   - offset: 설정할 오프셋 값
    private func setHandleOffset(
        type: HandleType,
        offset: CGFloat
    ) {
        switch type {
        case .left:
            newLeftHandleOffset = max(0, min(offset, newRightHandleOffset - trackMinimumPixel))
            
        case .right:
            newRightHandleOffset = max(newLeftHandleOffset + trackMinimumPixel, min(newRightHandleOffset, screenWidth))
            
        case .none:
            break
        }
    }
    
    /// 핸들 위치에 따라 자동 스크롤 방향을 결정
    /// - Parameter handleOffset: 현재 핸들의 스크린 상 오프셋 위치
    private func setDragDirection(handleOffset: CGFloat) {
        let leftScrollPoint = scrollOffset + (screenWidth * 0.25)
        let rightScrollPoint = scrollOffset + (screenWidth * 0.75)
        
        if handleOffset <= leftScrollPoint {
            dragDirection = .left
        } else if handleOffset >= rightScrollPoint {
            dragDirection = .right
        } else {
            dragDirection = .none
        }
    }
    
    /// 핸들이 화면 가장자리에 있을 때 자동 스크롤을 시작
    private func startAutoScroll() {
        guard isDragging && dragDirection != .none else { return }
        
        if handleType == .left {
            scrollTargetOffset = scrollOffset
        } else if handleType == .right {
            scrollTargetOffset = scrollOffset + screenWidth
        }
        
        // TODO: View 구현 후 추가할 내용
//        autoScrollTimer?.invalidate()
//        autoScrollTimer = Timer.scheduledTimer(
//            withTimeInterval: 0.016,
//            repeats: true
//        ) { _ in
//            self.onAutoScroll?()
        
    }
}
