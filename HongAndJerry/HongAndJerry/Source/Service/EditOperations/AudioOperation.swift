//
//  AudioOperation.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/25/25.
//

import AVKit
import SwiftUI

final class AudioOperation: EditOperation {
    private var segmentID: UUID
    private var isMuted: Bool
    
    init(
        segmentID: UUID,
        isMuted: Bool
    ) {
        self.segmentID = segmentID
        self.isMuted = isMuted
    }
    
    func apply(on segments: [VideoSegment]) async throws -> EditResult {
       let newSegments = segments.map { segment in
           if self.segmentID == segment.id {
               segment.isMuted = isMuted
           }
           
           return segment
       }
       
       return .segmentsUpdated(newSegments)
    }
}
