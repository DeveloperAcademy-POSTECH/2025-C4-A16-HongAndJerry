//
//  VideoSource.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

struct VideoSource: Identifiable {
  let id: UUID = UUID()
  let asset: AVAsset
  let url: String
  let duration: CMTime
  
  init(
    asset: AVAsset,
    url: String,
    duration: CMTime
  ) {
    self.asset = asset
    self.url = url
    self.duration = duration
  }
}
