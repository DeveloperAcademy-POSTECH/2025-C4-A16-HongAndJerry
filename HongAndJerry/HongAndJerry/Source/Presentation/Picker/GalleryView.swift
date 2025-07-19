//
//  HJGalleryView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct GalleryView: View {
    
    @StateObject var viewModel = GalleryViewModel()
    
    var body: some View {
        ZStack {
            Color.background
            
            VStack(spacing: 0) {
                // 선택 비디오 가로스크롤 뷰
                if !viewModel.selectedVideos.isEmpty {
                    SelectedVideoHorizontalScrollView(viewModel: viewModel)
                }
                AllVideoGridScrollView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    GalleryView()
}
