import SwiftUI

extension View {
  func hjNavigationBar(title: String) -> some View {
    self.modifier(HJNavigationBar(title: title))
  }
}
