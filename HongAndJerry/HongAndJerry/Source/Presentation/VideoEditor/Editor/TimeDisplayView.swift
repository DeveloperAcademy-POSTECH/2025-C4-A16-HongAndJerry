//
//  TimeDisplayView.swift
//  HongAndJerry
//
//  Created by Rama on 1/22/26.
//

import SwiftUI

struct TimeDisplayView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    var body: some View {
        Text("\(viewModel.playerController.currentTime.formattedString) / \(viewModel.playerController.totalDuration.formattedString)")
            .font(.SUITTimer)
            .foregroundColor(.white)
            .frame(height: EditConstants.rulerHeight)
            .background(Rectangle().fill(.black))
            .padding(.leading, 16)
    }
}
