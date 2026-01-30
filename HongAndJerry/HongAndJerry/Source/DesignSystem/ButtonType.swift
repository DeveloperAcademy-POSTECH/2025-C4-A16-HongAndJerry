//
//  ButtonType.swift
//  HongAndJerry
//
//  Created by Hong on 7/17/25.
//

enum ButtonType {
  case next
  case plus
  case export
  
  var title: String? {
    switch self {
    case .next:
      return "다음"
    case .plus:
      return "비디오 만들기"
    case .export:
      return "내보내기"
    }
  }
  
  var systemImageName: String? {
    switch self {
    case .next:
      return nil
    case .plus:
      return "plus"
    case .export:
      return nil
    }
  }
}
