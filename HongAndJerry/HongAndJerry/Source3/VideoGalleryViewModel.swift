//
//  VideoGalleryViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/17/25.
//

import Photos
import SwiftUI

class VideoGalleryViewModel: ObservableObject {
    @Published var videos: [PHAsset] = []
    @Published var selectedVideos: [PHAsset] = []
    
    private let maxSelection = 3
    
    func loadVideos() {
        requestPhotoLibraryPermission { granted in
            if granted {
                self.fetchVideos()
            }
        }
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func fetchVideos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        DispatchQueue.main.async {
            self.videos = []
            fetchResult.enumerateObjects { asset, _, _ in
                self.videos.append(asset)
            }
        }
    }
    
    func toggleSelection(_ video: PHAsset) {
        if selectedVideos.contains(video) {
            removeVideo(video)
        } else if selectedVideos.count < maxSelection {
            selectedVideos.append(video)
        }
    }
    
    func removeVideo(_ video: PHAsset) {
        selectedVideos.removeAll { $0 == video }
    }
    
    func getSelectionIndex(for video: PHAsset) -> Int? {
        if let index = selectedVideos.firstIndex(of: video) {
            return index + 1
        }
        return nil
    }
}
