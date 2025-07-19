//
//  HJSelectedVideoHorizontalScrollView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

/// 선택한 비디오 배열의 수평 스크롤 뷰
struct HJSelectedVideoHorizontalScrollView: View {
    
    @ObservedObject var viewModel: HJGalleryViewModel
//    @ObservedObject private var selectedVideos: [PHAsset]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.offset) { index, video in
                    HJSelectedVideoThumbnail(video: video, index: index + 1) {
                        viewModel.removeVideo(video)
                    }
                }
            }
        }
        .frame(height: 100)
        .background(Color.background)
    }
}
