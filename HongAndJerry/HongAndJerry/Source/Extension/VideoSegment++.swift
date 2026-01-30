//
//  VideoSegment++.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

extension VideoSegment: Hashable {
  public static func == (lhs: VideoSegment, rhs: VideoSegment) -> Bool {
    return lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension VideoSegment {
  static func mock(
    resourceName: String,
    resourceExtension: String
  ) async throws -> VideoSegment {
    let mockSource = try await VideoSource.mock(
      resourceName: resourceName,
      resourceExtension: resourceExtension
    )
    
    return VideoSegment(source: mockSource)
  }
  
  static func mockList() async -> [VideoSegment] {
    let videoResources = [
      ("video1", "MOV"),
      ("video2", "MOV"),
      ("video3", "MP4")
    ]
    
    var segments: [VideoSegment] = []
    for (name, ext) in videoResources {
      do {
        let segment = try await mock(resourceName: name, resourceExtension: ext)
        segments.append(segment)
      } catch {
        print("Failed to create mock segment for \(name).\(ext): \(error)")
      }
    }
    return segments
  }
}
