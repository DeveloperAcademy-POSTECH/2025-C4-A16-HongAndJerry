//
//  RoutingView.swift
//  HongAndJerry
//
//  Created by Hong on 7/21/25.
//

import SwiftUI
import Photos

struct RoutingView {
    @State var navigateDestination: Screen
    @EnvironmentObject var router: Router
}

extension RoutingView: View {
    var body: some View {
        switch navigateDestination {
        case .selectFrame:
            FrameSelectView().environment(router)
        case .selectVideo:
            GalleryView().environment(router)
        case .home:
            EmptyView()
        case .editVideoRatio(let assets):
            CropView(viewModel: .init(selectedVideos: assets))
        case .videoEditView(let segments):
            VideoEditorView(segments: segments)
        }
    }
}
