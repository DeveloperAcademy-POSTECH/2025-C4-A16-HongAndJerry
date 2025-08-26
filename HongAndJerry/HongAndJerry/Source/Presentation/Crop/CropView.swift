//
//  CropView.swift
//  HongAndJerry
//
//  Created by Soop on 7/20/25.
//

import SwiftUI
import Photos

struct CropView: View {
    @EnvironmentObject var router: Router
    @Bindable var viewModel: CropViewModel
    
    @State var cropArea: CGRect = .init(x: 0, y: 0, width: 10, height: 10)
    @State var imageViewSize: CGSize = .zero
    @State var croppedImage: UIImage?
    
    @State var isCropTestViewShown: Bool = false
}

extension CropView {
    var body: some View {
        ZStack {
            // soop TODO: 다들 배경 어떻게 하나 물어보고 변경하깅~
            Color.background.ignoresSafeArea()
            VStack {
                Group {
                    switch viewModel.state {
                    case .thumbnailLoading:
                        ProgressView("로딩 중...")
                            .frame(width: 300, height: 300)
                    case .thumbnailLoaded:
                        tabView
                    case .cropping:
                        ProgressView("자른 영상 로딩 중...")
                            .frame(width: 300, height: 300)
                            .navigationBarBackButtonHidden()
                    case .completedConvertToAsset:
                        Text("Complete")
                    }
                }
                
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
        }
        .hjNavigationBar(title: ExportNameSpace.AppMain.cropVideoTitle)
    }
    
    var tabView: some View {
        VStack {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(
                    Array(viewModel.selectedVideos.enumerated())
                    , id: \.1.localIdentifier
                ) { index, _ in
                    thumbnailCell(videoIndex: index)
                        .tag(index)
                }
            }
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .tabViewStyle(.page(indexDisplayMode: .never))    // 탭뷰 좌우 스크롤 설정
                     
            pageIndicator
                .padding(.vertical, 8)
            
            CtaButton(buttonType: .next, isDisabled: .constant(viewModel.currentIndex != 2)) {
                Task {
                    await viewModel.cropVideos()
                    let segments = await viewModel.createVideoSegments()
                    
                    router.push(screen: .videoEditView(segments))
                }
            }
        }
        
    }
    
    func thumbnailCell(videoIndex: Int) -> some View {
        Group {
            let crop = viewModel.crops[videoIndex]
            
            Image(uiImage: crop.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    GeometryReader { geometry in
                        CropBox(rect: viewModel.bindingForCropRect(at: videoIndex))
                            .allowsHitTesting(true)
                            .onAppear {
                                viewModel.send(.containerDidChangeSize(size: geometry.size, at: videoIndex))
                                if crop.cropRect == CGRect(x: 0, y: 0, width: 10, height: 10) {
                                    let initialRect = viewModel.calculate16x9CropRect(in: geometry.size)
                                    viewModel.updateCropRect(at: videoIndex, rect: initialRect)
                                }
                            }
                            .onChange(of: geometry.size) { oldValue, newValue in
                                viewModel.send(.containerDidChangeSize(size: newValue, at: videoIndex))
                            }
                    }
                }
                .clipped() // 이미지 영역을 벗어나지 않도록
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
            viewModel.send(.prevButtonTapped)
        } label: {
            Image(systemName: "chevron.left")
                .foregroundStyle(.font)
        }
        .buttonStyle(.plain)
    }
    
    var nextButton: some View {
        Button {
            viewModel.send(.nextButtonTapped)
        } label: {
            Image(systemName: "chevron.right")
                .foregroundStyle(.font)
        }
        .buttonStyle(.plain)
    }
}
