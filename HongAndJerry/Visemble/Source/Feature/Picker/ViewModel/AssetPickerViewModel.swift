import Photos
import SwiftUI
import Foundation
import AVFoundation

@Observable
final class AssetPickerViewModel {
  enum Action {
    case toggleSelection(PHAsset)
    case removeSelection(PHAsset)
  }

  enum VideoDownloadState: Equatable {
    case notStarted
    case downloading(progress: Double)
    case completed(AVAsset)
    case failed(Error)

    static func == (lhs: VideoDownloadState, rhs: VideoDownloadState) -> Bool {
      switch (lhs, rhs) {
      case (.notStarted, .notStarted): return true
      case (.downloading(let p1), .downloading(let p2)): return p1 == p2
      case (.completed, .completed): return true
      case (.failed, .failed): return true
      default: return false
      }
    }
  }

  var videos: [PHAsset] = []
  var selectedVideos: [PHAsset] = []
  var downloadingVideos: [String: VideoDownloadState] = [:]

  private let maxSelection = 3
  private let assetRepository: PHAssetRepository
  private var downloadTasks: [String: Task<Void, Never>] = [:]
  private var downloadRequestIDs: [String: PHImageRequestID] = [:]
  
  var selectedCount: Int {
    selectedVideos.count
  }
  
  var canProceedToEdit: Bool {
    selectedVideos.count == maxSelection
  }
  
  init(
    videos: [PHAsset] = [],
    selectedVideos: [PHAsset] = [],
    assetRepository: PHAssetRepository = PHAssetRepository()
  ) {
    self.videos = videos
    self.selectedVideos = selectedVideos
    self.assetRepository = assetRepository
  }
  
  @MainActor
  func send(_ action: Action) {
    switch action {
    case .toggleSelection(let pHAsset):
      handleToggleSelection(pHAsset)
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
  
  @MainActor
  private func handleToggleSelection(_ asset: PHAsset) {
    let identifier = asset.localIdentifier

    if selectedVideos.contains(where: { $0.localIdentifier == identifier }) {
      selectedVideos.removeAll { $0.localIdentifier == identifier }
      downloadingVideos.removeValue(forKey: identifier)
      return
    }

    if case .downloading = downloadingVideos[identifier] {
      cancelDownload(for: identifier)
      return
    }

    let downloadingCount = downloadingVideos.values.filter { state in
      if case .downloading = state { return true }
      return false
    }.count

    if selectedVideos.count + downloadingCount >= maxSelection {
      return
    }

    startDownload(asset: asset)
  }

  @MainActor
  private func startDownload(asset: PHAsset) {
    let identifier = asset.localIdentifier
    downloadingVideos[identifier] = .downloading(progress: 0)

    let task = Task { @MainActor in
      do {
        let isLocal = await assetRepository.isVideoAvailableLocally(asset: asset)

        try Task.checkCancellation()

        if isLocal {
          let options = PHVideoRequestOptions()
          options.isNetworkAccessAllowed = false
          options.deliveryMode = .highQualityFormat

          let avAsset = try await assetRepository.loadAVAsset(for: asset, options: options)

          try Task.checkCancellation()

          downloadingVideos[identifier] = .completed(avAsset)
          selectedVideos.append(asset)
        } else {
          let avAsset = try await assetRepository.downloadVideo(
            asset: asset,
            progressHandler: { progress in
              Task { @MainActor in
                self.downloadingVideos[identifier] = .downloading(progress: progress)
              }
            },
            requestIDHandler: { requestID in
              Task { @MainActor in
                self.downloadRequestIDs[identifier] = requestID
              }
            }
          )

          try Task.checkCancellation()

          downloadingVideos[identifier] = .completed(avAsset)
          selectedVideos.append(asset)
        }
      } catch is CancellationError {
        downloadingVideos.removeValue(forKey: identifier)
      } catch {
        if !Task.isCancelled {
          downloadingVideos[identifier] = .failed(error)
          print("[AssetPickerViewModel] Failed to download video: \(error)")
        } else {
          downloadingVideos.removeValue(forKey: identifier)
        }
      }

      downloadTasks.removeValue(forKey: identifier)
      downloadRequestIDs.removeValue(forKey: identifier)
    }

    downloadTasks[identifier] = task
  }

  @MainActor
  private func cancelDownload(for identifier: String) {
    downloadTasks[identifier]?.cancel()
    downloadTasks.removeValue(forKey: identifier)

    if let requestID = downloadRequestIDs[identifier] {
      assetRepository.cancelRequest(requestID)
      downloadRequestIDs.removeValue(forKey: identifier)
    }

    downloadingVideos.removeValue(forKey: identifier)
  }

  private func removeVideo(_ video: PHAsset) {
    let videoId = video.localIdentifier
    selectedVideos.removeAll { $0.localIdentifier == videoId }
    downloadingVideos.removeValue(forKey: videoId)
  }
}
