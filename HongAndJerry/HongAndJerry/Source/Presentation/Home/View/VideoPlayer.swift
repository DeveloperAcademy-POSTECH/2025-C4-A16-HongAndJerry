//
//  VideoPlayer.swift
//  HongAndJerry
//
//  Created by Hong on 7/24/25.
//

import SwiftUI
import AVKit
import Photos

struct HomeVideoPlayer: UIViewControllerRepresentable {
    let asset: PHAsset

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        requestPlayerItem(from: asset) { playerItem in
            if let item = playerItem {
                controller.player = AVPlayer(playerItem: item)
                controller.player?.play()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    private func requestPlayerItem(from asset: PHAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
            DispatchQueue.main.async {
                completion(playerItem)
            }
        }
    }
}
