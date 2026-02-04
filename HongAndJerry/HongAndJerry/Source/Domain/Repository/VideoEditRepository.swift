import AVFoundation

protocol VideoEditRepository {
  func getVideoSize(from asset: AVAsset) async throws -> CGSize

  func exportVideoForSave(
    asset: AVAsset,
    videoComposition: AVVideoComposition?,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL
}
