//
//  VideoPlayer.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//
import SwiftUI
import Foundation

struct VideoPlayer: View {
    let videoPlayerViewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack {
            Text("Video Player")
        }
    }
}

#Preview {
    
    
    let viewModel = VideoPlayerViewModel();
    VideoPlayer(videoPlayerViewModel: viewModel)
}
