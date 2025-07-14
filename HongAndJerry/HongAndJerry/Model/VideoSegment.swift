
//
//  VideoSegment.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//

import AVKit
import Foundation
import AVFoundation

struct VideoSegment: Identifiable {
    let id: UUID = UUID()
    let origin: VideoSource
    let asset: AVAsset
    let trimStartTime: CMTime
    let trimEndTime: CMTime
    let cropX: CGFloat
    let cropY: CGFloat
    let cropWidth: CGFloat
    let cropHeight: CGFloat
}

extension VideoSegment {
    static func sample1() async throws -> VideoSegment {
        let url = Bundle.main.url(forResource: "video1", withExtension: "MP4")!
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        
        let origin = VideoSource(
            asset: asset,
            url: url.absoluteString,
            duration: duration
        )
        
        return VideoSegment(
            origin: origin,
            asset: asset,
            trimStartTime: .zero,
            trimEndTime: duration,
            cropX: 0,
            cropY: 0,
            cropWidth: 1,
            cropHeight: 1
        )
    }
    
    static func sample2() async throws -> VideoSegment {
        let url = Bundle.main.url(forResource: "video2", withExtension: "MOV")!
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        
        let origin = VideoSource(
            asset: asset,
            url: url.absoluteString,
            duration: duration
        )
        
        return VideoSegment(
            origin: origin,
            asset: asset,
            trimStartTime: .zero,
            trimEndTime: duration,
            cropX: 0,
            cropY: 0,
            cropWidth: 1,
            cropHeight: 1
        )
    }
    
    static func sample3() async throws -> VideoSegment {
        let url = Bundle.main.url(forResource: "video3", withExtension: "MOV")!
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        
        let origin = VideoSource(
            asset: asset,
            url: url.absoluteString,
            duration: duration
        )
        
        return VideoSegment(
            origin: origin,
            asset: asset,
            trimStartTime: .zero,
            trimEndTime: duration,
            cropX: 0,
            cropY: 0,
            cropWidth: 1,
            cropHeight: 1
        )
    }
}

