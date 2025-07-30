//
//  CompositionBuilder.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Foundation
import AVFoundation

enum CompositionBuildError: Error {
    case failedToCreateVerticalVideoComposition
    case failedToAddTrack
    case noValidTracks
}

enum TrackTypes {
    struct VideoTrackInfo {
        let trackID: CMPersistentTrackID
        let duration: CMTime
    }
    
    struct AudioTrackInfo {
        let trackID: CMPersistentTrackID
    }
}

typealias AddTracksResult = (
    video: [TrackTypes.VideoTrackInfo],
    audio: [TrackTypes.AudioTrackInfo]
)


@MainActor
struct CompositionBuilder {
    
    /// VideoSegment 배열로부터 재생 가능한 AVPlayerItem을 빌드합니다.
    ///
    /// 이 메서드는 빌더의 메인 진입점입니다. 컴포지션 생성을 조율하고,
    /// 필요한 비디오 변환을 적용한 후, `CompositionBuildResult`를 반환합니다.
    ///
    /// - Parameter segments: 결합할 `VideoSegment` 객체의 배열.
    /// - Returns: `AVPlayerItem`과 총 길이를 담은 `CompositionBuildResult`.
    /// - Throws: 내부 AVFoundation 작업 중 하나라도 실패할 경우 에러를 던집니다.
    func build(from segments: [VideoSegment]) async throws -> CompositionBuildResult {
        
        let composition = AVMutableComposition()
        var totalDuration: CMTime = .zero
        
        let (video, _) = try await addTracks(to: composition, from: segments, totalDuration: &totalDuration)
        
        let videoComposition = try await createVerticalVideoComposition(
            composition: composition,
            trackInfos: video,
            totalDuration: totalDuration
        )
        
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        return CompositionBuildResult(
            playerItem: playerItem,
            totalDuration: totalDuration
        )
    }
    
    private func addTracks(
        to composition: AVMutableComposition,
        from segments: [VideoSegment],
        totalDuration: inout CMTime
    ) async throws -> AddTracksResult {
        var videoTrackInfos: [TrackTypes.VideoTrackInfo] = []
        var audioTrackInfos: [TrackTypes.AudioTrackInfo] = []

        for segment in segments {
            let asset = segment.source.asset
            
            let timeRange = CMTimeRange(
                start: segment.startTime,
                duration: segment.trimmedDuration
            )
            
            if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
                if let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) {
                    try compositionTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
                    videoTrackInfos.append(
                        TrackTypes.VideoTrackInfo(
                            trackID: compositionTrack.trackID,
                            duration: timeRange.duration
                        )
                    )
                }
            }

            // 오디오 트랙 추가
            if(!segment.isMuted) {
                if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    if let compositionTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    ) {
                        try compositionTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                        audioTrackInfos.append(
                            TrackTypes.AudioTrackInfo(
                                trackID: compositionTrack.trackID,
                            )
                        )
                    }
                }
            }
            
            // 가장 긴 길이를 totalDuration으로 설정
            totalDuration = max(totalDuration, timeRange.duration)
        }
        
        guard !videoTrackInfos.isEmpty else {
            throw CompositionBuildError.noValidTracks
        }
        
        return (video: videoTrackInfos, audio: audioTrackInfos)
    }
    
    /// 트랙을 수직으로 배열하기 위한 비디오 컴포지션을 생성합니다.
    private func createVerticalVideoComposition(
        composition: AVMutableComposition,
        trackInfos: [TrackTypes.VideoTrackInfo],
        totalDuration: CMTime
    ) async throws -> AVMutableVideoComposition {
        let renderSize = CGSize(width: 1080, height: 1821)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: totalDuration)
        
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        let videoHeight = renderSize.height / CGFloat(trackInfos.count)
        
        for (index, trackInfo) in trackInfos.enumerated() {
            
            let trackID = trackInfo.trackID
            let duration = trackInfo.duration
            
            guard let track = composition.track(withTrackID: trackID) else { continue }
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            let assetSize = track.naturalSize
            
            // --- 변환 계산 ---
            // 1. 너비에 맞게 스케일 조정
            let scaleFactor = renderSize.width / assetSize.width
            let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            
            // 2. 할당된 슬롯 내에서 비디오를 수직으로 중앙 정렬
            let scaledAssetHeight = assetSize.height * scaleFactor
            let yOffset = (videoHeight - scaledAssetHeight) / 2
            
            // 3. 위에서부터 슬롯 위치 지정
            let yPosition = ((CGFloat(index + 1) * videoHeight) + yOffset) - (renderSize.height / 3)
            
            let moveTransform = CGAffineTransform(translationX: 0, y: yPosition)
            
            // 4. 변환 결합
            let finalTransform = scaleTransform.concatenating(moveTransform)
            // --- 변환 계산 종료 ---

            layerInstruction.setOpacity(0.0, at: duration)
            
            layerInstruction.setTransform(finalTransform, at: .zero)
            layerInstructions.append(layerInstruction)
        }
        
        mainInstruction.layerInstructions = layerInstructions.reversed()
        videoComposition.instructions = [mainInstruction]
        
        return videoComposition
    }
}
