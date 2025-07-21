//
//  HomeViewModel.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import UIKit
import Foundation
import Photos

@Observable
final class AlbumVideoViewModel {
    var videos: [VideoAsset] = []

    init() {
        requestPermissionAndLoadVideos()
    }

    private func requestPermissionAndLoadVideos() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.loadVideos(albumName: "WVDO")
            }
        }
    }
    
    private func loadVideos(albumName: String) {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        collections.enumerateObjects { [weak self] collection, _, _ in
            guard let self else { return }
            guard collection.localizedTitle == albumName else { return }
            self.fetchVideos(collection: collection)
        }
    }

    private func fetchVideos(collection: PHAssetCollection) {
        let assets = PHAsset.fetchAssets(in: collection, options: nil)
        assets.enumerateObjects { [weak self] asset, _, _ in
            guard asset.mediaType == .video else { return }
            guard let self else { return }
            self.requestThumbnail(asset: asset)
        }
    }

    private func requestThumbnail(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let manager = PHImageManager.default()
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 150, height: 150),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self else { return }
            self.fetchImageResult(image: image, asset: asset, info: info)
        }
    }

    private func fetchImageResult(
        image: UIImage?,
        asset: PHAsset,
        info: [AnyHashable: Any]?
    ) {
        guard
            let thumbnail = image
        else { return }

        let video = VideoAsset(
            asset: asset,
            thumbnail: thumbnail,
            duration: asset.duration,
            creationDate: asset.creationDate,
            creationTime: asset.creationDate
        )
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.videos.append(video)
        }
    }
}
