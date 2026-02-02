import Photos
import AVFoundation

@MainActor
final class PHImageVideoCropRepository: VideoCropRepository {
  private let imageManager: PHImageManager

  nonisolated init(imageManager: PHImageManager = .default()) {
    self.imageManager = imageManager
  }

  func loadAVAsset(
    for asset: PHAsset,
    options: PHVideoRequestOptions?
  ) async throws -> AVAsset {
    let startTime = Date()
    let result: AVAsset = try await withCheckedThrowingContinuation { continuation in
      imageManager.requestAVAsset(
        forVideo: asset,
        options: options
      ) { avAsset, audioMix, info in
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
    return result
  }

  func getVideoSize(from asset: AVAsset) async throws -> CGSize {
    guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
      throw AssetError.assetNotFound
    }

    let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
    return CGSize(width: abs(size.width), height: abs(size.height))
  }

  func makeVideoComposition(
    cropRect: CGRect,
    asset: AVAsset
  ) async throws -> AVVideoComposition {
    guard cropRect.width > 0, cropRect.height > 0 else {
      return AVVideoComposition()
    }

    guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
      throw AssetError.assetNotFound
    }

    let frameRate = try await videoTrack.load(.nominalFrameRate)
    let originalTransform = try await videoTrack.load(.preferredTransform)

    let composition = AVMutableVideoComposition()
    composition.renderSize = cropRect.size
    composition.frameDuration = CMTime(
      value: 1,
      timescale: CMTimeScale(frameRate > 0 ? frameRate : 30)
    )

    let instruction = AVMutableVideoCompositionInstruction()
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let finalTransform = originalTransform.concatenating(
      CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
    )
    layerInstruction.setTransform(finalTransform, at: .zero)

    let duration = try await asset.load(.duration)
    instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
    instruction.layerInstructions = [layerInstruction]
    composition.instructions = [instruction]

    return composition
  }

  func exportVideo(
    asset: AVAsset,
    composition: AVVideoComposition,
    index: Int
  ) async throws -> AVAsset {
    let tempDirectory = FileManager.default.temporaryDirectory
    let outputURL = tempDirectory.appendingPathComponent(
      "croppedVideo_\(index)_\(UUID().uuidString).mov"
    )

    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }

    guard let exportSession = AVAssetExportSession(
      asset: asset,
      presetName: AVAssetExportPresetMediumQuality
    ) else {
      throw AssetError.assetNotFound
    }

    exportSession.videoComposition = composition

    try await exportSession.export(
      to: outputURL,
      as: .mov
    )

    if let error = exportSession.error {
      throw error
    }

    guard exportSession.status == .completed else {
      throw AssetError.assetNotFound
    }

    return AVURLAsset(url: outputURL)
  }
}
