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
    
    func cropVideos(crops: [Crop], defaultThumbnailSize: CGRect) async throws -> [(AVAsset, AVVideoComposition)] {
        var array: [(AVAsset, AVVideoComposition)] = []
        
        for crop in crops {
            let video  = try await self.requestAVAssetAsync(for: crop.video)        // AVAsset 타입의 비디오
            let videoSize = try await getVideoSize(from: video)                     // 비디오의 실제 사이즈
            print("비디오 사이즈 : \(videoSize)")
            let actualCropRect = self.convertThumbnailRectToVideoRect(thumbnailRect: crop.cropRect, thumbnailSize: crop.thumbnail.size, defaultThumbnailSize: defaultThumbnailSize, videoSize: videoSize)                           // 실제 크롭 영역
            print("사용자가 선택한 사각형 사이즈 : \(crop.cropRect)")
//            print("\(actualCropRect)")
            let composition = try await self.makeCroppedVideoComposition(crop: actualCropRect, asset: video)
            array.append((video, composition))
        }
        return array
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
        defaultThumbnailSize: CGRect,
        videoSize: CGSize
    ) -> CGRect {
        // 썸네일과 실제 비디오의 비율 계산
    
        
        let scaleX = videoSize.width / defaultThumbnailSize.width
        let scaleY = videoSize.height / defaultThumbnailSize.height
        
        print("scaleX(\(scaleX)) = \(videoSize.width) / \(defaultThumbnailSize.width)")
        print("scaleY(\(scaleY)) = \(videoSize.height) / \(defaultThumbnailSize.height)")
        
        // CGRect를 실제 비디오 좌표로 변환
        let videoRect = CGRect(
            x: thumbnailRect.origin.x * scaleX,
            y: thumbnailRect.origin.y * scaleY,
            width: thumbnailRect.width * scaleX,
            height: thumbnailRect.height * scaleY
        )
        
        return videoRect
    }
    
    func makeCroppedVideoComposition(crop: CGRect, asset: AVAsset) async throws -> AVVideoComposition {
        let videoComposition = try await AVVideoComposition.videoComposition(
            with: asset
        ) { request in
            do {
                guard let cropFilter = CIFilter(
                    name: "CICrop"
                ) else {
                    throw NSError(
                        domain: "CropFilter",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "CICrop 필터 생성 실패"]
                    )
                }
                cropFilter.setValue(
                    request.sourceImage,
                    forKey: kCIInputImageKey
                )
                cropFilter.setValue(
                    CIVector(
                        cgRect: crop
                    ),
                    forKey: "inputRectangle"
                )
                guard let cropped = cropFilter.outputImage else {
                    throw NSError(
                        domain: "CropFilter",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "출력 이미지 생성 실패"]
                    )
                }
                let translated = cropped.transformed(
                    by: CGAffineTransform(
                        translationX: -crop.origin.x,
                        y: -crop.origin.y
                    )
                )
                request.finish(
                    with: translated,
                    context: nil
                )
            } catch {
                request.finish(
                    with: error
                )
            }
        }
        
        return videoComposition
    }
}
