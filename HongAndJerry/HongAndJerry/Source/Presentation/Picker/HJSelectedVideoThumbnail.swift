//
//  HJSelectedVideoThumbnail.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

/// 선택한 비디오의 섬네일
struct HJSelectedVideoThumbnail: View {
    
    let video: PHAsset
    let index: Int
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 116, height: 116)
                .overlay(
                    Group {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 116, height: 116)
                                .clipped()
                        }
                    }
                )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    /// 섬네일 로딩 함수
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        manager.requestImage(
            for: video,
            targetSize: CGSize(width: 60, height: 60),
            contentMode: .aspectFill,
            options: option
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

//#Preview {
//    HJSelectedVideoThumbnail(video: <#T##PHAsset#>, index: <#T##Int#>, onRemove: <#T##() -> Void#>, thumbnail: <#T##UIImage?#>)
//}
