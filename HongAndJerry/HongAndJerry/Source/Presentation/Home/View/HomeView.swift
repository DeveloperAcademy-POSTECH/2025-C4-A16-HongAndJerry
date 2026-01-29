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
    @State private var viewModel = HomeViewModel()
    @State private var selectedAsset: PHAsset? = nil
}

extension HomeView: View {
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.videos.isEmpty {
                Spacer()
                Text("아직 생성된 비디오가 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.SUITTitle)
                    .foregroundStyle(.inactive)
                Spacer()
            } else {
                VideoScrollView(
                    viewModel: $viewModel,
                    selectedAsset: $selectedAsset
                )
            }
            CtaButton(
                buttonType: .plus,
                isDisabled: .constant(false)) {
                    router.push(screen: .selectVideo)
                }
        }
        .sheet(isPresented: Binding(
            get: { selectedAsset != nil },
            set: { if !$0 { selectedAsset = nil } }
        )) {
            if let asset = selectedAsset {
                PHAssetPlayer(asset: asset)
            }
        }
        .background(Color.background)
        .onAppear {
            viewModel.loadVideos(albumName: "WVDO")
        }
    }
}

#Preview(body: {
    HomeView()
})
