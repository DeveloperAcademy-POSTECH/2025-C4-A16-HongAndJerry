import AVFoundation
import Photos

protocol VideoCropRepository {
  func loadAVAsset(
    for asset: PHAsset,
    options: PHVideoRequestOptions?
  ) async throws -> AVAsset

  func getVideoSize(from asset: AVAsset) async throws -> CGSize

  func makeVideoComposition(
    cropRect: CGRect,
    asset: AVAsset
  ) async throws -> AVVideoComposition

  func exportVideo(
    asset: AVAsset,
    composition: AVVideoComposition,
    index: Int
  ) async throws -> AVAsset
}
