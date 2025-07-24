//
//  HJGalleryView.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct GalleryView: View {
    
    @EnvironmentObject var router: Router
    @State var viewModel = GalleryViewModel()
//    @State var showCropPage: Bool = false // soop TODO: - NavigationPath 정의되면 수정
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 선택 비디오 가로스크롤 뷰
                if !viewModel.selectedVideos.isEmpty {
                    SelectedVideoHorizontalScrollView(viewModel: viewModel)
                }
                AllVideoGridScrollView(viewModel: viewModel)
                Spacer()
                VStack {
                    if viewModel.canProceedToEdit {
                        CtaButton(
                            buttonType: .next,
                            isDisabled: .constant(false)
                        ) {
                            router.push(screen: .editVideoRatio(viewModel.selectedVideos))
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

#Preview {
    GalleryView()
}
