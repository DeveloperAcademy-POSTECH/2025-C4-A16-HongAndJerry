//
//  HJSelectedVideoHorizontalScrollView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

/// 선택한 비디오 배열의 수평 스크롤 뷰
struct SelectedVideoHorizontalScrollView: View {
    
    var viewModel: GalleryViewModel
//    @ObservedObject private var selectedVideos: [PHAsset]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.offset) { index, video in
                    SelectedVideoThumbnail(video: video, index: index + 1) {
                        viewModel.removeVideo(video)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.leading, 28)
        }
        .frame(height: 100)
        .background(Color.background)
    }
}
