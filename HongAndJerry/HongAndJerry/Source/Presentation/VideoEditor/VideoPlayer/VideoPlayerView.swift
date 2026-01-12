//
//  VideoPlayerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/18/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let playerController: PlayerController

    var body: some View {
        PlayerView(player: playerController.player)
            .aspectRatio(1080 / 1821, contentMode: .fit)
            .background(Color.black)
    }
}


