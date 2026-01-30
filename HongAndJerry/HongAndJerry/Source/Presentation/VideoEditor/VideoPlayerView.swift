//
//  VideoPlayerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/18/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
  @Environment(EditorViewModel.self) private var viewModel
  let playerController: PlayerController
  
  var body: some View {
    ZStack {
      PlayerView(player: playerController.player)
        .frame(maxWidth: .infinity)
        .opacity(viewModel.isLoading ? 0 : 1)
    }
  }
}
