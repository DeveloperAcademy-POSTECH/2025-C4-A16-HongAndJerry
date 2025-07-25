//
//  FrameView.swift
//  HongAndJerry
//
//  Created by Hong on 7/24/25.
//

import SwiftUI

struct FrameView {
    @Binding var frameSelected: Bool
    @Binding var viewModel: FrameSelectViewModel
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
}

extension FrameView: View {
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.frames) { frame in
                Button {
                    frameSelected.toggle()
                    viewModel.getImage(isFrameSelected: !frameSelected)
                } label: {
                    frame.image
                        .resizable()
                        .frame(width: 100, height: 180)
                }
                .disabled(frame.image == Image(.comingSoon))
            }
        }
    }
}
