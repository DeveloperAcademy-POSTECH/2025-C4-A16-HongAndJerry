import SwiftUI
import Photos

struct RoutingView {
    @State var navigateDestination: Screen
    @EnvironmentObject var router: Router
}

extension RoutingView: View {
    var body: some View {
        switch navigateDestination {
        case .home:
            EmptyView()
          
        case .selectVideo:
            AssetPickerView().environment(router)
          
        case .editVideoRatio(let assets):
            RatioSettingView(viewModel: .init(selectedVideos: assets))
          
        case .videoEditView(let segments):
            EditorView(segments: segments)
        }
    }
}
