//
//  CropTestView.swift
//  HongAndJerry
//
//  Created by Soop on 7/27/25.
//

import SwiftUI
import AVKit

struct CropTestView: View {
    
    var viewModel: CropViewModel
    @State private var isLoaded = false
    
    var body: some View {
        VStack {
            if viewModel.croppedVideos.isEmpty {
                ProgressView("Cropping Videos…")
                    .task {
                        if !isLoaded {
                            isLoaded = true
                            await viewModel.cropVideos()
                        }
                    }
            } else {
                ScrollView {
                    ForEach(Array(viewModel.croppedVideos.enumerated()), id: \.offset) { index, item in
                        CropPlayerView(asset: item.0, videoComposition: item.1)
//                            .padding()
                    }
                }
            }
        }
    }
}

struct CropPlayerView: View {
    let asset: AVAsset
    let videoComposition: AVVideoComposition

    var body: some View {
        VideoPlayer(player: makePlayer())
            .frame(height: 300)
    }

    func makePlayer() -> AVPlayer {
        let item = AVPlayerItem(asset: asset)
        item.videoComposition = videoComposition
        return AVPlayer(playerItem: item)
    }
}

#Preview {
    CropTestView(viewModel: .init(selectedVideos: []))
}
