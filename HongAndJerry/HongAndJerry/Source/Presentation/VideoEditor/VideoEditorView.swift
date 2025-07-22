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
    /// 편집기 상태를 관리하는 뷰 모델입니다.
    /// 이 뷰가 ViewModel의 생명주기를 소유합니다.
    @State private var viewModel: VideoViewModel
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
    @Namespace private var videoAnimation

    /// Crop 흐름에서 완성된 VideoSegment 배열을 받아 ViewModel을 초기화합니다.
    init(segments: [VideoSegment]) {
        if segments.isEmpty {
            _viewModel = State(initialValue: VideoViewModel())
        } else {
            // @State 객체를 외부 파라미터로 초기화하는 표준 방식입니다.
            _viewModel = State(initialValue: VideoViewModel(segments: segments))
        }
    }

    var body: some View {
        Group {
            // isFullScreen 상태에 따라 두 뷰를 전환합니다.
            if viewModel.isFullScreen {
                FullScreenPlayerView(namespace: videoAnimation)
            } else {
                EditorWorkspaceView(namespace: videoAnimation)
            }
        }
        .environment(viewModel)
    }
}

#Preview {
    VideoEditorView(segments: [])
}
