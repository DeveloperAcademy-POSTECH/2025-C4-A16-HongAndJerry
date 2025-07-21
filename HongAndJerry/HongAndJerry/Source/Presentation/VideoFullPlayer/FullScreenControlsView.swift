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
    
    // 쓰로틀링을 위한 마지막 seek 실행 시간
    @State private var lastSeekTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.1 // 0.1초 간격으로 제한
    
    var body: some View {
        HStack(spacing: 15) {
            // 재생/일시정지 버튼
            Button {
                if viewModel.playerController.isPlaying {
                    viewModel.playerController.pause()
                } else {
                    viewModel.playerController.play()
                }
            } label: {
                Image(systemName: viewModel.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 17))
            }
            
            // 현재 시간
            Text(viewModel.playerController.currentTime.formattedString)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white)
            
            // 비디오 탐색 슬라이더
            Slider(
                value: $sliderValue
                , in: 0...viewModel.playerController.totalDuration.seconds
            ) {
                isEditing in
                self.isSeeking = isEditing
                if isEditing {
                    viewModel.playerController.pause()
                }
            }
            
            // 총 시간
            Text(viewModel.playerController.totalDuration.formattedString)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white)
            
            // 축소 버튼
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.isFullScreen = false
                }
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .foregroundColor(.white)
                    .font(.system(size: 17))
            }
        }
        .padding(.horizontal, 14)
        .onChange(of: viewModel.playerController.currentTime) {
            // 사용자가 슬라이더를 조작하고 있지 않을 때만, 외부의 시간 변화를 슬라이더에 반영합니다.
            if !isSeeking {
                sliderValue = viewModel.playerController.currentTime.seconds
            }
        }
        .onChange(of: sliderValue) {
            // 슬라이더 값이 바뀔 때 쓰로틀링을 적용하여 seek를 호출합니다.
            let now = Date.now.timeIntervalSinceReferenceDate
            if now - lastSeekTime > throttleInterval {
                if isSeeking {
                    viewModel.playerController.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 600))
                    lastSeekTime = now
                }
            }
        }
    }
}