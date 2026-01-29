//
//  HJSelectedVideoHorizontalScrollView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos


struct SelectedVideoHorizontalScrollView: View {
    var viewModel: GalleryViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.element.localIdentifier) { index, video in
                    SelectedVideoThumbnail(video: video, index: index + 1) {
                        viewModel.send(.removeSelection(video))
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
