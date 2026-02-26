enum ButtonType {
  case next
  case plus
  case export
  case delete

  var title: String? {
    switch self {
    case .next:
      return "다음"
    case .plus:
      return "영상 만들기"
    case .export:
      return "내보내기"
    case .delete:
      return "삭제"
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
    case .delete:
      return "trash"
    }
  }
}
