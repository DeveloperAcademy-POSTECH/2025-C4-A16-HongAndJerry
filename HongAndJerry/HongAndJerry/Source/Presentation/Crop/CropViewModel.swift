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
        case goToNextPhoto
        case goToPreviousPhoto
    }
    
    var selectedVideos: [PHAsset]
    var currentIndex = 0
    var thumbnails: [String: UIImage] = [:]
    var isLoading = true
    
    var crops: [Crop] = []
    
    init(selectedVideos: [PHAsset]) {
        self.selectedVideos = selectedVideos
    }
}

extension CropViewModel {
    
    func send(_ action: Action) {
        
        switch action {
        case .loadThumbnail:
            loadThumbnails()
            
        case .goToNextPhoto:
            if currentIndex < 2 { currentIndex += 1 }
            
        case .goToPreviousPhoto:
            if currentIndex > 0 { currentIndex -= 1 }
        }
    }
    
    private func loadThumbnails() {
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
                crops.append(Crop(localIdentifier: video.localIdentifier, cropRect: .init(x: 0, y: 0, width: 100, height: 100), thumbnail: thumbnail))
            }
        }
        
        isLoading = false   // 로딩이 끝나면 TabView에 이미지 띄움
    }
    
    private func loadSingleThumbnail(for video: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            let targetSize = PHImageManagerMaximumSize // 원본 해상도
            
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
