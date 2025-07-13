//
//  ContentView.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var viewModel = VideoViewModel()
    
    var body: some View {
        VStack(spacing: 14) {
            // MARK: - Video Preview
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
                    .padding(36)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(9/16, contentMode: .fit)
            }
            
            // MARK: - Play Button
            Button {
                if viewModel.isPlaying {
                    viewModel.pause()
                } else {
                    viewModel.play()
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 16))
            }
            
            // MARK: - Video Editor
            VideoEditor(viewModel: viewModel)
            
        }
        .task {
            do {
                try await viewModel.buildPlayer()
            } catch {
                print("Error building player: \(error)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

#Preview {
    ContentView()
}
