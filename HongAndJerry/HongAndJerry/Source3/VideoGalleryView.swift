//
//  VideoGalleryView.swift
//  HongAndJerry
//
//  Created by Soop on 7/17/25.
//

import SwiftUI
import Photos
import AVFoundation

struct VideoGalleryView: View {
    @StateObject private var viewModel = VideoGalleryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 선택된 비디오 섬네일 가로스크롤뷰
            if !viewModel.selectedVideos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.offset) { index, video in
                            SelectedVideoThumbnail(
                                video: video,
                                index: index + 1,
                                onRemove: { viewModel.removeVideo(video) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 80)
                .background(Color.gray.opacity(0.1))
            }
            
            // 인라인 갤러리 (3그리드)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(viewModel.videos, id: \.localIdentifier) { video in
                        VideoThumbnailCell(
                            video: video,
                            isSelected: viewModel.selectedVideos.contains(video),
                            selectionIndex: viewModel.getSelectionIndex(for: video),
                            onTap: { viewModel.toggleSelection(video) }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .onAppear {
            viewModel.loadVideos()
        }
    }
}

#Preview {
  VideoGalleryView()
}
