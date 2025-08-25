//
//  EditResult.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Foundation

enum EditResult {
    case segmentsUpdated([VideoSegment])
    case exportCompleted(URL)
    case noChange
}
