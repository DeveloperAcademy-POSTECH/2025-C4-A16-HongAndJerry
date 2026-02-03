//
//  CompositionRepository.swift
//  HongAndJerry
//
//  Created by Claude on 1/30/26.
//

import Foundation

protocol CompositionRepository {
    func build(from segments: [VideoSegment]) async throws -> CompositionBuildResult
}
