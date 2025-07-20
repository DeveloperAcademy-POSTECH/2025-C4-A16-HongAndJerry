//
//  VideoSaver.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

protocol VideoSaving {
    func save(video: AVAsset, to album: PHAssetCollection) async throws
}
