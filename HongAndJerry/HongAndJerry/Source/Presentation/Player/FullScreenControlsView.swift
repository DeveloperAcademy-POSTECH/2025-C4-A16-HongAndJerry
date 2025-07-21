//
//  FullScreenControlsView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/19/25.
//

import SwiftUI
import AVKit

/// 전체 화면 모드에서 사용될 컨트롤 뷰입니다.
struct FullScreenControlsView: View {
    var viewModel: VideoViewModel
    
    @State private var isSeeking = false
    @State private var sliderValue: Double = 0

    var body: some View {
        HStack(spacing: 15) {
            // 재생/일시정지 버튼
            Button(action: {
                if viewModel.playerController.isPlaying {
                    viewModel.playerController.pause()
                } else {
                    viewModel.playerController.play()
                }
            }) {
                Image(systemName: viewModel.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }

            // 현재 시간
            Text(viewModel.playerController.currentTime.formattedString)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white)

            // 비디오 탐색 슬라이더
            Slider(value: $sliderValue, in: 0...viewModel.playerController.totalDuration.seconds) {
                isEditing in
                self.isSeeking = isEditing
                if !isEditing {
                    viewModel.playerController.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 600))
                }
            }

            // 총 시간
            Text(viewModel.playerController.totalDuration.formattedString)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white)

            // 축소 버튼
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.isFullScreen = false
                }
            }) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
        .padding()
        .onChange(of: viewModel.playerController.currentTime) {
            if !isSeeking {
                sliderValue = viewModel.playerController.currentTime.seconds
            }
        }
    }
}
