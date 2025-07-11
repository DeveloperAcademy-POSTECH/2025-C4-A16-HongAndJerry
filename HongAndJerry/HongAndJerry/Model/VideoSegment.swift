//
//  VideoSegment.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//

import AVKit
import Foundation

struct VideoSegment {
    let origin: VideoSource
    let asset: AVAsset
    let trimStartTime: CMTime
    let trimEndTime: CMTime
    let cropX: CGFloat
    let cropY: CGFloat
    let cropWidth: CGFloat
    let cropHeight: CGFloat
}
