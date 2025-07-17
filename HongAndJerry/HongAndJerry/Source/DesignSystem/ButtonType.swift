//
//  ButtonType.swift
//  HongAndJerry
//
//  Created by Hong on 7/17/25.
//

enum ButtonType {
    case next
    case plus

    var title: String? {
        switch self {
        case .next:
            return "다음"
        case .plus:
            return nil
        }
    }

    var systemImageName: String? {
        switch self {
        case .next:
            return nil
        case .plus:
            return "plus"
        }
    }
}
