import Foundation
import AVFoundation
import CoreImage

enum CompositionBuildError: Error {
  case failedToCreateVerticalVideoComposition
  case failedToAddTrack
  case noValidTracks
}

enum TrackTypes {
  struct VideoTrackInfo {
    let trackID: CMPersistentTrackID
    let duration: CMTime
    let cropRect: CGRect?
    let preferredTransform: CGAffineTransform
    let naturalSize: CGSize
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
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let naturalSize = try await videoTrack.load(.naturalSize)
        if let compositionTrack = composition.addMutableTrack(
          withMediaType: .video,
          preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
          try compositionTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
          compositionTrack.preferredTransform = .identity
          videoTrackInfos.append(
            TrackTypes.VideoTrackInfo(
              trackID: compositionTrack.trackID,
              duration: timeRange.duration,
              cropRect: segment.cropRect,
              preferredTransform: preferredTransform,
              naturalSize: naturalSize
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
    videoComposition.customVideoCompositorClass = CropCompositor.self

    let slotHeight = renderSize.height / CGFloat(trackInfos.count)

    var slots: [CropCompositionInstruction.SlotInfo] = []

    for (index, trackInfo) in trackInfos.enumerated() {
      let pt = trackInfo.preferredTransform
      let naturalSize = trackInfo.naturalSize
      let transformedSize = CGSize(
        width: abs(naturalSize.applying(pt).width),
        height: abs(naturalSize.applying(pt).height)
      )

      let cropRect = trackInfo.cropRect ?? CGRect(
        x: 0, y: 0,
        width: transformedSize.width,
        height: transformedSize.height
      )

      let slotRect = CGRect(
        x: 0,
        y: CGFloat(index) * slotHeight,
        width: renderSize.width,
        height: slotHeight
      )

      slots.append(CropCompositionInstruction.SlotInfo(
        trackID: trackInfo.trackID,
        cropRect: cropRect,
        preferredTransform: pt,
        naturalSize: naturalSize,
        slotRect: slotRect
      ))
    }

    let instruction = CropCompositionInstruction(
      timeRange: CMTimeRange(start: .zero, duration: totalDuration),
      slots: slots,
      renderSize: renderSize
    )

    videoComposition.instructions = [instruction]

    return videoComposition
  }
}

private final class CropCompositionInstruction: NSObject, @unchecked Sendable, AVVideoCompositionInstructionProtocol {
  var timeRange: CMTimeRange
  var enablePostProcessing: Bool = false
  var containsTweening: Bool = false
  var requiredSourceTrackIDs: [NSValue]?
  var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

  struct SlotInfo {
    let trackID: CMPersistentTrackID
    let cropRect: CGRect
    let preferredTransform: CGAffineTransform
    let naturalSize: CGSize
    let slotRect: CGRect
  }

  let slots: [SlotInfo]
  let renderSize: CGSize

  init(timeRange: CMTimeRange, slots: [SlotInfo], renderSize: CGSize) {
    self.timeRange = timeRange
    self.slots = slots
    self.renderSize = renderSize
    self.requiredSourceTrackIDs = slots.map { slot in
      slot.trackID as NSValue
    }
    super.init()
  }
}

private final class CropCompositor: NSObject, @unchecked Sendable, AVVideoCompositing {
  var sourcePixelBufferAttributes: [String: Any]? {
    [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
  }

  var requiredPixelBufferAttributesForRenderContext: [String: Any] {
    [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
  }

  private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
  private let colorSpace = CGColorSpaceCreateDeviceRGB()

  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    guard let instruction = request.videoCompositionInstruction as? CropCompositionInstruction else {
      request.finish(with: NSError(domain: "CropCompositor", code: -1))
      return
    }

    guard let outputBuffer = request.renderContext.newPixelBuffer() else {
      request.finish(with: NSError(domain: "CropCompositor", code: -2))
      return
    }

    let renderSize = instruction.renderSize
    var outputImage = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: renderSize))

    for slot in instruction.slots {
      guard let sourceBuffer = request.sourceFrame(byTrackID: slot.trackID) else { continue }

      var sourceImage = CIImage(cvPixelBuffer: sourceBuffer)
      let pt = slot.preferredTransform
      let naturalSize = slot.naturalSize

      let transformedSize = CGSize(
        width: abs(naturalSize.applying(pt).width),
        height: abs(naturalSize.applying(pt).height)
      )

      let flipY = CGAffineTransform(scaleX: 1, y: -1)
        .concatenating(CGAffineTransform(translationX: 0, y: naturalSize.height))
      let unflipY = CGAffineTransform(scaleX: 1, y: -1)
        .concatenating(CGAffineTransform(translationX: 0, y: transformedSize.height))

      let ciTransform = flipY.concatenating(pt).concatenating(unflipY)
      sourceImage = sourceImage.transformed(by: ciTransform)

      let cropRect = slot.cropRect
      let ciCropRect = CGRect(
        x: cropRect.origin.x,
        y: transformedSize.height - cropRect.origin.y - cropRect.height,
        width: cropRect.width,
        height: cropRect.height
      )
      sourceImage = sourceImage.cropped(to: ciCropRect)

      let slotRect = slot.slotRect
      let sf = min(slotRect.width / cropRect.width, slotRect.height / cropRect.height)

      let scaledWidth = cropRect.width * sf
      let scaledHeight = cropRect.height * sf
      let offsetX = slotRect.origin.x + (slotRect.width - scaledWidth) / 2
      let offsetY = renderSize.height - slotRect.origin.y - slotRect.height
        + (slotRect.height - scaledHeight) / 2

      sourceImage = sourceImage
        .transformed(by: CGAffineTransform(
          translationX: -sourceImage.extent.origin.x,
          y: -sourceImage.extent.origin.y
        ))
        .transformed(by: CGAffineTransform(scaleX: sf, y: sf))
        .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

      outputImage = sourceImage.composited(over: outputImage)
    }

    ciContext.render(
      outputImage,
      to: outputBuffer,
      bounds: CGRect(origin: .zero, size: renderSize),
      colorSpace: colorSpace
    )

    request.finish(withComposedVideoFrame: outputBuffer)
  }

  func cancelAllPendingVideoCompositionRequests() {}
}
