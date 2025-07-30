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
        VStack {
            Text(ExportNameSpace.AppMain.AppName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .font(.SUITTitle)
                .foregroundStyle(.font)
            if viewModel.videos.isEmpty {
                Spacer()
                Image(.logo)
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
    }
    
}

#Preview(body: {
    HomeView()
})
