import Photos
import AVFoundation

@MainActor
final class PHAssetRepository: AssetLoadRepository, AlbumRepository {
  private let imageManager: PHImageManager

  nonisolated init(imageManager: PHImageManager = .default()) {
    self.imageManager = imageManager
  }

  func loadAVAsset(
    for asset: PHAsset,
    options: PHVideoRequestOptions?
  ) async throws -> AVAsset {
    try await withCheckedThrowingContinuation { continuation in
      imageManager.requestAVAsset(
        forVideo: asset,
        options: options
      ) { avAsset, _, info in
        if let error = info?[PHImageErrorKey] as? Error {
          continuation.resume(throwing: error)
          return
        }
        if let avAsset = avAsset {
          continuation.resume(returning: avAsset)
        } else {
          continuation.resume(throwing: AssetError.assetNotFound)
        }
      }
    }
  }

  func checkAlbum(named title: String) throws -> PHAssetCollection {
    if let existingAlbum = fetchExistingAlbum(title: title) {
      return existingAlbum
    }
    return try createAlbum(title: title)
  }

  func saveVideoToAlbum(at fileURL: URL, to album: PHAssetCollection) async throws {
    try await PHPhotoLibrary.shared().performChanges {
      guard
        let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(
          atFileURL: fileURL
        ),
        let placeholder = assetRequest.placeholderForCreatedAsset,
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
      else { return }

      albumChangeRequest.addAssets([placeholder] as NSArray)
    }
  }

  private func fetchExistingAlbum(title: String) -> PHAssetCollection? {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "title = %@", title)
    return PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .any,
      options: options
    ).firstObject
  }

  private func createAlbum(title: String) throws -> PHAssetCollection {
    let identifier = try performAlbumCreation(title: title)
    return try fetchAlbum(with: identifier)
  }

  private func performAlbumCreation(title: String) throws -> String {
    var placeholder: PHObjectPlaceholder?

    try PHPhotoLibrary.shared().performChangesAndWait {
      let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
        withTitle: title
      )
      placeholder = request.placeholderForCreatedAssetCollection
    }

    guard let id = placeholder?.localIdentifier else {
      throw AlbumError.albumCreateError
    }

    return id
  }

  private func fetchAlbum(with identifier: String) throws -> PHAssetCollection {
    guard
      let album = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [identifier],
        options: nil
      ).firstObject
    else {
      throw AlbumError.albumFetchError
    }

    return album
  }
}
