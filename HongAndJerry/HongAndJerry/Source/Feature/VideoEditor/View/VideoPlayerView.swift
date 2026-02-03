import SwiftUI
import AVKit

struct VideoPlayerView: View {
  @Environment(EditorViewModel.self) private var viewModel

  var body: some View {
    ZStack {
      if viewModel.isLoading {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(maxWidth: .infinity)
      } else {
        PlayerView(player: viewModel.player)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
