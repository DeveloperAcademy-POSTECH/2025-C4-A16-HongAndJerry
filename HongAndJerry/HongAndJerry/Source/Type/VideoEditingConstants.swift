//
//  VideoEditingConstantes.swift
//  HongAndJerry
//
//  Created by Rama on 7/22/25.
//

import AVKit

struct VideoEditingConstants {
    static let pixelsPerSecond: CGFloat = 25.0
    static let thumbnailHeight: CGFloat = (170.0 - 20) / 3
    static let handleWidth: CGFloat = 10
    static let trimMinimumDuration: Double = 1.0
    static let thumbnailTimeStep: Double = 3.0
    static var trackMinimumPixel: CGFloat {
        VideoEditingConstants.pixelsPerSecond * VideoEditingConstants.trimMinimumDuration
    }
    
    static func convertOffsetToTime(_ offset: CGFloat) -> CMTime {
        let seconds = Double(offset / VideoEditingConstants.pixelsPerSecond)
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
    
    static func convertTimeToOffset(_ time: CMTime) -> CGFloat {
        return CGFloat(time.seconds * Double(VideoEditingConstants.pixelsPerSecond))
    }
}
