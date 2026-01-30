//
//  VideoSaver.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

// TODO: edit
protocol VideoSaving {
  func save(
    video asset: AVAsset,
    videoComposition: AVVideoComposition?,
    to album: PHAssetCollection,
    progressHandler: @escaping (Double) -> Void
  ) async throws
}
