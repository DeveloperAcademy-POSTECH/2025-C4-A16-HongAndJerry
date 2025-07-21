//
//  VideoSegment++.swift
//  HongAndJerry
//
//  Created by Rama on 7/18/25.
//

import AVKit

#if DEBUG
extension VideoSegment {
    /// 실제 비디오 파일을 기반으로 VideoSegment의 단일 목(mock) 객체를 비동기적으로 생성합니다.
    static func mock(
        resourceName: String,
        resourceExtension: String
    ) async throws -> VideoSegment {
        let mockSource = try await VideoSource.mock(
            resourceName: resourceName,
            resourceExtension: resourceExtension
        )
        
        return VideoSegment(source: mockSource)
    }
    
    /// `Resources` 폴더에 있는 모든 샘플 비디오를 사용하여 `VideoSegment` 목 리스트를 비동기적으로 생성합니다.
    static func mockList() async -> [VideoSegment] {
        let videoResources = [
            ("video1", "MP4"),
            ("video2", "MOV"),
            ("video3", "MOV")
        ]
        
        var segments: [VideoSegment] = []
        for (name, ext) in videoResources {
            do {
                let segment = try await mock(resourceName: name, resourceExtension: ext)
                segments.append(segment)
            } catch {
                print("Failed to create mock segment for \(name).\(ext): \(error)")
            }
        }
        return segments
    }
}
#endif