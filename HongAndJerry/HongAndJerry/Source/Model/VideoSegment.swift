//
//  VideoSegment.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit
import Observation

@Observable
class VideoSegment: Identifiable {
    let id: UUID = UUID()
    let source: VideoSource
    var startTime: CMTime
    var trimmedDuration: CMTime
    var thumbnails: [UIImage]
    var isMuted: Bool
    
    var endTime: CMTime {
        startTime + trimmedDuration
    }
    
    init(source: VideoSource) {
        self.source = source
        self.startTime = .zero
        self.trimmedDuration = source.duration
        self.isMuted = false
        self.thumbnails = []
        
        Task {
            await generateThumbnails()
        }
    }
    
    private func generateThumbnails() async {
        await MainActor.run {
            self.thumbnails.removeAll()
        }
        
        let asset = self.source.asset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let totalDurationSeconds = self.trimmedDuration.seconds
        guard totalDurationSeconds > 0 else { return }
        
        // 2초 간격으로 CMTime 배열 생성
        let times: [CMTime] = stride(from: 0, to: totalDurationSeconds, by: 3).map { second in
            let timeValue = self.startTime.seconds + second
            return CMTime(seconds: timeValue, preferredTimescale: 600)
        }

        for time in times {
            do {
                let cgImage = try await imageGenerator.image(at: time).image
                await MainActor.run {
                    self.thumbnails.append(UIImage(cgImage: cgImage))
                }
            } catch {
                print("Failed to generate thumbnail at time \(time): \(error)")
            }
        }
    }
}
