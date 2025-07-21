//
//  PlaybackControlsView.swift
//  HongAndJerry
//
//  Created by Gemini on 7/18/25.
//

import SwiftUI

/// 비디오 재생을 제어하는 버튼(재생/일시정지, 전체 화면)을 포함하는 뷰입니다.
struct PlaybackControlsView: View {
    /// 앱의 상태를 관리하는 뷰 모델입니다.
    var viewModel: VideoViewModel

    var body: some View {
        HStack {
            // 왼쪽 자리 차지용 뷰 (투명)
            Button(action: {}) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 17))
            }
            .opacity(0)
            .disabled(true)

            Spacer()

            // 재생/일시정지 버튼 (가운데)
            Button(action: {
                if viewModel.playerController.isPlaying {
                    viewModel.playerController.pause()
                } else {
                    viewModel.playerController.play()
                }
            }) {
                Image(systemName: viewModel.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }

            Spacer()

            // 전체 화면 버튼 (오른쪽)
            Button(action: {
                // TODO: 전체 화면 기능 구현
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 30)
    }
}
