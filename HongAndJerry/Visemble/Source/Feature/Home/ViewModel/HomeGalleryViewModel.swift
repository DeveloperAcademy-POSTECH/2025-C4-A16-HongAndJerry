import UIKit
import Foundation
import Photos
import AVFoundation

@Observable
final class HomeGalleryViewModel {
  var videos: [VideoAsset] = []
  var selectedAsset: PHAsset?
  var isLoadingVideo = false

  var isEditing = false
  var selectedForDeletion: Set<String> = []

  let playerUseCase = PlayerUseCase()

  var player: AVPlayer {
    playerUseCase.player
  }

  @MainActor
  var isPlaying: Bool {
    playerUseCase.isPlaying
  }

  @MainActor
  var currentTime: CMTime {
    playerUseCase.currentTime
  }

  @MainActor
  var totalDuration: CMTime {
    playerUseCase.totalDuration
  }

  private let assetLoadRepository: AssetLoadRepository

  init(assetLoadRepository: AssetLoadRepository = PHAssetRepository()) {
    self.assetLoadRepository = assetLoadRepository
    requestPermissionAndLoadVideos()
  }
  
  func loadVideos(albumName: String) {
    self.videos = []
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
  
  private func requestPermissionAndLoadVideos() {
    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized || status == .limited {
        self.loadVideos(albumName: "Visemble")
      }
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
    guard let thumbnail = image else { return }
    
    let video = VideoAsset(
      asset: asset,
      thumbnail: thumbnail,
      duration: asset.duration,
      creationDate: asset.creationDate,
      creationTime: asset.creationDate
    )
    Task { @MainActor [weak self] in
      guard let self else { return }
      if !self.videos.contains(where: { $0.asset.localIdentifier == asset.localIdentifier }) {
        self.videos.append(video)
      }
    }
  }

  func selectAsset(_ asset: PHAsset) {
    selectedAsset = asset
    loadVideo(for: asset)
  }

  func closePlayer() {
    selectedAsset = nil
    Task { @MainActor in
      cleanup()
    }
  }

  private func loadVideo(for asset: PHAsset) {
    isLoadingVideo = true

    Task { @MainActor in
      do {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let avAsset = try await assetLoadRepository.loadAVAsset(for: asset, options: options)
        let playerItem = AVPlayerItem(asset: avAsset)
        playerUseCase.replaceCurrentItem(with: playerItem)
        isLoadingVideo = false
      } catch {
        print("[HomeGalleryViewModel] ❌ Failed to load video: \(error)")
        isLoadingVideo = false
      }
    }
  }

  @MainActor
  func play() {
    playerUseCase.play()
  }

  @MainActor
  func pause() {
    playerUseCase.pause()
  }

  @MainActor
  func seek(to time: CMTime) {
    playerUseCase.seek(to: time)
  }

  @MainActor
  func cleanup() {
    playerUseCase.cleanup()
  }

  func toggleEditing() {
    isEditing.toggle()
    if !isEditing {
      selectedForDeletion.removeAll()
    }
  }

  func toggleSelection(for video: VideoAsset) {
    let id = video.asset.localIdentifier
    if selectedForDeletion.contains(id) {
      selectedForDeletion.remove(id)
    } else {
      selectedForDeletion.insert(id)
    }
  }

  func isSelected(_ video: VideoAsset) -> Bool {
    selectedForDeletion.contains(video.asset.localIdentifier)
  }

  func deleteSelectedVideos() {
    let assetsToDelete = videos
      .filter { selectedForDeletion.contains($0.asset.localIdentifier) }
      .map { $0.asset }

    guard !assetsToDelete.isEmpty else { return }

    PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
    } completionHandler: { [weak self] success, error in
      guard let self else { return }
      Task { @MainActor in
        if success {
          self.videos.removeAll { self.selectedForDeletion.contains($0.asset.localIdentifier) }
          self.selectedForDeletion.removeAll()
          self.isEditing = false
        } else if let error {
          print("[HomeGalleryViewModel] ❌ Failed to delete videos: \(error)")
        }
      }
    }
  }
}
