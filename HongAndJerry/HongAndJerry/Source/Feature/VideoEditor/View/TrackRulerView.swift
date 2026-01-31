import SwiftUI

struct TrackRulerView: View {
  @Environment(EditorViewModel.self) private var viewModel
  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if viewModel.totalDuration.seconds > 0 {
        let totalSeconds = Int(
          viewModel
            .totalDuration
            .seconds
            .rounded(.up)
        )
        ForEach(0..<totalSeconds, id: \.self) { second in
          VStack {
            if second % 5 == 0
                || second == totalSeconds
            {
              Text("\(second)s")
                .font(.SUITTimer)
                .foregroundColor(.inactive)
            } else {
              Rectangle()
                .fill(.inactive)
                .frame(width: 1, height: EditConstants.tickHeight)
            }
          }
          .frame(width: EditConstants.pixelsPerSecond)
        }
      }
    }
  }
}
