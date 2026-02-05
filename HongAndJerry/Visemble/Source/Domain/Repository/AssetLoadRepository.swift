import AVFoundation
import Photos

protocol AssetLoadRepository {
  func loadAVAsset(
    for asset: PHAsset,
    options: PHVideoRequestOptions?
  ) async throws -> AVAsset
}
