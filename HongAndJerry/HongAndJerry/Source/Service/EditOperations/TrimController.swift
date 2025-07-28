//
//  TrimOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

import AVKit
import SwiftUI

struct TrimController {
    func initializeHandleOffsets(
        segmentID: UUID,
        segments: [VideoSegment]
    ) -> (left: CGFloat, right: CGFloat) {
        guard let segment = segments.first(where: { $0.id == segmentID }) else {
            return (left: 0, right: 0)
        }
        
        let newLeftHandleOffset = EditConstants.convertTimeToOffset(segment.startTime)
        let newRightHandleOffset = EditConstants.convertTimeToOffset(segment.startTime + segment.trimmedDuration)
        
        return (left: newLeftHandleOffset, right: newRightHandleOffset)
    }
    
    func dragHandle(
        initialOffsets: (left: CGFloat, right: CGFloat),
        handleType: HandleType,
        translation: CGFloat,
        initialTrackWidth: CGFloat
    ) -> (left: CGFloat, right: CGFloat) {
        let calculatedOffset = calculateHandleOffset(
            handleType: handleType,
            initialOffsets: initialOffsets,
            translation: translation
        )
        
        let constrainedOffset = applyConstraints(
            handleType: handleType,
            calculatedOffset: calculatedOffset,
            initialTrackWidth: initialTrackWidth
        )

        return constrainedOffset
    }
    
    private func calculateHandleOffset(
        handleType: HandleType,
        initialOffsets: (left: CGFloat, right: CGFloat),
        translation: CGFloat
    ) -> (CGFloat, CGFloat) {
        switch handleType {
        case .left:
            return (initialOffsets.left + translation, initialOffsets.right)
            
        case .right:
            return (initialOffsets.left, initialOffsets.right + translation)
            
        case .none:
            return initialOffsets
        }
    }
    
    private func applyConstraints(
        handleType: HandleType,
        calculatedOffset: (left: CGFloat, right: CGFloat),
        initialTrackWidth: CGFloat
    ) -> (left: CGFloat, right: CGFloat) {
        switch handleType {
        case .left:
            let constrainedLeft = max(0, min(calculatedOffset.left, calculatedOffset.right - EditConstants.trackMinimumPixel))
            return (constrainedLeft, calculatedOffset.right)
            
        case .right:
            let constrainedRight = max(calculatedOffset.left + EditConstants.trackMinimumPixel, min(calculatedOffset.right, initialTrackWidth))
            return (calculatedOffset.left, constrainedRight)
            
        case .none:
            return calculatedOffset
        }
    }
}
