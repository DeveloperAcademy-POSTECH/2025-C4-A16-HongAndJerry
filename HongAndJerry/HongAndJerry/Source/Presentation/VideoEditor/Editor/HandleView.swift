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
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .frame(width: EditConstants.handleWidth)
            .foregroundStyle(.accent)
            .offset(x: viewModel.draggingHandleType == handleType ? viewModel.handleDragTranslation : 0)
            .overlay {
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(width: EditConstants.handleWidth * 0.2,
                           // TODO: rawVal 변경
                           height: 20)
            }
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
