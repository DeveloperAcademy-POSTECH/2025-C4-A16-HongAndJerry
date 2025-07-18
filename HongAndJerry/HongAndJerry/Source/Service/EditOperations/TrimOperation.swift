//
//  TrimOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

import AVKit
import SwiftUI

class TrimOperation: EditOperation {
    var isDragging: Bool = false
    var handleType: HandleType = .none
    
    var screenWidth: CGFloat = 0
    var oldLeftHandleOffset: CGFloat = 0
    var oldRightHandleOffset: CGFloat = 0
    var leftHandleOffset: CGFloat = 0
    var rightHandleOffset: CGFloat = 0
    
    let pixelsPerSecond: CGFloat = 25.0
    let trimMinimumDutarion: Double = 1.0
    var trackMinimumPixel: CGFloat {
        pixelsPerSecond * trimMinimumDutarion
    }
    
    var mockSegments: [VideoSegment] {
        VideoSegment.mockList()
    }
    
    func apply(on segments: [VideoSegment]) async throws -> EditResult {
        return .segmentsUpdated(mockSegments)
    }
    
    func dragHandle(type: HandleType, translation: CGFloat) {
        startDrag(type: type)
        
        let newOffset = calculateHandleOffset(
            type: type,
            translation: translation
        )
        setHandleOffset(
            type: type,
            offset: newOffset
        )
    }
    
    private func startDrag(type: HandleType) {
        guard !isDragging else { return }
        
        isDragging = true
        handleType = type
        oldLeftHandleOffset = leftHandleOffset
        oldRightHandleOffset = rightHandleOffset
    }
    
    private func endDrag() {
        isDragging = false
        handleType = .none
    }
    
    private func calculateHandleOffset(
        type: HandleType,
        translation: CGFloat
    ) -> CGFloat {
        switch type {
        case .leftHandle:
            return oldLeftHandleOffset + translation
            
        case .rightHandle:
            return oldRightHandleOffset + translation
            
        case .none:
            return 0
        }
    }
    
    private func setHandleOffset(type: HandleType, offset: CGFloat) {
        switch type {
        case .leftHandle:
            leftHandleOffset = max(0, min(offset, rightHandleOffset - trackMinimumPixel))
            
        case .rightHandle:
            rightHandleOffset = max(0, min(offset, rightHandleOffset - trackMinimumPixel))
            
        case .none:
            break
        }
    }

}
