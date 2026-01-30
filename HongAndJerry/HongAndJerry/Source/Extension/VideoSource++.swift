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
    resourceName: String,
    resourceExtension: String
  ) async throws -> VideoSource {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
      fatalError("Mock video file not found: \(resourceName).\(resourceExtension)")
    }
    
    let asset = AVURLAsset(url: url)
    let duration = try await asset.load(.duration)
    return VideoSource(
      asset: asset,
      url: url.absoluteString,
      duration: duration
    )
  }
}
#endif
