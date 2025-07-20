//
//  CropView.swift
//  HongAndJerry
//
//  Created by Soop on 7/20/25.
//

import SwiftUI
import Photos

struct CropView: View {
    
    @Bindable var viewModel: CropViewModel  // ← 핵심: @Bindable
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("로딩 중...")
                    .frame(width: 300, height: 300)
            } else {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.1.localIdentifier) { index, video in
                        
                        Group {
                            if let thumbnail = viewModel.thumbnails[video.localIdentifier] {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 300, height: 300)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 300, height: 300)
                                    .cornerRadius(12)
                                    .overlay(ProgressView())
                            }
                        }
                        .tag(index) // 중요: index로 태그 매칭
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .onAppear {
            viewModel.loadThumbnails()
        }
    }
}

#Preview {
    CropView(viewModel: CropViewModel(selectedVideos: []))
}
