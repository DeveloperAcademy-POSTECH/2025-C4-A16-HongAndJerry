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
    /// 환경으로부터 주입받는 뷰 모델입니다.
    @Environment(VideoViewModel.self) private var viewModel
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            EditorHeaderView(videoAsset: viewModel.getFinalVideoAsset())
            
            VideoPlayerView(playerController: viewModel.playerController)
                // 이 뷰가 "videoPlayer"라는 ID를 가짐을 선언하여
                // FullScreenPlayerView의 플레이어와 연결합니다.
                .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                .padding(.top, 21)
                .padding(.bottom, 8)
                .padding(.horizontal, 80)
            
            PlaybackControlsView()
            
            // ZStack을 사용하여 타임라인 위에 시간과 플레이헤드를 오버레이합니다.
            ZStack(alignment: .topLeading) {
                EditorTimelineView()
                
                // 중앙 플레이헤드
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .padding(.vertical, EditConstants.rulerHeight) // 상하 여백
                    .frame(maxWidth: .infinity) // ZStack 중앙 정렬을 위해
                
                // 시간 표시 텍스트
                Text("\(viewModel.playerController.currentTime.formattedString) / \(viewModel.playerController.totalDuration.formattedString)")
                    .font(.SUITTimer)
                    .foregroundColor(.white)
                    .frame(height: EditConstants.rulerHeight)
                    .background(
                        Rectangle().fill(.black)
                    )
                    .padding(.leading, 16)
            }
            .frame(height: UIScreen.main.bounds.height / 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
