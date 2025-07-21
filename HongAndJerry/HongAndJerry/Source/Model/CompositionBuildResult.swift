//
//  CompositionBuildResilt.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVFoundation

/// CompositionBuilder의 빌드 결과를 캡슐화하는 구조체입니다.
///
/// 이 구조체는 재생 준비가 완료된 최종 `AVPlayerItem`과
/// 비디오의 총 길이를 함께 담고 있습니다.
struct CompositionBuildResult {
    let playerItem: AVPlayerItem
    let totalDuration: CMTime
}
