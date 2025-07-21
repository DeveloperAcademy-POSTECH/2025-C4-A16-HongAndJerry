//
//  VideoPlayerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/18/25.
//

import SwiftUI
import AVKit

/// `PlayerController`의 `player`를 받아 화면에 비디오를 표시하는 SwiftUI 뷰입니다.
struct VideoPlayerView: View {
    /// 비디오 재생을 관리하는 플레이어 컨트롤러입니다.
    let playerController: PlayerController

    var body: some View {
        // 기존에 구현된 VideoView를 사용하여 player를 화면에 렌더링합니다.
        VideoView(player: playerController.player)
            .aspectRatio(9 / 16, contentMode: .fit)
            .background(Color.black)
    }
}
