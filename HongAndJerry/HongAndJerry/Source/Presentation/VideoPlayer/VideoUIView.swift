//
//  VideoUIView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/12/25.
//

import UIKit
import AVFoundation

class VideoUIView: UIView {
    
    // MARK: - Properties
    
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
    
    // MARK: - Lifecycle
    
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    // MARK: - Init
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.player = player
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
