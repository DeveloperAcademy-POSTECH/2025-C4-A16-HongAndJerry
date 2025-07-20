//
//  VideoSource++.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

#if DEBUG
extension VideoSource {
   static func mock(
       url: String = "mock://video/source1.mp4",
       duration: TimeInterval = 60
   ) -> VideoSource {
       let mockURL = URL(string: url)!
       let mockAsset = AVURLAsset(url: mockURL)
       return VideoSource(
           asset: mockAsset,
           url: url,
           duration: CMTime(seconds: duration, preferredTimescale: 600)
       )
   }
}
#endif
