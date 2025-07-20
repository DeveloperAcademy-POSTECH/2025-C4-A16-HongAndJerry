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
    @State var showCropPage: Bool = false // soop TODO: - NavigationPath 정의되면 수정
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 선택 비디오 가로스크롤 뷰
                    if !viewModel.selectedVideos.isEmpty {
                        SelectedVideoHorizontalScrollView(viewModel: viewModel)
                            // soop TODO: - 선택 영상 목록 등장시 애니메이션 효과 주기
                    }
                    AllVideoGridScrollView(viewModel: viewModel)
                    
                    // soop TODO: 다음 버튼이 생성되고 나서, 갤러리 최하단에 도달했을 경우 하단에 공백
                }
                
                VStack {
                    Spacer()
                    
                    if viewModel.canProceedToEdit {
                        CtaButton(
                            buttonType: .next,
                            isDisabled: .constant(false)
                        ) {
                            showCropPage = true
                        }
                        .padding(.horizontal, 16)
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
