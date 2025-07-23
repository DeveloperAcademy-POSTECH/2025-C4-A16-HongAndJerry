//
//  VideoSegment.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit
import Observation

/// 타임라인의 단일 비디오 클립을 나타내며, 고유하고 편집 가능한 미디어 조각입니다.
///
/// 이 객체는 앱의 여러 부분(예: ViewModel, 타임라인 뷰, 플레이어)에서 공유되고 수정되는
/// 고유한 개체이므로 참조 타입(`class`)입니다. `@Observable`을 사용하면 SwiftUI가
/// 속성 변경을 자동으로 감지하고 이에 따라 UI를 업데이트할 수 있습니다.
@Observable
class VideoSegment: Identifiable {
    /// SwiftUI 리스트 및 렌더링에 필수적인, 세그먼트를 위한 고유하고 안정적인 식별자입니다.
    let id: UUID = UUID()
    
    /// 이 세그먼트의 원본 비디오 데이터를 포함하는 기본 소스 에셋입니다.
    let source: VideoSource
    
    /// `source` 에셋의 시작점을 기준으로 한 세그먼트의 시작 시간입니다.
    var startTime: CMTime
    
    /// 트리밍 후 세그먼트의 지속 시간입니다.
    var trimmedDuration: CMTime
    
    /// 트리밍된 시간 범위 내의 비디오 콘텐츠를 나타내는 썸네일 이미지 모음입니다.
    /// 이 속성은 백그라운드 생성 프로세스를 통해 채워질 것입니다.
    var thumbnails: [UIImage] = []
    
    init(source: VideoSource) {
        self.source = source
        self.startTime = .zero
        self.trimmedDuration = source.duration
        
        Task {
            await generateThumbnails()
        }
    }
    
    /// 1초 간격으로 썸네일 이미지를 비동기적으로 생성하여 `thumbnails` 배열을 채웁니다.
    private func generateThumbnails() async {
        // UI 속성인 thumbnails 배열을 안전하게 비우기 위해 메인 액터에서 실행합니다.
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
                // UI 속성인 thumbnails 배열에 안전하게 접근하기 위해 메인 액터에서 실행합니다.
                await MainActor.run {
                    self.thumbnails.append(UIImage(cgImage: cgImage))
                }
            } catch {
                print("Failed to generate thumbnail at time \(time): \(error)")
            }
        }
    }
}
