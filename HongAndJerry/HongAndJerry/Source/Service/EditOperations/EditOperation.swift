//
//  EditOperation.swift
//  HongAndJerry
//
//  Created by Rama on 7/17/25.
//

protocol EditOperation {
  func apply(on segments: [VideoSegment]) async throws -> EditResult
}


