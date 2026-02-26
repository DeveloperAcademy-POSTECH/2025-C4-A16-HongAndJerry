import SwiftUI

extension View {
  func hjNavigationBar(title: String) -> some View {
    self.modifier(HJNavigationBar(title: title) { EmptyView() })
  }

  func hjNavigationBar<TrailingContent: View>(
    title: String,
    @ViewBuilder trailingContent: () -> TrailingContent
  ) -> some View {
    self.modifier(HJNavigationBar(title: title, trailingContent: trailingContent))
  }
}
