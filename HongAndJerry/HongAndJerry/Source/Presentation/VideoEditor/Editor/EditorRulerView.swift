//
//  EditorRulerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI



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
