import Foundation
import AVFoundation
import Photos

@MainActor
@Observable
final class EditUseCase {
    private let compositionRepository: CompositionRepository
    private let cropVideoUseCase: CropVideoUseCase

    var segments: [VideoSegment] = []
    private(set) var currentPlayerItem: AVPlayerItem?

    nonisolated init(
        compositionRepository: CompositionRepository,
        cropVideoUseCase: CropVideoUseCase = CropVideoUseCase(repository: PHImageVideoCropRepository())
    ) {
        self.compositionRepository = compositionRepository
        self.cropVideoUseCase = cropVideoUseCase
    }
  
    func initializeSegments(_ segments: [VideoSegment]) {
        self.segments = segments
    }

    func createSegmentsFromCrops(_ crops: [Crop]) async throws -> [VideoSegment] {
        let croppedAssets = try await cropVideoUseCase.execute(crops: crops)

        var segments: [VideoSegment] = []
        for asset in croppedAssets {
            segments.append(
                VideoSegment(
                    source: VideoSource(
                        asset: asset,
                        url: "",
                        duration: asset.duration
                    )
                )
            )
        }

        self.segments = segments
        return segments
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

    func createTrimmingPlayerItem(for segmentID: UUID) -> AVPlayerItem? {
        guard let segment = segments.first(where: { $0.id == segmentID }) else {
            return nil
        }

        let singlePlayerItem = AVPlayerItem(asset: segment.source.asset)
        let endTime = CMTimeAdd(segment.startTime, segment.trimmedDuration)
        singlePlayerItem.forwardPlaybackEndTime = endTime

        return singlePlayerItem
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
