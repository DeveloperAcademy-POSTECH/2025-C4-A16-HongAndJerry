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
    
    func convertThumbnailRectToVideoRect(
        thumbnailRect: CGRect,
        thumbnailSize: CGSize,
        containerSize: CGSize,
        videoSize: CGSize
    ) -> CGRect {
        
        // 1. .fit 모드에서 실제 썸네일 이미지가 표시되는 영역을 계산합니다. (레터박스 제외)
        let fittedRect = calculateFittedRect(from: containerSize, imageSize: thumbnailSize)
        
        // 2. 사용자가 선택한 크롭 영역(thumbnailRect)을 실제 이미지(fittedRect) 기준의 상대 좌표로 변환합니다.
        let relativeX = thumbnailRect.origin.x - fittedRect.origin.x
        let relativeY = thumbnailRect.origin.y - fittedRect.origin.y
        
        // 썸네일 뷰 크기 대비 실제 비디오 해상도의 스케일링 비율을 계산합니다.
        let scaleX = videoSize.width / fittedRect.width
        let scaleY = videoSize.height / fittedRect.height
        
        // 3. 상대 좌표와 스케일링 비율을 사용하여 실제 비디오의 크롭 좌표를 계산합니다.
        let videoRect = CGRect(
            x: relativeX * scaleX,
            y: relativeY * scaleY,
            width: thumbnailRect.width * scaleX,
            height: thumbnailRect.height * scaleY
        )
        
        return videoRect
    }
    
    func makeCroppedVideoComposition(crop: CGRect, asset: AVAsset) async throws -> AVVideoComposition {
        // 크롭 영역의 크기가 0이면 빈 Composition을 반환하여 크래시를 방지합니다.
        guard crop.width > 0, crop.height > 0 else {
            return AVVideoComposition()
        }
        
        // 1. 비디오 트랙과 기본 정보를 비동기로 로드합니다.
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AssetError.assetNotFound
        }
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let originalTransform = try await videoTrack.load(.preferredTransform)
        
        // 2. AVFoundation의 표준 도구를 사용하여 Composition을 구성합니다.
        let composition = AVMutableVideoComposition()
        composition.renderSize = crop.size // 최종 결과물 크기를 크롭 영역의 크기로 설정
        composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate > 0 ? frameRate : 30))
        
        let instruction = AVMutableVideoCompositionInstruction()
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // 3. 최종 변환 행렬(Transform)을 계산합니다.
        // 이 행렬은 원본 비디오를 최종 캔버스에 어떻게 위치시킬지 결정합니다.
        // a. 원본 비디오의 방향(회전)을 그대로 가져옵니다.
        // b. 크롭 영역의 왼쪽 상단이 (0,0)이 되도록 비디오를 평행 이동시킵니다.
        let finalTransform = originalTransform.concatenating(CGAffineTransform(translationX: -crop.origin.x, y: -crop.origin.y))
        
        // 4. Layer Instruction에 최종적으로 계산된 변환 행렬만 설정합니다.
        layerInstruction.setTransform(finalTransform, at: .zero)
        
        // 5. Composition을 최종 구성합니다.
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
    
    /// .aspectRatio(contentMode: .fit) 로 인해 생긴 레터박스를 계산하여,
    /// 썸네일 이미지 뷰 안에 실제 썸네일이 그려지는 영역(CGRect)을 반환합니다.
    private func calculateFittedRect(from containerSize: CGSize, imageSize: CGSize) -> CGRect {
        let containerAspectRatio = containerSize.width / containerSize.height
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var finalSize: CGSize = .zero
        var origin: CGPoint = .zero
        
        // 컨테이너가 이미지보다 넓은 경우 (세로에 맞춰짐, 좌우에 레터박스)
        if containerAspectRatio > imageAspectRatio {
            finalSize.height = containerSize.height
            finalSize.width = imageSize.width * (containerSize.height / imageSize.height)
            origin.x = (containerSize.width - finalSize.width) / 2
            origin.y = 0
        } else { // 컨테이너가 이미지보다 좁거나 같은 경우 (가로에 맞춰짐, 상하에 레터박스)
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
    
    /// AVAsset과 composition을 실제로 렌더링해서 새로운 파일로 저장합니다.
    private func exportToNewAsset(asset: AVAsset, composition: AVVideoComposition, index: Int) async throws -> AVAsset {
        // 임시 파일 경로 생성
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent("croppedVideo_\(index)_\(UUID().uuidString).mov")
        // 기존 파일이 있다면 삭제
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        // Export session 생성
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
        
        // 에러 체크
        if let error = exportSession.error {
            throw error
        }
        
        guard exportSession.status == .completed else {
            throw AssetError.assetNotFound
        }
        
        // 새로운 AVAsset 생성
        return AVURLAsset(url: outputURL)
    }
}
