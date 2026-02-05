import AVFoundation
import Photos

struct CropResult {
  let asset: AVAsset
  let cropRect: CGRect
}

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

  func execute(crops: [Crop]) async throws -> [CropResult] {
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat

    let loadedAssets = try await withThrowingTaskGroup(of: (Int, AVAsset).self) { group in
      for (index, crop) in crops.enumerated() {
        group.addTask {
          let asset = try await self.assetLoadRepository.loadAVAsset(
            for: crop.video,
            options: options
          )
          return (index, asset)
        }
      }

      var results = [(Int, AVAsset)]()
      for try await result in group {
        results.append(result)
      }
      return results.sorted { $0.0 < $1.0 }
    }

    var cropResults: [CropResult] = []

    for (index, originalAsset) in loadedAssets {
      let crop = crops[index]
      let videoSize = try await videoEditRepository.getVideoSize(from: originalAsset)

      let actualCropRect = convertContainerRectToVideoRect(
        containerRect: crop.cropRect,
        containerSize: crop.containerSize,
        videoSize: videoSize
      )

      cropResults.append(CropResult(asset: originalAsset, cropRect: actualCropRect))
    }

    return cropResults
  }

  private func convertContainerRectToVideoRect(
    containerRect: CGRect,
    containerSize: CGSize,
    videoSize: CGSize
  ) -> CGRect {
    let fittedRect = calculateFittedRect(from: containerSize, imageSize: videoSize)
    let relativeX = containerRect.origin.x - fittedRect.origin.x
    let relativeY = containerRect.origin.y - fittedRect.origin.y
    let scaleX = videoSize.width / fittedRect.width
    let scaleY = videoSize.height / fittedRect.height
    let videoRect = CGRect(
      x: relativeX * scaleX,
      y: relativeY * scaleY,
      width: containerRect.width * scaleX,
      height: containerRect.height * scaleY
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
