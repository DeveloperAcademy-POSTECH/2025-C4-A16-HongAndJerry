//
//  EditorWorkspaceView.swift
//  HongAndJerry
//
//  Created by Gemini on 7/19/25.
//

import SwiftUI

/// 비디오 편집을 위한 기본 작업 공간 뷰입니다.
/// 일반 모드에서 플레이어, 컨트롤러, 타임라인 에디터를 포함합니다.
struct EditorWorkspaceView: View {
    /// 앱의 메인 뷰 모델입니다.
    var viewModel: VideoViewModel
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            VideoPlayerView(playerController: viewModel.playerController)
                // 이 뷰가 "videoPlayer"라는 ID를 가짐을 선언합니다.
                .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                .padding(.horizontal, 80)
                .padding(.top, 21)
                .padding(.bottom, 8)
                .border(Color.white, width: 2)
            
            PlaybackControlsView(viewModel: viewModel)
            
            // TODO: 3단계 - EditorView 추가 영역
            Spacer() // 임시로 공간을 채웁니다.
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
