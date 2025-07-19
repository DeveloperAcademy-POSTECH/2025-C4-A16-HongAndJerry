//
//  HJAllVideoGridView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI

struct HJAllVideoGridScrollView: View {
    
    @ObservedObject var viewModel: HJGalleryViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(viewModel.videos, id: \.localIdentifier) { video in
                    HJVideoThumbnail(
                        video: video,
                        isSelected: viewModel.selectedVideos.contains(video),
                        selectionIndex: viewModel.getSelectionIndex(for: video),
                        onTap: { viewModel.toggleSelection(video) }
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadVideos()
        }
    }
}

//#Preview {
//    HJAllVideoGridScrollView()
//}
