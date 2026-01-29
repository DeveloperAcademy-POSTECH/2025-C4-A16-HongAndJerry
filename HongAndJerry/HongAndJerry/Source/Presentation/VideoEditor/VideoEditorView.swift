//
//  VideoEditorView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI



struct VideoEditorView: View {
    @State private var viewModel: VideoViewModel
    @Namespace private var videoAnimation

    init(segments: [VideoSegment]) {
        _viewModel = State(initialValue: VideoViewModel(segments: segments))
    }

    var body: some View {
        Group {
            if viewModel.isFullScreen {
                FullScreenPlayerView(namespace: videoAnimation)
            } else {
                EditorWorkspaceView(namespace: videoAnimation)
            }
        }
        .environment(viewModel)
        .navigationBarHidden(true)
    }
}

#Preview {
    @Previewable @State var segments: [VideoSegment] = []

    Group {
        if segments.isEmpty {
            ProgressView("Mock 데이터 로딩 중...")
        } else {
            VideoEditorView(segments: segments)
        }
    }
    .task {
        segments = await VideoSegment.mockList()
    }
}
