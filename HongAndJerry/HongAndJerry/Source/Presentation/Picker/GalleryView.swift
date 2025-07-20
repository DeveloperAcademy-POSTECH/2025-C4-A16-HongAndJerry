//
//  HJGalleryView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct GalleryView: View {
    
    @State var viewModel = GalleryViewModel()
    @State var showCropPage: Bool = false // TODO: - NavigationPath 정의되면 수정
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                
                VStack(spacing: 0) {
                    // 선택 비디오 가로스크롤 뷰
                    if !viewModel.selectedVideos.isEmpty {
                        SelectedVideoHorizontalScrollView(viewModel: viewModel)
                        
                    }
                    AllVideoGridScrollView(viewModel: viewModel)
                }
                
                VStack {
                    Button {
                        showCropPage = true
                    } label: {
                        Text("확인")
                            .padding()
                            .background(Color.accent)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCropPage) {
                CropView(viewModel: .init(selectedVideos: viewModel.selectedVideos))
            }
        }
    }
}

#Preview {
    GalleryView()
}
