//
//  PHImageManager.swift
//  HongAndJerry
//
//  Created by Soop on 7/23/25.
//

import Photos
import AVFoundation

extension PHImageManager {
    
    /// PHAsset을 비동기로 AVAsset으로 변환.
    func requestAVAssetAsync(
        for asset: PHAsset,
        options: PHVideoRequestOptions? = nil
    ) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            self.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                
                // 에러 처리: info에 에러가 있을 경우 throw
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: AssetError.infoNotFound)
                    return
                }
                
                // AVAsset 반환 성공
                if let avAsset = avAsset {
                    continuation.resume(returning: avAsset)
                } else {
                    continuation.resume(throwing: AssetError.assetNotFound)
                }
            }
        }
    }
    
    func cropVideos(_ crops: [Crop]) async throws {
        for crop in crops {
            let video  = try await self.requestAVAssetAsync(for: crop.video)        // AVAsset 타입의 비디오
            let videoSize = try await getVideoSize(from: video)                     // 비디오의 실제 사이즈
            let actualCropRect = self.convertThumbnailRectToVideoRect(thumbnailRect: crop.cropRect, thumbnailSize: crop.thumbnail.size, videoSize: videoSize)                           // 실제 크롭 영역
        }
        
    }
    
    func getVideoSize(from asset: AVAsset) async throws -> CGSize {
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
            throw AssetError.assetNotFound
        }
        
        let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
        
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func convertThumbnailRectToVideoRect(
        thumbnailRect: CGRect,
        thumbnailSize: CGSize,
        videoSize: CGSize
    ) -> CGRect {
        // 썸네일과 실제 비디오의 비율 계산
        let scaleX = videoSize.width / thumbnailSize.width
        let scaleY = videoSize.height / thumbnailSize.height
        
        // CGRect를 실제 비디오 좌표로 변환
        let videoRect = CGRect(
            x: thumbnailRect.origin.x * scaleX,
            y: thumbnailRect.origin.y * scaleY,
            width: thumbnailRect.width * scaleX,
            height: thumbnailRect.height * scaleY
        )
        
        return videoRect
    }
    
    func makeCroppedVideo(crop: CGRect, asset: AVAsset) async throws -> AVMutableVideoComposition {
        let videoComposition = try await AVMutableVideoComposition.videoComposition(with: asset) { request in
            let cropFilter = CIFilter(name: "CICrop")!
            cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
            cropFilter.setValue(CIVector(cgRect: crop), forKey: "inputRectanlge")
            let cropped = cropFilter.outputImage!
            let translated = cropped.transformed(by: CGAffineTransform(translationX: -crop.origin.x, y: -crop.origin.y))
            request.finish(with: translated, context: nil)
        }
        
        videoComposition.renderSize = crop.size
        
        return videoComposition
    }
}
