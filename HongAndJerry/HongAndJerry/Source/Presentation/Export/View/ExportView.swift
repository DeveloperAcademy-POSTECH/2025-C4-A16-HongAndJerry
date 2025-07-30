//
//  ExportView.swift
//  HongAndJerry
//
//  Created by Hong on 7/30/25.
//

import AVKit
import Photos
import SwiftUI

struct ExportView {
    @State var viewModel: ExportViewModel
    @EnvironmentObject var router: Router
    @State private var player: AVPlayer?
}

extension ExportView: View {
    var body: some View {
        if !viewModel.isExported {
            VStack {
                Spacer()
                if let asset = viewModel.video {
                    VideoPlayer(player: player)
                        .onAppear {
                            if player == nil {
                                let item = AVPlayerItem(asset: asset)
                                item.videoComposition = viewModel.avvideoComposition
                                player = AVPlayer(playerItem: item)
                                player?.play()
                            }
                        }
                        .frame(width: 234, height: 358)
                }
                Spacer()
                CtaButton(
                    buttonType: .export,
                    isDisabled: .constant(false)) {
                        viewModel.isExported = true
                    }
            }
            .background(Color.background)
        } else {
            LoadingView(viewModel: viewModel)
                
                .navigationBarBackButtonHidden()
        }
    }
}
