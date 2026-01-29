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

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if !viewModel.selectedVideos.isEmpty {
                    SelectedVideoHorizontalScrollView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.selectedVideos)
                }
                ZStack {
                    AllVideoGridScrollView(viewModel: viewModel)
                        .animation(.easeInOut, value: viewModel.selectedVideos)
                    VStack {
                        Spacer()
                        if viewModel.canProceedToEdit {
                            CtaButton(
                                buttonType: .next,
                                isDisabled: .constant(false)
                            ) {
                                router.push(screen: .editVideoRatio(viewModel.selectedVideos))
                            }
                        }
                    }
                }
            }
        }
        .hjNavigationBar(title: ExportNameSpace.AppMain.selectVideoTitle)
    }
}

#Preview {
    GalleryView()
}
