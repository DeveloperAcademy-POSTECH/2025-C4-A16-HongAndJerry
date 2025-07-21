//
//  CMTime++.swift
//  HongAndJerry
//
//  Created by Gemini on 7/19/25.
//

import AVKit

// CMTime을 "MM:SS" 형식의 문자열로 변환하는 헬퍼
extension CMTime {
    var formattedString: String {
        let totalSeconds = seconds
        guard !totalSeconds.isNaN && !totalSeconds.isInfinite else {
            return "00:00"
        }
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
