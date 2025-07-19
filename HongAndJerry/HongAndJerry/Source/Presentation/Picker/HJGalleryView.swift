//
//  HJGalleryView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct HJGalleryView: View {
    
    @StateObject var viewModel = HJGalleryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 선택 비디오 가로스크롤 뷰
            if !viewModel.selectedVideos.isEmpty {
                HJSelectedVideoHorizontalScrollView(viewModel: viewModel)
            }
            HJAllVideoGridScrollView(viewModel: viewModel)
        }
    }
}

#Preview {
    HJGalleryView()
}
