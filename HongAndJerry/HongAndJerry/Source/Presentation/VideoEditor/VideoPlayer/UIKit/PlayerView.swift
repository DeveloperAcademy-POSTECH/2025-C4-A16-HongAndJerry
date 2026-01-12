//
//  VideoView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/12/25.
//

import SwiftUI
import AVFoundation
import Foundation

struct PlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player !== self.player {
            uiView.player = self.player
        }
    }
}
