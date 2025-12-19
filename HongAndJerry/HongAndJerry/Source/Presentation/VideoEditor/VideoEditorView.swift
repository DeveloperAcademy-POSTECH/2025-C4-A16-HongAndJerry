//
//  VideoEditorView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI

/// 비디오 편집 경험을 제공하는 최상위 컨테이너 뷰입니다.
/// EditorWorkspaceView와 FullScreenPlayerView 간의 전환을 관리합니다.
struct VideoEditorView: View {
    @State private var viewModel: VideoViewModel
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
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
    VideoEditorView(segments: [])
}
