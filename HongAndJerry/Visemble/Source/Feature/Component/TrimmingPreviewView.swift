import AVFoundation
import SwiftUI
import UIKit

final class TrimmingPreviewUIView: UIView {

  private var containerLayers: [CALayer] = []
  private var cachedSegmentPlayers: [TrimmingPlayerUseCase.SegmentPlayer] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return nil
  }

  func configure(with segmentPlayers: [TrimmingPlayerUseCase.SegmentPlayer]) {
    cachedSegmentPlayers = segmentPlayers
    rebuildLayers()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    rebuildLayers()
  }

  private func rebuildLayers() {
    for container in containerLayers {
      container.removeFromSuperlayer()
    }
    containerLayers.removeAll()

    let viewWidth = bounds.width
    let viewHeight = bounds.height
    let slotCount = cachedSegmentPlayers.count
    guard slotCount > 0, viewWidth > 0, viewHeight > 0 else { return }

    let slotHeight = viewHeight / CGFloat(slotCount)

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    for (index, sp) in cachedSegmentPlayers.enumerated() {
      let slotRect = CGRect(
        x: 0,
        y: CGFloat(index) * slotHeight,
        width: viewWidth,
        height: slotHeight
      )

      let containerLayer = CALayer()
      containerLayer.frame = slotRect
      containerLayer.masksToBounds = true
      containerLayer.backgroundColor = UIColor.black.cgColor

      let playerLayer = AVPlayerLayer(player: sp.player)
      playerLayer.videoGravity = .resizeAspect

      let transformedSize = sp.transformedSize

      let cropRect = sp.segment.cropRect ?? CGRect(
        origin: .zero,
        size: transformedSize
      )

      let sf = min(
        slotRect.width / cropRect.width,
        slotRect.height / cropRect.height
      )

      let playerLayerWidth = transformedSize.width * sf
      let playerLayerHeight = transformedSize.height * sf

      let offsetX = -cropRect.origin.x * sf
        + (slotRect.width - cropRect.width * sf) / 2
      let offsetY = -cropRect.origin.y * sf
        + (slotRect.height - cropRect.height * sf) / 2

      playerLayer.frame = CGRect(
        x: offsetX,
        y: offsetY,
        width: playerLayerWidth,
        height: playerLayerHeight
      )

      containerLayer.addSublayer(playerLayer)
      layer.addSublayer(containerLayer)
      containerLayers.append(containerLayer)
    }

    CATransaction.commit()
  }
}

struct TrimmingPreviewView: UIViewRepresentable {
  let segmentPlayers: [TrimmingPlayerUseCase.SegmentPlayer]

  func makeUIView(context: Context) -> TrimmingPreviewUIView {
    let view = TrimmingPreviewUIView()
    return view
  }

  func updateUIView(_ uiView: TrimmingPreviewUIView, context: Context) {
    uiView.configure(with: segmentPlayers)
  }
}
