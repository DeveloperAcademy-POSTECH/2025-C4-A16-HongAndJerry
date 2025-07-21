//
//  HJAllVideoGridView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI

struct AllVideoGridScrollView: View {
    
    var viewModel: GalleryViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 2),
                    count: 3),
                spacing: 2
            ) {
                ForEach(viewModel.videos, id: \.localIdentifier) { video in
                    VideoThumbnail(
                        video: video,
                        isSelected: viewModel.selectedVideos.contains(video),
                        selectionIndex: viewModel.getSelectionIndex(for: video),
                        onTap: { viewModel.send(.toggleSelection(video)) }
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            Task {
                await viewModel.loadVideos()
            }
        }
    }
}

//#Preview {
//    HJAllVideoGridScrollView()
//}
