//
//  CropViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/20/25.
//

import Photos
import SwiftUI

@Observable
final class CropViewModel {
    
    enum Action {
        case loadThumbnail
    }
    
    var selectedVideos: [PHAsset]
    var currentIndex = 0
    var thumbnails: [String: UIImage] = [:]
    var isLoading = true
    
    init(selectedVideos: [PHAsset]) {
        self.selectedVideos = selectedVideos
    }
}

extension CropViewModel {
   func loadThumbnails() {
            Task {
                await loadThumbnailsAsync()
            }
        }
        
        @MainActor
        private func loadThumbnailsAsync() async {
            isLoading = true
            
            for video in selectedVideos {
                let thumbnail = await loadSingleThumbnail(for: video)
                if let thumbnail = thumbnail {
                    thumbnails[video.localIdentifier] = thumbnail
                }
            }
            
            isLoading = false
        }
        
        private func loadSingleThumbnail(for video: PHAsset) async -> UIImage? {
            return await withCheckedContinuation { continuation in
                let manager = PHImageManager.default()
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                
                let targetSize = CGSize(width: 500, height: 500)
                
                manager.requestImage(
                    for: video,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                    if !isDegraded {
                        continuation.resume(returning: image)
                    }
                }
            }
        }
}
