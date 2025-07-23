//
//  TrimOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

import AVKit
import SwiftUI

/// 비디오 트림 관련 계산 로직을 담당하는 순수한 유틸리티 컨트롤러
/// 모든 메서드는 입력값을 받아 계산 결과만 반환하는 순수 함수로 구성되어 있습니다
struct TrimController {
    
    /// 세그먼트의 시작 시간과 지속 시간을 기반으로 핸들의 초기 오프셋을 계산합니다.
    /// - Parameters:
    ///   - segmentID: 대상 세그먼트의 고유 식별자
    ///   - segments: 전체 세그먼트 배열
    /// - Returns: (좌측 핸들 오프셋, 우측 핸들 오프셋) 튜플
    func initializeHandleOffsets(
        segmentID: UUID,
        segments: [VideoSegment]
    ) -> (left: CGFloat, right: CGFloat) {
        guard let segment = segments.first(where: { $0.id == segmentID}) else { return (left: 0, right: 0)}
        
        let newLeftHandleOffset = EditConstants.convertTimeToOffset(segment.startTime)
        let newRightHandleOffset = EditConstants.convertTimeToOffset(segment.startTime + segment.trimmedDuration)
        
        return (left: newLeftHandleOffset, right: newRightHandleOffset)
    }
    
    /// 핸들 드래그 시 새로운 오프셋을 계산하고 제약사항을 적용합니다.
    /// - Parameters:
    ///   - oldOffsets: 드래그 시작 시점의 핸들 오프셋
    ///   - handleType: 드래그 중인 핸들 타입 (.left, .right, .none)
    ///   - translation: 드래그로 인한 이동 거리 (픽셀 단위)
    ///   - screenWidth: 화면 너비 (경계 제약사항 적용용)
    /// - Returns: 제약사항이 적용된 새로운 (좌측, 우측) 핸들 오프셋
    func dragHandle(
        oldOffsets: (left: CGFloat, right: CGFloat),
        handleType: HandleType,
        translation: CGFloat,
        screenWidth: CGFloat
    ) -> (left: CGFloat, right: CGFloat) {
        let calculatedOffset = calculateHandleOffset(
            handleType: handleType,
            oldOffsets: oldOffsets,
            translation: translation
        )
        
        let constrainedOffset = applyConstraints(
            handleType: handleType,
            calculatedOffset: calculatedOffset,
            screenWidth: screenWidth
        )

        return constrainedOffset
    }
    
    /// 핸들 타입에 따라 이동 거리를 적용하여 새로운 오프셋을 계산합니다.
    /// - Parameters:
    ///   - handleType: 드래그 중인 핸들 타입
    ///   - oldOffsets: 기존 핸들 오프셋
    ///   - translation: 드래그 이동 거리
    /// - Returns: 계산된 새로운 핸들 오프셋 (제약사항 적용 전)
    private func calculateHandleOffset(
        handleType: HandleType,
        oldOffsets: (left: CGFloat, right: CGFloat),
        translation: CGFloat
    ) -> (CGFloat, CGFloat) {
        switch handleType {
        case .left:
            return (oldOffsets.left + translation, oldOffsets.right)
            
        case .right:
            return (oldOffsets.left, oldOffsets.right + translation)
            
        case .none:
            return oldOffsets
        }
    }
    
    /// 계산된 오프셋에 제약사항을 적용합니다.
    /// 제약사항: 최소 트랙 길이, 화면 경계, 0 이하 방지
    /// - Parameters:
    ///   - handleType: 드래그 중인 핸들 타입
    ///   - calculatedOffset: 제약사항 적용 전 계산된 오프셋
    ///   - screenWidth: 화면 너비 (우측 경계 제한용)
    /// - Returns: 모든 제약사항이 적용된 최종 핸들 오프셋
    private func applyConstraints(
        handleType: HandleType,
        calculatedOffset: (left: CGFloat, right: CGFloat),
        screenWidth: CGFloat
    ) -> (left: CGFloat, right: CGFloat) {
        switch handleType {
        case .left:
            let constrainedLeft = max(0, min(calculatedOffset.left, calculatedOffset.right - EditConstants.trackMinimumPixel))
            return (constrainedLeft, calculatedOffset.right)
            
        case .right:
            let constrainedRight = max(calculatedOffset.left + EditConstants.trackMinimumPixel, min(calculatedOffset.right, screenWidth))
            return (calculatedOffset.left, constrainedRight)
            
        case .none:
            return calculatedOffset
        }
    }
}
