import AVFoundation
import Photos
import SwiftUI

@Observable
final class CropViewModel {
  enum Action {
    case loadVideos
    case goToNextPhoto
    case goToPreviousPhoto
    case setContainerSize(CGSize, at: Int)
    case play
    case pause
    case seek(to: CMTime)
  }

  enum CropState {
    case loading
    case loaded
    case cropping
  }

  var selectedVideos: [PHAsset]
  var currentIndex = 0 {
    didSet {
      if currentIndex != oldValue {
        loadCurrentVideo()
      }
    }
  }
  var isLoading = true
  var state: CropState = .loaded
  var crops: [Crop] = []
  var cropBoxStates: [Int: CropBoxState] = [:]

  let playerUseCase = PlayerUseCase()

  var player: AVPlayer {
    playerUseCase.player
  }

  @MainActor
  var isPlaying: Bool {
    playerUseCase.isPlaying
  }

  @MainActor
  var currentTime: CMTime {
    playerUseCase.currentTime
  }

  @MainActor
  var totalDuration: CMTime {
    playerUseCase.totalDuration
  }

  private let assetLoadRepository: AssetLoadRepository

  init(
    selectedVideos: [PHAsset],
    assetLoadRepository: AssetLoadRepository = PHAssetRepository()
  ) {
    self.selectedVideos = selectedVideos
    self.assetLoadRepository = assetLoadRepository
  }
}

struct CropBoxState {
  var initialRect: CGRect? = nil
  var frameSize: CGSize = .init(width: 1, height: 1)
}

extension CropViewModel {
  func send(_ action: Action) {
    switch action {
    case .loadVideos:
      Task { @MainActor in
        await self.loadAllVideos()
      }
    case .goToNextPhoto:
      if currentIndex < 2 { currentIndex += 1 }
    case .goToPreviousPhoto:
      if currentIndex > 0 { currentIndex -= 1 }
    case .setContainerSize(let size, let index):
      setContainerSize(size, at: index)
    case .play:
      Task { @MainActor in
        playerUseCase.play()
      }
    case .pause:
      Task { @MainActor in
        playerUseCase.pause()
      }
    case .seek(let time):
      Task { @MainActor in
        playerUseCase.seek(to: time)
      }
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
  
  private func setContainerSize(_ size: CGSize, at index: Int) {
    guard index < crops.count else { return }
    crops[index].containerSize = size
  }

  private func loadCurrentVideo() {
    guard currentIndex < selectedVideos.count else { return }
    let video = selectedVideos[currentIndex]

    Task { @MainActor in
      do {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let avAsset = try await assetLoadRepository.loadAVAsset(for: video, options: options)
        let playerItem = AVPlayerItem(asset: avAsset)
        playerUseCase.replaceCurrentItem(with: playerItem)
        isLoading = false
      } catch {
        print("[CropViewModel] ❌ Failed to load video: \(error)")
      }
    }
  }

  @MainActor
  private func loadAllVideos() async {
    guard !selectedVideos.isEmpty else { return }

    crops = selectedVideos.map { video in
      Crop(
        video: video,
        localIdentifier: video.localIdentifier,
        cropRect: .init(x: 0, y: 0, width: 10, height: 10)
      )
    }

    loadCurrentVideo()
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

  @MainActor
  func cleanup() {
    playerUseCase.cleanup()
  }
}
