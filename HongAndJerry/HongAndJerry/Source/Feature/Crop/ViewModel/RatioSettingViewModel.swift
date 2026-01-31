import Photos
import SwiftUI

@Observable
final class RatioSettingViewModel {
  enum Action {
    case loadThumbnail
    case goToNextPhoto
    case goToPreviousPhoto
    case setContainerSize(CGSize, at: Int)
  }
  
  enum VideoState {
    case thumbnailLoading
    case thumbnailLoaded
    case cropping
    case completedConvertToAsset
  }
  
  var selectedVideos: [PHAsset]
  var currentIndex = 0
  var thumbnails: [String: UIImage] = [:]
  var isLoading = true
  var state: VideoState = .thumbnailLoaded
  var crops: [Crop] = []
  var croppedVideos: [(AVAsset, AVVideoComposition)] = []
  var cropBoxStates: [Int: CropBoxState] = [:]
  
  init(selectedVideos: [PHAsset]) {
    self.selectedVideos = selectedVideos
  }
}

struct CropBoxState {
  var initialRect: CGRect? = nil
  var frameSize: CGSize = .init(width: 1, height: 1)
}

extension RatioSettingViewModel {
  func send(_ action: Action) {
    switch action {
    case .loadThumbnail:
      loadThumbnails()
    case .goToNextPhoto:
      if currentIndex < 2 { currentIndex += 1 }
    case .goToPreviousPhoto:
      if currentIndex > 0 { currentIndex -= 1 }
    case .setContainerSize(let size, let index):
      setContainerSize(size, at: index)
    }
  }
  
  func updateCropRect(at index: Int, rect: CGRect) {
    guard index < crops.count else { return }
    crops[index].cropRect = rect
  }
  
  func bindingForCropRect(at index: Int) -> Binding<CGRect> {
    Binding(
      get: {
        guard index < self.crops.count else { return .zero }
        return self.crops[index].cropRect
      },
      set: { newRect in
        self.updateCropRect(at: index, rect: newRect)
      }
    )
  }
  
  func calculate16x9CropRect(in imageSize: CGSize) -> CGRect {
    let aspectRatio: CGFloat = 16.0 / 9.0
    let maxWidth = imageSize.width
    let maxHeight = imageSize.height
    let widthBasedHeight = maxWidth / aspectRatio
    let heightBasedWidth = maxHeight * aspectRatio
    
    let (cropWidth, cropHeight): (CGFloat, CGFloat) = {
      if widthBasedHeight <= maxHeight {
        return (maxWidth, widthBasedHeight)
      } else {
        return (heightBasedWidth, maxHeight)
      }
    }()
    
    let x = (imageSize.width - cropWidth) / 2
    let y = (imageSize.height - cropHeight) / 2
    let rect = CGRect(x: x, y: y, width: cropWidth, height: cropHeight)
    return rect
  }
  
  @MainActor
  func cropVideos() async {
    state = .cropping
    do {
      let exportedAssets = try await PHImageManager.default().exportCroppedVideos(crops: crops)
      croppedVideos = exportedAssets.map { ($0, AVMutableVideoComposition()) }
    } catch {
      if let assetError = error as? AssetError {
        print("AssetError: \(assetError)")
      }
    }
  }
  
  func createVideoSegments() async -> [VideoSegment] {
    var segments: [VideoSegment] = []
    for crop in croppedVideos {
      segments.append(
        VideoSegment(
          source: VideoSource(
            asset: crop.0,
            url: "",
            duration: crop.0.duration
          )
        )
      )
    }
    state = .completedConvertToAsset
    return segments
  }
  
  private func loadThumbnails() {
    Task {
      await loadThumbnailsAsync()
    }
  }
  
  @MainActor
  private func loadThumbnailsAsync() async {
    isLoading = true
    for video in selectedVideos {
      let thumbnail = await loadSingleThumbnail(for: video)
      if let thumbnail = thumbnail {
        thumbnails[video.localIdentifier] = thumbnail
        crops.append(
          Crop(
            video: video,
            localIdentifier: video.localIdentifier,
            cropRect: .init(x: 0, y: 0, width: 10, height: 10),
            thumbnail: thumbnail
          )
        )
      }
    }
    state = .thumbnailLoaded
  }
  
  private func loadSingleThumbnail(for video: PHAsset) async -> UIImage? {
    return await withCheckedContinuation { continuation in
      let manager = PHImageManager.default()
      let options = PHImageRequestOptions()
      options.deliveryMode = .highQualityFormat
      options.isNetworkAccessAllowed = true
      options.isSynchronous = false
      let targetSize = PHImageManagerMaximumSize
      manager.requestImage(
        for: video,
        targetSize: targetSize,
        contentMode: .aspectFill,
        options: options
      ) { image, info in
        let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
        if !isDegraded {
          continuation.resume(returning: image)
        }
      }
    }
  }
  
  private func setContainerSize(_ size: CGSize, at index: Int) {
    guard index < crops.count else { return }
    crops[index].containerSize = size
  }
  
  func getCropBoxState(at index: Int) -> CropBoxState {
    if let state = cropBoxStates[index] {
      return state
    }
    let newState = CropBoxState()
    cropBoxStates[index] = newState
    return newState
  }
  
  func updateCropBoxState(at index: Int, _ update: (inout CropBoxState) -> Void) {
    var state = getCropBoxState(at: index)
    update(&state)
    cropBoxStates[index] = state
  }
  
  func setCropBoxFrameSize(_ size: CGSize, at index: Int) {
    updateCropBoxState(at: index) { state in
      state.frameSize = size
    }
  }
  
  func handleCropBoxDragStarted(at index: Int, currentRect: CGRect) {
    updateCropBoxState(at: index) { state in
      state.initialRect = currentRect
    }
  }
  
  func handleCropBoxDragEnded(at index: Int) {
    updateCropBoxState(at: index) { state in
      state.initialRect = nil
    }
  }
  
  func handleCropBoxDragChanged(
    at index: Int,
    initialRect: CGRect,
    frameSize: CGSize,
    translation: CGSize
  ) -> CGRect {
    return calculateDraggedRect(
      initialRect: initialRect,
      frameSize: frameSize,
      translation: translation
    )
  }
  
  private func calculateDraggedRect(
    initialRect: CGRect,
    frameSize: CGSize,
    translation: CGSize
  ) -> CGRect {
    let maxX = frameSize.width - initialRect.width
    let newX = min(max(initialRect.origin.x + translation.width, 0), maxX)
    let maxY = frameSize.height - initialRect.height
    let newY = min(max(initialRect.origin.y + translation.height, 0), maxY)
    
    return CGRect(
      origin: CGPoint(x: newX, y: newY),
      size: initialRect.size
    )
  }
}
