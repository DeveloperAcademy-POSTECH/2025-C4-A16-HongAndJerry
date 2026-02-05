import Foundation
import AVFoundation
import Photos

@MainActor
@Observable
final class EditUseCase {
  private let compositionRepository: CompositionRepository
  
  var segments: [VideoSegment] = []
  private(set) var currentPlayerItem: AVPlayerItem?
  
  nonisolated init(
    compositionRepository: CompositionRepository
  ) {
    self.compositionRepository = compositionRepository
  }
  
  func setSegments(_ segments: [VideoSegment]) {
    self.segments = segments
  }
  
  func initializeSegmentsFromAssets(_ assets: [AVAsset]) {
    self.segments = assets.map { asset in
      VideoSegment(
        source: VideoSource(
          asset: asset,
          url: "",
          duration: asset.duration
        )
      )
    }
  }
  
  func initializeSegmentsFromCropResults(_ cropResults: [CropResult]) {
    self.segments = cropResults.map { result in
      VideoSegment(
        source: VideoSource(
          asset: result.asset,
          url: "",
          duration: result.asset.duration
        ),
        cropRect: result.cropRect
      )
    }
  }
  
  func rebuildPlayerItem() async throws -> AVPlayerItem? {
    guard !segments.isEmpty else {
      currentPlayerItem = nil
      return nil
    }
    
    let buildResult = try await compositionRepository.build(from: segments)
    currentPlayerItem = buildResult.playerItem
    
    return buildResult.playerItem
  }
  
  func toggleAudioMute(segmentID: UUID) async throws -> AVPlayerItem? {
    guard let index = segments.firstIndex(where: { $0.id == segmentID }) else {
      return nil
    }
    
    segments[index].isMuted.toggle()
    return try await rebuildPlayerItem()
  }
  
  func getSegmentCompositionTime(for segmentID: UUID) -> CMTime? {
    var accumulatedTime = CMTime.zero

    for segment in segments {
      if segment.id == segmentID {
        return accumulatedTime
      }
      accumulatedTime = CMTimeAdd(accumulatedTime, segment.trimmedDuration)
    }

    return nil
  }
  
  func updateTrimRange(segmentID: UUID, start: Double, end: Double) {
    guard let index = segments.firstIndex(where: { $0.id == segmentID }) else {
      return
    }
    
    let segment = segments[index]
    let minDuration = 0.5
    
    let clampedStart = max(0, min(start, end - minDuration))
    let clampedEnd = max(clampedStart + minDuration, min(end, segment.source.duration.seconds))
    
    segments[index].startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
    segments[index].trimmedDuration = CMTime(seconds: clampedEnd - clampedStart, preferredTimescale: 600)
  }
  
  func getFinalVideoAsset() -> AVAsset? {
    return currentPlayerItem?.asset
  }
  
  func getFinalVideoComposition() -> AVVideoComposition? {
    return currentPlayerItem?.videoComposition
  }
  
  func getSegmentEndTimes(excluding segmentID: UUID) -> [Double] {
    return segments
      .filter { $0.id != segmentID }
      .map { $0.trimmedDuration.seconds }
  }
}
