import Foundation
import AVFoundation

enum CompositionBuildError: Error {
  case failedToCreateVerticalVideoComposition
  case failedToAddTrack
  case noValidTracks
}

enum TrackTypes {
  struct VideoTrackInfo {
    let trackID: CMPersistentTrackID
    let duration: CMTime
  }

  struct AudioTrackInfo {
    let trackID: CMPersistentTrackID
  }
}

typealias AddTracksResult = (
  video: [TrackTypes.VideoTrackInfo],
  audio: [TrackTypes.AudioTrackInfo]
)

@MainActor
struct AVMutableCompositionRepository: CompositionRepository {
  nonisolated init() {}

  func build(from segments: [VideoSegment]) async throws -> CompositionBuildResult {
    let composition = AVMutableComposition()
    var totalDuration: CMTime = .zero
    
    let (
      video, _
    ) = try await addTracks(
      to: composition,
      from: segments,
      totalDuration: &totalDuration
    )
    
    let videoComposition = try await createVerticalVideoComposition(
      composition: composition,
      trackInfos: video,
      totalDuration: totalDuration
    )
    
    let playerItem = AVPlayerItem(asset: composition)
    playerItem.videoComposition = videoComposition
    
    return CompositionBuildResult(
      playerItem: playerItem,
      totalDuration: totalDuration
    )
  }
  
  private func addTracks(
    to composition: AVMutableComposition,
    from segments: [VideoSegment],
    totalDuration: inout CMTime
  ) async throws -> AddTracksResult {
    var videoTrackInfos: [TrackTypes.VideoTrackInfo] = []
    var audioTrackInfos: [TrackTypes.AudioTrackInfo] = []
    
    for segment in segments {
      let asset = segment.source.asset
      
      let timeRange = CMTimeRange(
        start: segment.startTime,
        duration: segment.trimmedDuration
      )
      
      if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
        if let compositionTrack = composition.addMutableTrack(
          withMediaType: .video,
          preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
          try compositionTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
          videoTrackInfos.append(
            TrackTypes.VideoTrackInfo(
              trackID: compositionTrack.trackID,
              duration: timeRange.duration
            )
          )
        }
      }
      
      if(!segment.isMuted) {
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
          if let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
          ) {
            try compositionTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            audioTrackInfos.append(
              TrackTypes.AudioTrackInfo(
                trackID: compositionTrack.trackID,
              )
            )
          }
        }
      }
      
      totalDuration = max(totalDuration, timeRange.duration)
    }
    
    guard !videoTrackInfos.isEmpty else {
      throw CompositionBuildError.noValidTracks
    }
    
    return (video: videoTrackInfos, audio: audioTrackInfos)
  }
  
  private func createVerticalVideoComposition(
    composition: AVMutableComposition,
    trackInfos: [TrackTypes.VideoTrackInfo],
    totalDuration: CMTime
  ) async throws -> AVMutableVideoComposition {
    let renderSize = CGSize(width: 1080, height: 1821)
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = renderSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
    
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRange(start: .zero, duration: totalDuration)
    
    var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
    let videoHeight = renderSize.height / CGFloat(trackInfos.count)
    
    for (index, trackInfo) in trackInfos.enumerated() {
      
      let trackID = trackInfo.trackID
      let duration = trackInfo.duration
      
      guard let track = composition.track(withTrackID: trackID) else { continue }
      
      let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
      let assetSize = track.naturalSize
      let scaleFactor = renderSize.width / assetSize.width
      let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
      let scaledAssetHeight = assetSize.height * scaleFactor
      let yOffset = (videoHeight - scaledAssetHeight) / 2
      let yPosition = ((CGFloat(index + 1) * videoHeight) + yOffset) - (renderSize.height / 3)
      let moveTransform = CGAffineTransform(translationX: 0, y: yPosition)
      let finalTransform = scaleTransform.concatenating(moveTransform)
      
      layerInstruction.setOpacity(0.0, at: duration)
      layerInstruction.setTransform(finalTransform, at: .zero)
      layerInstructions.append(layerInstruction)
    }
    
    mainInstruction.layerInstructions = layerInstructions.reversed()
    videoComposition.instructions = [mainInstruction]
    
    return videoComposition
  }
}
