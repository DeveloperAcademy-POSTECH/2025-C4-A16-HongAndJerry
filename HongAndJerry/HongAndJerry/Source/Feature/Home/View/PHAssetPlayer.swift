import SwiftUI
import AVKit
import Photos

struct PHAssetPlayer: View {
  let asset: PHAsset
  
  @State private var player: AVPlayer?
  @State private var isLoading = true
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      if isLoading {
        ProgressView().tint(.white)
      } else if let player = player {
        VideoPlayer(player: player).ignoresSafeArea()
      }
    }
    .onAppear { loadVideo() }
    .onDisappear { player?.pause()}
  }
  
  private func loadVideo() {
    let options = PHVideoRequestOptions()
    options.deliveryMode = .automatic
    options.isNetworkAccessAllowed = true
    
    PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, info in
      DispatchQueue.main.async {
        if let item = playerItem {
          self.player = AVPlayer(playerItem: item)
          self.player?.play()
        } else {
          print("❌ Failed to load video: \(String(describing: info))")
        }
        self.isLoading = false
      }
    }
  }
}
