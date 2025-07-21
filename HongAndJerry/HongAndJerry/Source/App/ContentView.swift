//
//  ContentView.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI

struct ContentView: View {
    /// 앱의 메인 뷰 모델입니다.
    /// `@State`로 선언하여 ContentView가 ViewModel의 생명주기를 소유하고 관리합니다.
    @State private var viewModel = VideoViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 비디오를 표시하는 뷰입니다.
            // viewModel의 playerController를 전달합니다.
            VideoPlayerView(playerController: viewModel.playerController)
                .padding(.horizontal, 80)
                .padding(.top, 21)
                .padding(.bottom, 8)
                .border(Color.white, width: 2)
            
            PlaybackControlsView(viewModel: viewModel)
            
            // TODO: 3단계 - EditorView 추가 영역
            Spacer() // 임시로 공간을 채웁니다.
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // VStack이 전체 공간을 차지하도록 설정
        .background(Color.black)
    }
}

#Preview {
    ContentView()
}
