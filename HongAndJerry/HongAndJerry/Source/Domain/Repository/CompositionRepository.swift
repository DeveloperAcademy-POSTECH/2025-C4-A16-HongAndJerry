//
//  CompositionRepository.swift
//  HongAndJerry
//
//  Created by Claude on 1/30/26.
//

import Foundation

/// Composition 생성을 추상화하는 Repository Interface
/// Domain Layer - 구현체에 의존하지 않음
protocol CompositionRepository {
    /// VideoSegment 배열로부터 AVPlayerItem을 생성
    /// - Parameter segments: 합성할 비디오 세그먼트들
    /// - Returns: 생성된 PlayerItem과 총 재생 시간
    func build(from segments: [VideoSegment]) async throws -> CompositionBuildResult
}
