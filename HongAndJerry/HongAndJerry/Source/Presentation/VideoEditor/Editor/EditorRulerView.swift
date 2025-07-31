//
//  EditorRulerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI

/// 타임라인 상단에 시간 눈금을 표시하는 뷰입니다.
/// 이 뷰는 스스로 스크롤되지 않으며, 부모 뷰의 offset에 의해 위치가 결정됩니다.
struct EditorRulerView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if viewModel.playerController.totalDuration.seconds > 0 {
                let totalSeconds = Int(
                    viewModel
                        .playerController
                        .totalDuration
                        .seconds
                        .rounded(.up)
                )
                
                ForEach(0..<totalSeconds, id: \.self) { second in
                    VStack {
                        if second % 5 == 0
                            || second == totalSeconds
                        {
                            Text("\(second)s")
                                .font(.SUITTimer)
                                .foregroundColor(.inactive)
                        } else {
                            Rectangle()
                                .fill(.inactive)
                                .frame(width: 1, height: EditConstants.tickHeight)
                        }
                    }
                    .frame(width: EditConstants.pixelsPerSecond)
                }
            }
        }
    }
}
