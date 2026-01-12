//
//  PlaybackControlsView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/18/25.
//

import SwiftUI

struct PlaybackControlsView: View {
    @Environment(VideoViewModel.self) private var viewModel

    var body: some View {
        HStack {
            Spacer().frame(width: 1)

            Button {
                if viewModel.playerController.isPlaying {
                    viewModel.playerController.pause()
                } else {
                    viewModel.playerController.play()
                }
            } label: {
                Image(systemName: viewModel.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }

            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.isFullScreen = true
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 30)
    }
}
