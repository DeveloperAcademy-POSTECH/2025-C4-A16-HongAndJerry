//
//  HandleView.swift
//  HongAndJerry
//
//  Created by Rama on 7/23/25.
//

import SwiftUI

struct HandleView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let handleType: HandleType
    let trackWidth: CGFloat
    let segmentID: UUID
    
    var body: some View {
        Rectangle()
            .frame(width: EditConstants.handleWidth)
            .foregroundStyle(.yellow)
            .offset(
                x: viewModel.getHandleOffset(
                    segmentID: segmentID,
                    handleType: handleType,
                    trackWidth: trackWidth
                )
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.onHandleDrag(
                            type: handleType,
                            translation: value.translation.width
                        )
                    }
                    .onEnded { _ in
                        Task { await viewModel.onHandleDragEnd() }
                    }
            )
    }
}
