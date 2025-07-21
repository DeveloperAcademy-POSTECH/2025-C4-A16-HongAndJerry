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
    
    /// 뷰 전환 애니메이션을 위한 네임스페이스입니다.
    @Namespace private var videoAnimation

    var body: some View {
        // isFullScreen 상태에 따라 다른 뷰를 보여줍니다.
        if viewModel.isFullScreen {
            FullScreenPlayerView(viewModel: viewModel, namespace: videoAnimation)
        } else {
            EditorWorkspaceView(viewModel: viewModel, namespace: videoAnimation)
        }
    }
}

#Preview {
    ContentView()
}
