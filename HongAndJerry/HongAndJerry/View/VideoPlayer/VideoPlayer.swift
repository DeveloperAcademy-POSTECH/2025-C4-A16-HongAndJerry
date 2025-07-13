//
//  VideoPlayer.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//
import SwiftUI
import Foundation
import AVKit

struct VideoPlayer: View {
    let player: AVPlayer
    
    var body: some View {
        VStack {
            VideoView(player: player)
        }
    }
}
