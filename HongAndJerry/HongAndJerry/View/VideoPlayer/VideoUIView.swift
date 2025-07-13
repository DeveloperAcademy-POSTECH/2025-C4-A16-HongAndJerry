
//
//  VideoPlayerUIView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/12/25.
//

import UIKit
import AVFoundation

class VideoUIView: UIView {
    
    // MARK: - Properties
    
    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    // MARK: - Lifecycle
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
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
