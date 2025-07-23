//
//  TrimOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

import AVKit
import SwiftUI

final class TrimOperation: EditOperation {
    private var segmentID: UUID
    private var newStartTime: CMTime
    private var newDuration: CMTime
    
    init(
        segmentID: UUID,
        newStartTime: CMTime,
        newDuration: CMTime
    ) {
        self.segmentID = segmentID
        self.newStartTime = newStartTime
        self.newDuration = newDuration
    }
    
    func apply(on segments: [VideoSegment]) async throws -> EditResult {
       let newSegments = segments.map { segment in
           if self.segmentID == segment.id {
               segment.startTime = self.newStartTime
               segment.trimmedDuration = self.newDuration
           }
           
           return segment
       }
       
       return .segmentsUpdated(newSegments)
    }
}
