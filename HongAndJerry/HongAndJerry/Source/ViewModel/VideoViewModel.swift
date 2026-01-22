//
//  VideoViewModel.swift
//  HongAndJerry
//
//  Created by Gemini on 7/18/25.
//

import AVKit
import Observation

@MainActor
@Observable
final class VideoViewModel {
    var segments: [VideoSegment] = []
    private var playerItem: AVPlayerItem?
    var isLoading: Bool = true
    var isTrimming: Bool = false
    var trimmingHandleType: HandlesView.HandleType?
    var selectedSegmentID: UUID?
    var screenWidth: CGFloat = 0
    var shouldShakeCheckButton: Bool = false

    var isFullScreen: Bool = false
    
    let playerController = PlayerController()
    
    private let compositionBuilder = CompositionBuilder()

    init(segments: [VideoSegment]) {
        Task {
            self.segments = segments
            await initializePlayer()
        }
    }

    private func initializePlayer() async {
        isLoading = true

        guard !segments.isEmpty else {
            isLoading = false
            return
        }

        await rebuildPlayerItem()
        isLoading = false
    }

    private func rebuildPlayerItem() async {
        do {
            guard !segments.isEmpty else {
                playerController.replaceCurrentItem(with: nil)
                return
            }

            let buildResult = try await compositionBuilder.build(from: segments)
            self.playerItem = buildResult.playerItem

            playerController.replaceCurrentItem(with: buildResult.playerItem)
        } catch {
            print("Error rebuilding player item: \(error)")
        }
    }
    
    func updateScreenWidth(_ width: CGFloat) {
        screenWidth = width
    }
    
    func editVideo(operation: EditOperation) async {
        do {
            let result = try await operation.apply(on: segments)
            
            switch result {
            case .segmentsUpdated(let updatedSegments):
                self.segments = updatedSegments
                await rebuildPlayerItem()
                
            case .exportCompleted(let url):
                print("Export completed at: \(url)")
                
            case .noChange:
                break
            }
        } catch {
            print("Failed to perform edit operation: \(error)")
        }
    }
    
    func getFinalVideoAsset() -> AVAsset? {
        if let playerItem = self.playerItem {
            return playerItem.asset
        } else {
            return nil
        }
    }
    
    func getFinalVideoComposition() -> AVVideoComposition? {
        if let playerItem = self.playerItem {
            return playerItem.videoComposition
        } else {
            return nil
        }
    }
    
    func activateTrimming(segmentID: UUID) async {
        if isTrimming, let currentSelectedID = selectedSegmentID, currentSelectedID != segmentID {
            triggerCheckButtonShake()
            return
        }

        selectedSegmentID = segmentID

        if let segment = segments.first(where: { $0.id == segmentID }) {
            let singlePlayerItem = AVPlayerItem(asset: segment.source.asset)
            let endTime = CMTimeAdd(segment.startTime, segment.trimmedDuration)
            singlePlayerItem.forwardPlaybackEndTime = endTime

            playerController.replaceCurrentItem(with: singlePlayerItem)
            playerController.pause()
        }
    }

    func triggerCheckButtonShake() {
        shouldShakeCheckButton = true

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            shouldShakeCheckButton = false
        }
    }

    func startTrimming(handleType: HandlesView.HandleType) {
        isTrimming = true
        trimmingHandleType = handleType
    }

    func endTrimming() {
        trimmingHandleType = nil
    }

    func confirmTrimming() async {
        isTrimming = false
        trimmingHandleType = nil
        selectedSegmentID = nil

        await rebuildPlayerItem()
    }
    
    func updateTrimRange(start: Double, end: Double) async {
        guard let selectedID = selectedSegmentID,
              let index = segments.firstIndex(where: { $0.id == selectedID }) else { return }
        
        let segment = segments[index]
        let clampedStart = max(0, min(start, end - TrimmingConstants.minTrimDuration))
        let clampedEnd = max(clampedStart + TrimmingConstants.minTrimDuration, min(end, segment.source.duration.seconds))
        
        segments[index].startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
        segments[index].trimmedDuration = CMTime(seconds: clampedEnd - clampedStart, preferredTimescale: 600)
    }
    
    func scrollOffsetForTrimStart() -> CGFloat? {
        guard
            let handleType = trimmingHandleType,
            let selectedID = selectedSegmentID,
            let segment = segments.first(where: { $0.id == selectedID })
        else { return nil }

        switch handleType {
        case .left:
            return 0

        case .right:
            let visualRightEnd =
                segment.startTime.seconds + segment.trimmedDuration.seconds
            return -(visualRightEnd * EditConstants.pixelsPerSecond)
        }
    }

    func getSegmentEndTimes(excluding segmentID: UUID) -> [Double] {
        segments
            .filter { $0.id != segmentID }
            .map { $0.trimmedDuration.seconds }
    }
}
