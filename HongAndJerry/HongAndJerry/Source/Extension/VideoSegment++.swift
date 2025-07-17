//
//  VideoSegment++.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

#if DEBUG
extension VideoSegment {
   static func mock(
       url: String = "mock://video/segment.mp4",
       sourceDuration: TimeInterval = 60,
       startTime: TimeInterval = 0,
       trimmedDuration: TimeInterval = 30
   ) -> VideoSegment {
       let mockSource = VideoSource.mock(
           url: url,
           duration: sourceDuration
       )
       
       return VideoSegment(
           source: mockSource,
           startTime: CMTime(seconds: startTime, preferredTimescale: 600),
           trimmedDuration: CMTime(seconds: trimmedDuration, preferredTimescale: 600)
       )
   }
   
   static func mockList(count: Int = 3) -> [VideoSegment] {
       (0..<count).map { index in
           mock(
               url: "mock://video/segment\(index + 1).mp4",
               sourceDuration: Double(40 + index * 20),
               startTime: Double(index * 2),
               trimmedDuration: Double(15 + index * 5)
           )
       }
   }
}
#endif
