//
//  FullScreenPlayerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/19/25.
//

import SwiftUI


struct FullScreenPlayerView: View {
    @Environment(VideoViewModel.self) private var viewModel
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            VideoPlayerView(playerController: viewModel.playerController)
                .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            FullScreenControlsView()
        }
        .background(Color.black.ignoresSafeArea())
    }
}
