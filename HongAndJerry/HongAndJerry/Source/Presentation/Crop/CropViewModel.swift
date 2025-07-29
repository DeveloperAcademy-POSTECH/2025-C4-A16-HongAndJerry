//
//  CropViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/20/25.
//

import Photos
import SwiftUI

@Observable
final class CropViewModel {
    
    enum Action {
        case loadThumbnail
        case goToNextPhoto
        case goToPreviousPhoto
        case setContainerSize(CGSize, at: Int)
    }
    
    var selectedVideos: [PHAsset]
    var currentIndex = 0
    var thumbnails: [String: UIImage] = [:]
    var isLoading = true
    
    var crops: [Crop] = []
    
    var croppedVideos: [(AVAsset, AVVideoComposition)] = []
    
    init(selectedVideos: [PHAsset]) {
        self.selectedVideos = selectedVideos
    }
}

extension CropViewModel {
    
    func send(_ action: Action) {
        
        switch action {
        case .loadThumbnail:
            loadThumbnails()
            
        case .goToNextPhoto:
            if currentIndex < 2 { currentIndex += 1 }
            
        case .goToPreviousPhoto:
            if currentIndex > 0 { currentIndex -= 1 }
            
        case .setContainerSize(let size, let index):
            setContainerSize(size, at: index)
        }
    }
    
    private func loadThumbnails() {
        Task {
            await loadThumbnailsAsync()
        }
    }
    
    @MainActor
    private func loadThumbnailsAsync() async {
        isLoading = true
        
        for video in selectedVideos {
            let thumbnail = await loadSingleThumbnail(for: video)
            if let thumbnail = thumbnail {
                thumbnails[video.localIdentifier] = thumbnail
                crops.append(Crop(video: video, localIdentifier: video.localIdentifier, cropRect: .init(x: 0, y: 0, width: 10, height: 10), thumbnail: thumbnail))
            }
        }
        
        isLoading = false   // 로딩이 끝나면 TabView에 이미지 띄움
    }
    
    private func loadSingleThumbnail(for video: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            let targetSize = PHImageManagerMaximumSize // 원본 해상도
            
            manager.requestImage(
                for: video,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    // CropRect 업데이트 메서드 추가
    func updateCropRect(at index: Int, rect: CGRect) {
        guard index < crops.count else { return }
        crops[index].cropRect = rect
    }
    
    // 개별 CropRect 바인딩 생성
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
    
    // CropView에 추가할 헬퍼 함수
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
    
    @MainActor
    func cropVideos() async {
        print("🔍 crops 배열 확인:")
        for (index, crop) in crops.enumerated() {
            print("  [\(index)] cropRect: \(crop.cropRect)")
            print("  [\(index)] containerSize: \(crop.containerSize)")
            print("  [\(index)] thumbnailSize: \(crop.thumbnail.size)")
        }
        
        do {
            // 새로운 방법: 실제로 렌더링된 AVAsset들을 받아옴
            let exportedAssets = try await PHImageManager.default().exportCroppedVideos(crops: crops)
            print("✅ exportCroppedVideos 성공: \(exportedAssets.count)개 생성")
            
            // croppedVideos를 새로운 방식으로 저장 (composition은 더 이상 필요 없음)
            croppedVideos = exportedAssets.map { ($0, AVMutableVideoComposition()) }
            
        } catch {
            print("❌ exportCroppedVideos 에러: \(error)")
            print("에러 타입: \(type(of: error))")
            if let assetError = error as? AssetError {
                print("AssetError: \(assetError)")
            }
        }
    }
    }
}
