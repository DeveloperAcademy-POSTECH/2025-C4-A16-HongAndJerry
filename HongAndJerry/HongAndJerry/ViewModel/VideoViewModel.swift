//
//  VideoPlayerViewModel.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//

import SwiftUI
import AVKit
import Foundation

@Observable public final class VideoViewModel {
    var segments: [VideoSegment] = []
    var composition: AVMutableComposition = AVMutableComposition()
    var videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
    var videoTrackIDs: [CMPersistentTrackID] = []
    var audioTrackIDs: [CMPersistentTrackID] = []
    var totalDuration: CMTime = .zero
    
    var player: AVPlayer?
    var isPlaying: Bool = false
    
    init() {
        
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }
}

extension VideoViewModel {
    
    @MainActor
    func buildPlayer() async throws {
        // 1. Load initial video data
        try await loadInitialData()
        
        // 2. Create the composition from the video segments
        try await createComposition()
        
        // 3. Create the visual layout instructions
        createVerticalVideoComposition()
        
        // 4. Create the final player item
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        // 5. Initialize the player
        self.player = AVPlayer(playerItem: playerItem)
    }

    private func createComposition() async throws {
        self.composition = AVMutableComposition()
        self.videoTrackIDs = []
        self.audioTrackIDs = []
        self.totalDuration = .zero
        
        var currentTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
        
        for segment in segments {
            let asset = segment.asset
            
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                print("Video track not found for asset: \(asset)")
                continue
            }
            
            guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                print("Audio track not found for asset: \(asset)")
                continue
            }
            
            currentTrackID += 1
            let videoCompositionTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: currentTrackID)
            self.videoTrackIDs.append(currentTrackID)
            let videoTimeRange = try await videoTrack.load(.timeRange)
            do {
                try videoCompositionTrack?.insertTimeRange(videoTimeRange, of: videoTrack, at: .zero)
            } catch {
                print("Failed to insert video track: \(error)")
            }
            
            currentTrackID += 1
            let audioCompositionTrack = self.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: currentTrackID)
            self.audioTrackIDs.append(currentTrackID)
            let audioTimeRange = try await audioTrack.load(.timeRange)
            do {
                try audioCompositionTrack?.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)
            } catch {
                print("Failed to insert audio track: \(error)")
            }
            
            self.totalDuration = max(self.totalDuration, videoTimeRange.duration)
        }
    }

    private func createVerticalVideoComposition() {
        let renderSize = CGSize(width: 1080, height: 1920)
        
        self.videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: self.totalDuration)
        
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        let videoHeight = renderSize.height / 3
        
        for(index, trackID) in self.videoTrackIDs.enumerated() {
            guard let track = self.composition.track(withTrackID: trackID) else { continue }
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            
            let assetSize = track.naturalSize
            let scaleFactor = renderSize.width / assetSize.width
            
            let yPosition = (renderSize.height - (CGFloat(index + 1) * videoHeight))
            
            let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            let moveTransform = CGAffineTransform(translationX: 0, y: yPosition)
            let finalTransform = scaleTransform.concatenating(moveTransform)
            
            layerInstruction.setTransform(finalTransform, at: .zero)
            layerInstructions.append(layerInstruction)
        }
        
        mainInstruction.layerInstructions = layerInstructions.reversed()
        self.videoComposition.instructions = [mainInstruction]
    }

    private func loadInitialData() async throws {
        let video1 = try await VideoSegment.sample1()
        let video2 = try await VideoSegment.sample2()
        let video3 = try await VideoSegment.sample3()
        
        self.segments = [video1, video2, video3]
    }
}
