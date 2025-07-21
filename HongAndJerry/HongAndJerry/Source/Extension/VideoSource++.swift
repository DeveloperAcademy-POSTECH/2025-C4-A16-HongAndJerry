//
//  VideoSource++.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

#if DEBUG
extension VideoSource {
    /// 실제 비디오 파일을 기반으로 VideoSource의 목(mock) 객체를 생성합니다.
    ///
    /// - Parameters:
    ///   - resourceName: `Resources` 번들에 있는 비디오 파일의 이름 (확장자 제외).
    ///   - resourceExtension: 비디오 파일의 확장자 (예: "MP4", "MOV").
    /// - Returns: 생성된 `VideoSource` 객체. 파일이 없으면 fatalError가 발생합니다.
    static func mock(
        resourceName: String,
        resourceExtension: String
    ) async throws -> VideoSource {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            fatalError("Mock video file not found: \(resourceName).\(resourceExtension)")
        }
        
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return VideoSource(
            asset: asset,
            url: url.absoluteString,
            duration: duration
        )
    }
}
#endif
