
//
//  AVAsset++.swift
//  HongAndJerry
//
//  Created by Gemini on 7/28/25.
//

import AVFoundation
import UIKit

// 비디오의 방향을 나타내는 열거형
enum VideoOrientation {
    case landscape
    case portrait
    case square
}

extension AVAsset {
    /// 비디오의 시각적 방향(가로, 세로, 정사각형)을 비동기적으로 계산하여 반환합니다.
    func orientation() async -> VideoOrientation? {
        // 1. 에셋에서 비디오 트랙을 가져옵니다.
        guard let track = try? await self.loadTracks(withMediaType: .video).first else {
            // 비디오 트랙이 없으면 방향을 알 수 없습니다.
            return nil
        }

        // 2. 트랙에서 naturalSize와 preferredTransform을 비동기로 로드합니다.
        guard
            let size = try? await track.load(.naturalSize),
            let transform = try? await track.load(.preferredTransform)
        else {
            return nil
        }

        // 3. transform을 적용하여 최종적으로 보여지는 시각적 크기를 계산합니다.
        let visualSize = size.applying(transform)

        // 4. 너비와 높이를 비교하여 방향을 결정합니다.
        //    (transform 적용 시 음수 값이 나올 수 있으므로 절대값을 사용합니다.)
        let width = abs(visualSize.width)
        let height = abs(visualSize.height)

        if width > height {
            return .landscape
        } else if height > width {
            return .portrait
        } else {
            return .square
        }
    }
}
