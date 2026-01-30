import Foundation

/// 타임라인 드래그 방향을 나타내는 열거형입니다.
enum DragDirection {
  /// 순방향 (미래로) 탐색을 나타냅니다.
  case forward
  /// 역방향 (과거로) 탐색을 나타냅니다.
  case backward
  /// 드래그 중이 아니거나 방향이 없는 상태를 나타냅니다.
  case none
}
