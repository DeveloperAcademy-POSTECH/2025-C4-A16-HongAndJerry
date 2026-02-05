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

class PlayerUIView: UIView {
  private var playerLayer: AVPlayerLayer {
    guard let layer = self.layer as? AVPlayerLayer else {
      fatalError("Layer is not AVPlayerLayer")
    }
    return layer
  }
  var player: AVPlayer? {
    get {
      playerLayer.player
    }
    set {
      playerLayer.player = newValue
    }
  }
  override class var layerClass: AnyClass {
    AVPlayerLayer.self
  }
  init(player: AVPlayer) {
    super.init(frame: .zero)
    self.player = player
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
