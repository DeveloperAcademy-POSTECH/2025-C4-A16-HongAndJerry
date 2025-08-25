//
//  HomeView.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import SwiftUI
import Photos

struct HomeView {
    @EnvironmentObject var router: Router
    @State private var viewModel = AlbumVideoViewModel()
    @State private var selectedAsset: PHAsset? = nil
    @State private var showPlayer = false
}

extension HomeView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(.homeViewLogo)
                .resizable()
                .frame(width: 75, height: 18)
                .padding(.leading)
            if viewModel.videos.isEmpty {
                Spacer()
                Text("프로젝트 생성 해주세요!")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.SUITBodyTitle)
                    .foregroundStyle(.inactive)
                Spacer()
            } else {
                VideoScrollView(
                    viewModel: $viewModel,
                    selectedAsset: $selectedAsset,
                    showPlayer: $showPlayer
                )
            }
            CtaButton(
                buttonType: .plus,
                isDisabled: .constant(false)) {
                    router.push(screen: .selectFrame)
                }
        }
        .background(Color.background)
        
        .sheet(isPresented: $showPlayer) {
            if let asset = selectedAsset {
                HomeVideoPlayer(asset: asset)
            }
        }
        .onAppear {
            viewModel.loadVideos(albumName: "WVDO")
        }
    }
}

#Preview(body: {
    HomeView()
})
