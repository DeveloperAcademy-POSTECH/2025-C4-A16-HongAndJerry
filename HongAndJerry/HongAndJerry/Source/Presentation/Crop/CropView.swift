//
//  CropView.swift
//  HongAndJerry
//
//  Created by Soop on 7/20/25.
//

import SwiftUI
import Photos

struct CropView: View {
    
    @Bindable var viewModel: CropViewModel
    
    @State var cropArea: CGRect = .init(x: 0, y: 0, width: 100, height: 100)
    @State var imageViewSize: CGSize = .zero
    @State var croppedImage: UIImage?
    
    var body: some View {
        ZStack {
            // soop TODO: 다들 배경 어떻게 하나 물어보고 변경하깅~
            Color.background.ignoresSafeArea()
            Group {
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
                        .frame(width: 300, height: 300)
                } else {
                    tabView
                }
            }
            .onAppear {
                viewModel.send(.loadThumbnail)
            }
        }
    }
    
    var tabView: some View {
        VStack {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.selectedVideos.enumerated()), id: \.1.localIdentifier) { index, video in
                    thumbnailCell(videoIndex: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))    // 탭뷰 좌우 스크롤 설정
            
            HStack {
                
                if viewModel.currentIndex > 0 {
                    previousButton
                }
                
                Spacer()
                
                pageIndicator
                
                Spacer()
                
                if viewModel.currentIndex < 2 {
                    nextButton
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    func thumbnailCell(videoIndex: Int)-> some View {
        Group {
            var crop = viewModel.crops[videoIndex]
            
            Image(uiImage: crop.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    GeometryReader { geometry in
                        CropBox(rect: .constant(crop.cropRect))
                            .onAppear {
                                self.imageViewSize = geometry.size
                            }
                            .onChange(of: geometry.size) {
                                self.imageViewSize = $0
                        }
                    }
                }
            
            
//            if let thumbnail = viewModel.crops[videoIndex].thumbnail {
            
        }
    }
    
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.selectedVideos.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentIndex ? Color.font : Color.font.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
            }
        }
    }
    
    var previousButton: some View {
        Button {
            viewModel.send(.goToPreviousPhoto)
        } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(.font)
        }
        .buttonStyle(.plain)
    }
    
    var nextButton: some View {
        Button {
            viewModel.send(.goToNextPhoto)
        } label: {
            Image(systemName: "chevron.right")
                .foregroundStyle(.font)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CropView(viewModel: CropViewModel(selectedVideos: []))
}
