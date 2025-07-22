//
//  FullScreenPlayerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/19/25.
//

import SwiftUI

/// 비디오를 전체 화면으로 보여주는 뷰입니다.
struct FullScreenPlayerView: View {
    /// 앱의 메인 뷰 모델입니다.
    var viewModel: VideoViewModel
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            // 1. 비디오 플레이어 뷰
            VideoPlayerView(playerController: viewModel.playerController)
                // 이 뷰가 "videoPlayer"라는 ID를 가짐을 선언하여
                // EditorWorkspaceView의 플레이어와 연결합니다.
                .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            // 2. 전체 화면용 컨트롤러
            FullScreenControlsView(viewModel: viewModel)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
