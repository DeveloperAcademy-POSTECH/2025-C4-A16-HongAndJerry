//
//  VideoEditingConstantes.swift
//  HongAndJerry
//
//  Created by Rama on 7/22/25.
//

import AVKit

struct EditConstants {
    static let pixelsPerSecond: CGFloat = 25.0
    static let tickHeight: CGFloat = 2
    static let rulerHeight: CGFloat = 40
//    static let thumbnailHeight: CGFloat = (170.0 - 20) / 3
    static let thumbnailHeight = EditConstants.pixelsPerSecond * 3 * (9 / 16)
    static let handleWidth: CGFloat = 5
    static let trimMinimumDuration: Double = 1.0
    static let thumbnailTimeStep: Double = 3.0
    static var trackMinimumPixel: CGFloat {
        EditConstants.pixelsPerSecond * EditConstants.trimMinimumDuration
    }
    
    static func convertOffsetToTime(_ offset: CGFloat) -> CMTime {
        let seconds = Double(offset / EditConstants.pixelsPerSecond)
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
    
    static func convertTimeToOffset(_ time: CMTime) -> CGFloat {
        return CGFloat(time.seconds * Double(EditConstants.pixelsPerSecond))
    }
}
