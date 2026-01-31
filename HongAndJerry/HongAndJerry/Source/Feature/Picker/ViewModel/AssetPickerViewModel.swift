import Photos
import SwiftUI
import Foundation

@Observable
final class AssetPickerViewModel {
  enum Action {
    case toggleSelection(PHAsset)
    case removeSelection(PHAsset)
  }
  
  var videos: [PHAsset] = []
  var selectedVideos: [PHAsset] = []
  
  private let maxSelection = 3
  
  var selectedCount: Int {
    selectedVideos.count
  }
  
  var canProceedToEdit: Bool {
    selectedVideos.count == maxSelection
  }
  
  init(
    videos: [PHAsset] = [],
    selectedVideos: [PHAsset] = []
  ) {
    self.videos = videos
    self.selectedVideos = selectedVideos
  }
  
  func send(_ action: Action) {
    switch action {
    case .toggleSelection(let pHAsset):
      toggleSelection(pHAsset)
    case .removeSelection(let pHAsset):
      removeVideo(pHAsset)
    }
  }
  
  func loadVideos() async {
    MediaPermissionUtils.requestPermission { permission in
      if permission == false {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
    }
    await self.fetchVideos()
  }
  
  func getSelectionIndex(for video: PHAsset) -> Int? {
    let videoId = video.localIdentifier
    let index = selectedVideos.firstIndex(where: { $0.localIdentifier == videoId })
    return index.map { $0 + 1 }
  }
  
  private func requestPhotoLibraryPermission() async -> Bool {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized, .limited:
      return true
    case .denied, .restricted:
      return false
    case .notDetermined:
      return await withCheckedContinuation { continuation in
        PHPhotoLibrary.requestAuthorization { newStatus in
          DispatchQueue.main.async {
            continuation.resume(returning: newStatus == .authorized || newStatus == .limited)
          }
        }
      }
    @unknown default:
      return false
    }
  }
  
  @MainActor
  private func fetchVideos() async {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
    let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
    self.videos = []
    fetchResult.enumerateObjects { asset, _, _ in
      self.videos.append(asset)
    }
  }
  
  private func toggleSelection(_ video: PHAsset) {
    let videoId = video.localIdentifier
    if let existingIndex = selectedVideos.firstIndex(where: { $0.localIdentifier == videoId }) {
      selectedVideos.remove(at: existingIndex)
    } else if selectedVideos.count < maxSelection {
      selectedVideos.append(video)
    }
  }
  
  private func removeVideo(_ video: PHAsset) {
    let videoId = video.localIdentifier
    selectedVideos.removeAll { $0.localIdentifier == videoId }
  }
}
