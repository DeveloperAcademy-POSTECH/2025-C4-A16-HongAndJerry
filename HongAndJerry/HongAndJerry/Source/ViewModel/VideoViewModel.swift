//
//  VideoViewModel.swift
//  HongAndJerry
//
//  Created by Gemini on 7/18/25.
//

import Foundation
import AVKit
import Observation

/// 앱의 모든 비디오 편집 상태와 비즈니스 로직을 총괄하는 중앙 허브입니다.
///
/// 이 ViewModel은 "Executive Producer" 역할을 수행하며, 다음을 책임집니다:
/// - `VideoSegment` 배열을 "Single Source of Truth"로 관리합니다.
/// - `CompositionBuilder`를 사용하여 AVFoundation 컴포지션을 생성합니다.
/// - `PlayerController`를 통해 비디오 재생을 제어합니다.
/// - UI로부터 모든 편집 요청(예: 트림, 순서 변경)을 받아 처리합니다.
@MainActor
@Observable
class VideoViewModel {
    /// 프로젝트의 현재 상태를 나타내는 비디오 세그먼트의 배열입니다. 이 배열이 앱의 유일한 진실 공급원(Source of Truth)입니다.
    var segments: [VideoSegment] = []
    
    /// 비디오 재생을 관리하는 `AVPlayer`의 래퍼(wrapper)입니다.
    let playerController = PlayerController()
    
    /// 컴포지션 생성을 담당하는 상태 없는(stateless) 빌더입니다.
    private let compositionBuilder = CompositionBuilder()

    /// 현재 비디오 플레이어가 전체 화면 모드인지 여부를 나타냅니다.
    var isFullScreen: Bool = false
    
    init() {
        // 비동기 초기화를 위해 Task를 사용합니다.
        Task {
            await loadInitialSegments()
            await rebuildPlayerItem()
        }
    }
    
    init(segments: [VideoSegment]) {
        Task {
            self.segments = segments
            await rebuildPlayerItem()
        }
    }
    
    /// 앱 시작 시 초기 비디오 세그먼트를 비동기적으로 로드합니다.
    /// `VideoSegment.mockList()` 비동기 함수를 사용합니다.
    private func loadInitialSegments() async {
        self.segments = await VideoSegment.mockList()
    }
    
    /// 현재 `segments` 배열의 상태를 기반으로 `AVPlayerItem`을 다시 빌드하고 플레이어를 업데이트합니다.
    /// 편집 작업(트림, 재정렬 등)이 발생할 때마다 호출되어야 합니다.
    func rebuildPlayerItem() async {
        do {
            // 세그먼트가 비어있으면 플레이어를 비웁니다.
            guard !segments.isEmpty else {
                playerController.replaceCurrentItem(with: nil)
                return
            }
            
            let buildResult = try await compositionBuilder.build(from: segments)
            playerController.replaceCurrentItem(with: buildResult.playerItem)
        } catch {
            print("플레이어 아이템을 다시 빌드하는 중 오류 발생: \(error)")
        }
    }
}
