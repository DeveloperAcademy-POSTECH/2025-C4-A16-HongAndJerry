//
//  VideoPlayerViewModel.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//

import Foundation
import AVKit

class VideoPlayerViewModel {
    var segments: [VideoSegment];
    
    init(segments: [VideoSegment]) {
        self.segments = segments
    }
}
