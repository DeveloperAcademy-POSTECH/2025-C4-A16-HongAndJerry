import AVFoundation
import Photos

@MainActor
@Observable
final class CropUseCase {
  private let assetLoadRepository: AssetLoadRepository
  private let videoEditRepository: VideoEditRepository

  nonisolated init(
    assetLoadRepository: AssetLoadRepository,
    videoEditRepository: VideoEditRepository
  ) {
    self.assetLoadRepository = assetLoadRepository
    self.videoEditRepository = videoEditRepository
  }

  func execute(crops: [Crop]) async throws -> [AVAsset] {
    let totalStartTime = CFAbsoluteTimeGetCurrent()
    print("🎬 [CropUseCase] Starting crop execution for \(crops.count) videos")

    var exportedAssets: [AVAsset] = []

    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat

    for (index, crop) in crops.enumerated() {
      let videoStartTime = CFAbsoluteTimeGetCurrent()
      print("  📹 [Video \(index + 1)/\(crops.count)] Starting processing")

      let loadStart = CFAbsoluteTimeGetCurrent()
      let originalAsset = try await assetLoadRepository.loadAVAsset(
        for: crop.video,
        options: options
      )
      let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
      print("    ⏱️ Load AVAsset: \(String(format: "%.3f", loadTime))s")

      let sizeStart = CFAbsoluteTimeGetCurrent()
      let videoSize = try await videoEditRepository.getVideoSize(from: originalAsset)
      let sizeTime = CFAbsoluteTimeGetCurrent() - sizeStart
      print("    ⏱️ Get video size: \(String(format: "%.3f", sizeTime))s")

      let rectStart = CFAbsoluteTimeGetCurrent()
      let actualCropRect = convertThumbnailRectToVideoRect(
        thumbnailRect: crop.cropRect,
        thumbnailSize: crop.thumbnail.size,
        containerSize: crop.containerSize,
        videoSize: videoSize
      )
      let rectTime = CFAbsoluteTimeGetCurrent() - rectStart
      print("    ⏱️ Calculate crop rect: \(String(format: "%.3f", rectTime))s")

      let compositionStart = CFAbsoluteTimeGetCurrent()
      let composition = try await videoEditRepository.makeVideoComposition(
        cropRect: actualCropRect,
        asset: originalAsset
      )
      let compositionTime = CFAbsoluteTimeGetCurrent() - compositionStart
      print("    ⏱️ Make composition: \(String(format: "%.3f", compositionTime))s")

      let exportStart = CFAbsoluteTimeGetCurrent()
      let exportedAsset = try await videoEditRepository.exportCroppedVideo(
        asset: originalAsset,
        composition: composition,
        index: index
      )
      let exportTime = CFAbsoluteTimeGetCurrent() - exportStart
      print("    ⏱️ Export video: \(String(format: "%.3f", exportTime))s")

      exportedAssets.append(exportedAsset)

      let videoTotalTime = CFAbsoluteTimeGetCurrent() - videoStartTime
      print("  ✅ [Video \(index + 1)/\(crops.count)] Total: \(String(format: "%.3f", videoTotalTime))s")
    }

    let totalTime = CFAbsoluteTimeGetCurrent() - totalStartTime
    print("🎉 [CropUseCase] Completed all crops in \(String(format: "%.3f", totalTime))s")

    return exportedAssets
  }

  private func convertThumbnailRectToVideoRect(
    thumbnailRect: CGRect,
    thumbnailSize: CGSize,
    containerSize: CGSize,
    videoSize: CGSize
  ) -> CGRect {
    let fittedRect = calculateFittedRect(from: containerSize, imageSize: thumbnailSize)
    let relativeX = thumbnailRect.origin.x - fittedRect.origin.x
    let relativeY = thumbnailRect.origin.y - fittedRect.origin.y
    let scaleX = videoSize.width / fittedRect.width
    let scaleY = videoSize.height / fittedRect.height
    let videoRect = CGRect(
      x: relativeX * scaleX,
      y: relativeY * scaleY,
      width: thumbnailRect.width * scaleX,
      height: thumbnailRect.height * scaleY
    )

    return videoRect
  }

  private func calculateFittedRect(
    from containerSize: CGSize,
    imageSize: CGSize
  ) -> CGRect {
    let containerAspectRatio = containerSize.width / containerSize.height
    let imageAspectRatio = imageSize.width / imageSize.height

    var finalSize: CGSize = .zero
    var origin: CGPoint = .zero

    if containerAspectRatio > imageAspectRatio {
      finalSize.height = containerSize.height
      finalSize.width = imageSize.width * (containerSize.height / imageSize.height)
      origin.x = (containerSize.width - finalSize.width) / 2
      origin.y = 0
    } else {
      finalSize.width = containerSize.width
      finalSize.height = imageSize.height * (containerSize.width / imageSize.width)
      origin.x = 0
      origin.y = (containerSize.height - finalSize.height) / 2
    }

    return CGRect(origin: origin, size: finalSize)
  }
}
