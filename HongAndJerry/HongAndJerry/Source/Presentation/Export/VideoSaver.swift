//
//  VideoSave.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

final class VideoSaver: VideoSave {

    func save(
        video: AVAsset,
        to album: PHAssetCollection
    ) async throws {
        guard
            let url = (video as? AVURLAsset)?.url
        else { return }

        try await PHPhotoLibrary.shared().performChanges {
            guard
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url),
                let placeholder = assetRequest.placeholderForCreatedAsset,
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            else { return }

            albumChangeRequest.addAssets([placeholder] as NSArray)
        }
    }
}
