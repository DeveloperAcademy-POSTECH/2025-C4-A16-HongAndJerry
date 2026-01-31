import SwiftUI
import AVKit

struct VideoPlayerView: View {
  @Environment(EditorViewModel.self) private var viewModel

  var body: some View {
    ZStack {
      PlayerView(player: viewModel.player)
        .frame(maxWidth: .infinity)
        .opacity(viewModel.isLoading ? 0 : 1)
    }
  }
}
