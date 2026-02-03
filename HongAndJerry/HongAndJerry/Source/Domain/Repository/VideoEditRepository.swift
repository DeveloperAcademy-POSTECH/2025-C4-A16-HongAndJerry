import AVFoundation

protocol VideoEditRepository {
  func getVideoSize(from asset: AVAsset) async throws -> CGSize

  func makeVideoComposition(
    cropRect: CGRect,
    asset: AVAsset
  ) async throws -> AVVideoComposition

  func exportCroppedVideo(
    asset: AVAsset,
    composition: AVVideoComposition,
    index: Int
  ) async throws -> AVAsset

  func exportVideoForSave(
    asset: AVAsset,
    videoComposition: AVVideoComposition?,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL
}
