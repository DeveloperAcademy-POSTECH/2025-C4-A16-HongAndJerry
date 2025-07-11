//
//  VideoSource.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//
import AVKit
import Foundation

struct VideoSource {
    var asset: AVAsset
    var url: String
    var duration: CMTime
    
    init(
        asset: AVAsset,
        url: String,
        duration: CMTime
    ) {
        self.asset = asset
        self.url = url
        self.duration = duration
    }
}
