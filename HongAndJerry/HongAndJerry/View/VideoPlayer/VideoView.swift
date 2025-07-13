//
//  VideoView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/12/25.
//

import SwiftUI
import AVFoundation
import Foundation

struct VideoView: UIViewRepresentable {
    
    let player: AVPlayer
    
    func makeUIView(context: Context) -> VideoUIView {
        return VideoUIView(player: player)
    }
    
    func updateUIView(_ uiView: VideoUIView, context: Context) {
        if(uiView.player !== self.player) {
            uiView.player = self.player
        }
    }
}
