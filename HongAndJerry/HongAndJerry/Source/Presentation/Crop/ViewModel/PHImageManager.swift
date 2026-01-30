//
//  PHImageManager.swift
//  HongAndJerry
//
//  Created by Soop on 7/23/25.
//

import Photos
import AVFoundation

// TODO: edit

extension PHImageManager {
  func requestAVAssetAsync(
    for asset: PHAsset,
    options: PHVideoRequestOptions? = nil
  ) async throws -> AVAsset {
    try await withCheckedThrowingContinuation { continuation in
      self.requestAVAsset(
        forVideo: asset,
        options: options
      ) { avAsset, audioMix, info in
        if let error = info?[PHImageErrorKey] as? Error {
          continuation.resume(throwing: AssetError.infoNotFound)
          return
        }
        if let avAsset = avAsset {
          continuation.resume(returning: avAsset)
        } else {
          continuation.resume(throwing: AssetError.assetNotFound)
        }
      }
    }
  }
  
  func convertThumbnailRectToVideoRect(
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
  
  func makeCroppedVideoComposition(
    crop: CGRect,
    asset: AVAsset
  ) async throws -> AVVideoComposition {
    guard crop.width > 0, crop.height > 0 else {
      return AVVideoComposition()
    }
    guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
      throw AssetError.assetNotFound
    }
    let frameRate = try await videoTrack.load(.nominalFrameRate)
    let originalTransform = try await videoTrack.load(.preferredTransform)
    
    let composition = AVMutableVideoComposition()
    composition.renderSize = crop.size
    composition.frameDuration = CMTime(
      value: 1,
      timescale: CMTimeScale(frameRate > 0 ? frameRate : 30)
    )
    
    let instruction = AVMutableVideoCompositionInstruction()
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let finalTransform = originalTransform.concatenating(
      CGAffineTransform(translationX: -crop.origin.x, y: -crop.origin.y)
    )
    layerInstruction.setTransform(finalTransform, at: .zero)
    
    let duration = try await asset.load(.duration)
    instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
    instruction.layerInstructions = [layerInstruction]
    composition.instructions = [instruction]
    
    return composition
  }
  
  func exportCroppedVideos(crops: [Crop]) async throws -> [AVAsset] {
    var exportedAssets: [AVAsset] = []
    
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    
    for (index, crop) in crops.enumerated() {
      print("🎬 처리 시작 idx:\(index)")
      
      let originalAsset = try await self.requestAVAssetAsync(
        for: crop.video,
        options: options
      )
      
      let videoSize = try await self.getVideoSize(from: originalAsset)
      
      let actualCropRect = self.convertThumbnailRectToVideoRect(
        thumbnailRect: crop.cropRect,
        thumbnailSize: crop.thumbnail.size,
        containerSize: crop.containerSize,
        videoSize: videoSize
      )
      
      let composition = try await self.makeCroppedVideoComposition(
        crop: actualCropRect,
        asset: originalAsset
      )
      
      let exportedAsset = try await self.exportToNewAsset(
        asset: originalAsset,
        composition: composition,
        index: index
      )
      
      exportedAssets.append(exportedAsset)
      print("✅ 처리 완료 idx:\(index)")
    }
    
    return exportedAssets
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
  
  private func getVideoSize(from asset: AVAsset) async throws -> CGSize {
    guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
      throw AssetError.assetNotFound
    }
    
    let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
    return CGSize(width: abs(size.width), height: abs(size.height))
  }
  
  private func exportToNewAsset(
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
      presetName: AVAssetExportPresetHighestQuality
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
