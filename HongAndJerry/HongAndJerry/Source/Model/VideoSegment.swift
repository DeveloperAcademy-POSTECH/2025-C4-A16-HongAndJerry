//
//  VideoSegment.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit

struct VideoSegment {
    let id: UUID = UUID() 
    let source: VideoSource
    let startTime: CMTime
    let trimmedDuration: CMTime
}
