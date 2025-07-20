//
//  HJGalleryViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import Photos
import SwiftUI

// TODO: - 뷰모델 이름 다시 정하기... 비디오 선택 + 비디오 편집 기능 분리해야 하나
@Observable
    
    private let maxSelection = 3                    // 최대 선택 개수
    
    init(
        videos: [PHAsset] = [],
        selectedVideos: [PHAsset] = []
    ) {
        self.videos = videos
        self.selectedVideos = selectedVideos
    }
}

extension GalleryViewModel {
    
    // private func
    // TODO: - 리턴 수정하기 ...
    func getSelectionIndex(for video: PHAsset) -> Int? {
        let videoId = video.localIdentifier
        let index = selectedVideos.firstIndex(where: { $0.localIdentifier == videoId })
        
        return index.map { $0 + 1 }
    }
    
    /// 설정에 따른 사용자로부터 갤러리 접근 권한 요청
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus() // 사용자의 접근 권한 상태 확인
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// PhotoLibrary에서 비디오 에셋 가져오기
    private func fetchVideos() {
        let fetchOptions = PHFetchOptions() // 필터 및 정렬 옵션. 영상만 필터링하고, 최신순 정렬
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions) // 원하는 옵션으로 에셋 가져오기
        
        DispatchQueue.main.async {
            self.videos = []
            fetchResult.enumerateObjects { asset, _, _ in           // 가져온 에셋을 순회하며 배열에 저장하기
                self.videos.append(asset)
            }
        }
    }
    
    // func
    /// 갤러리 접근 권한 확인 후, 전체 비디오 가져오기
    func loadVideos() {
        requestPhotoLibraryPermission { granted in
            if granted {
                self.fetchVideos()
            }
        }
    }
    
    /// 비디오 선택 여부 토글
    /// 전체 비디오 목록에서 비디오를 선택했을 때,
    /// 선택 비디오 목록에 이미 존재한 비디오면, 선택 비디오 목록에서 삭제
    /// 선택 비디오 목록에 없다면, 선택 비디오 목록에 추가
    func toggleSelection(_ video: PHAsset) {
        if selectedVideos.contains(video) {             // 이미 선택한 비디오일 경우
            removeVideo(video)              // 삭제
        } else if selectedVideos.count < maxSelection { // 최대 선택 개수 미만일 경우
            selectedVideos.append(video)    // 추가
        }
    }
    
    /// 선택한 비디오가 이미 선택 비디오 목록에 있다면 삭제
    func removeVideo(_ video: PHAsset) {
        selectedVideos.removeAll { $0 == video }
    /// 비디오 삭제
    /// 비디오의 id를 비교하여, 선택한 비디오 배열에 존재하면 삭제
    private func removeVideo(_ video: PHAsset) {
        let videoId = video.localIdentifier
        
        selectedVideos.removeAll { $0.localIdentifier == videoId }
    }
}
