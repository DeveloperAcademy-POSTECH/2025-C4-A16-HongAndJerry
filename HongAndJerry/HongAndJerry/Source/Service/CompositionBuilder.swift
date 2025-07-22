//
//  CompositionBuilder.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Foundation
import AVFoundation

/// 여러 비디오 세그먼트로부터 AVPlayerItem을 만드는 역할을 전담하는 상태 없는 빌더입니다.
///
/// 이 빌더는 다음과 같은 모든 AVFoundation 관련 로직을 캡슐화합니다:
/// 1. AVMutableComposition 생성
/// 2. 여러 VideoSegment 객체로부터 비디오 및 오디오 트랙 추가
/// 3. AVMutableVideoComposition을 사용하여 비디오 트랙을 수직으로 배열
/// 4. 모든 것을 최종 AVPlayerItem으로 결합
///
/// 이 로직을 중앙에서 관리함으로써 VideoViewModel을 AVFoundation의 복잡성에서 분리하고,
/// 상태 관리에만 집중할 수 있도록 합니다.
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
        // 1. 기본 컴포지션 생성
        let composition = AVMutableComposition()
        var totalDuration: CMTime = .zero
        
        // 2. 트랙을 추가하고 전체 길이를 계산합니다.
        // (private addTracks 메서드 호출)
        let trackIDs = try await addTracks(to: composition, from: segments, totalDuration: &totalDuration)
        
        // 3. 비디오 레이아웃을 위한 비디오 컴포지션 생성
        // (private createVerticalVideoComposition 메서드 호출)
        let videoComposition = createVerticalVideoComposition(
            composition: composition,
            trackIDs: trackIDs.video,
            totalDuration: totalDuration
        )
        
        // 4. 최종 플레이어 아이템 생성
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        // 5. 결과 반환
        return CompositionBuildResult(
            playerItem: playerItem,
            totalDuration: totalDuration
        )
    }
    
    /// 세그먼트의 비디오/오디오 트랙을 컴포지션에 추가합니다.
    private func addTracks(
        to composition: AVMutableComposition,
        from segments: [VideoSegment],
        totalDuration: inout CMTime
    ) async throws -> (video: [CMPersistentTrackID], audio: [CMPersistentTrackID]) {
        var videoTrackIDs: [CMPersistentTrackID] = []
        var audioTrackIDs: [CMPersistentTrackID] = []

        for segment in segments {
            let asset = segment.source.asset
            // 중요: 트림된 시간 범위(시작 시간, 지속 시간)를 정확히 사용합니다.
            let timeRange = CMTimeRange(start: segment.startTime, duration: segment.trimmedDuration)

            // 비디오 트랙 추가
            if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
                // AVFoundation이 자동으로 트랙 ID를 할당하도록 합니다.
                if let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try compositionTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
                    // 할당된 실제 ID를 배열에 추가합니다.
                    videoTrackIDs.append(compositionTrack.trackID)
                }
            }

            // 오디오 트랙 추가
            if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                // AVFoundation이 자동으로 트랙 ID를 할당하도록 합니다.
                if let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try compositionTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                    // 할당된 실제 ID를 배열에 추가합니다.
                    audioTrackIDs.append(compositionTrack.trackID)
                }
            }
            // 가장 긴 길이를 totalDuration으로 설정
            totalDuration = max(totalDuration, timeRange.duration)
        }
        return (videoTrackIDs, audioTrackIDs)
    }
    
    /// 트랙을 수직으로 배열하기 위한 비디오 컴포지션을 생성합니다.
    private func createVerticalVideoComposition(
        composition: AVMutableComposition,
        trackIDs: [CMPersistentTrackID],
        totalDuration: CMTime
    ) -> AVMutableVideoComposition {
        let renderSize = CGSize(width: 1080, height: 1821)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: totalDuration)
        
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        let videoHeight = renderSize.height / CGFloat(trackIDs.count)
        
        for (index, trackID) in trackIDs.enumerated() {
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
            let yPosition = renderSize.height - (CGFloat(index + 1) * videoHeight) + yOffset
            let moveTransform = CGAffineTransform(translationX: 0, y: yPosition)
            
            // 4. 변환 결합
            let finalTransform = scaleTransform.concatenating(moveTransform)
            // --- 변환 계산 종료 ---
            
            layerInstruction.setTransform(finalTransform, at: .zero)
            layerInstructions.append(layerInstruction)
        }
        
        mainInstruction.layerInstructions = layerInstructions.reversed()
        videoComposition.instructions = [mainInstruction]
        
        return videoComposition
    }
}
