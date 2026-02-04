import AVFoundation

@MainActor
final class AVVideoEditRepository: VideoEditRepository {
  nonisolated init() {}

  func getVideoSize(from asset: AVAsset) async throws -> CGSize {
    guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
      throw AssetError.assetNotFound
    }

    let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
    return CGSize(width: abs(size.width), height: abs(size.height))
  }

  func exportVideoForSave(
    asset: AVAsset,
    videoComposition: AVVideoComposition?,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL {
    guard
      let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPresetHighestQuality
      )
    else {
      throw ExportError.exportSessionCreationFailed
    }

    let tempDirectory = FileManager.default.temporaryDirectory
    let outputURL = tempDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mov
    exportSession.videoComposition = videoComposition

    let progressTask = Task { @MainActor in
      while exportSession.status == .waiting || exportSession.status == .exporting {
        progressHandler(Double(exportSession.progress))
        try? await Task.sleep(nanoseconds: 100_000_000)
      }
      progressHandler(1.0)
    }

    await exportSession.export()

    progressTask.cancel()

    switch exportSession.status {
    case .completed:
      return outputURL
    case .failed:
      throw ExportError.exportFailed(exportSession.error)
    case .cancelled:
      throw ExportError.exportCancelled
    default:
      throw ExportError.unknown
    }
  }
}
