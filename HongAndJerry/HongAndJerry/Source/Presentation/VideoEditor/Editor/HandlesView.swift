//
//  HandlesView.swift
//  HongAndJerry
//
//  Created by Rama on 7/25/25.
//

import SwiftUI

struct HandlesView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let segment: VideoSegment
    let trimmedTrackWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            if viewModel.selectedSegmentID == segment.id {
                HandleView(
                    handleType: .left,
                    segmentID: segment.id
                )
                
                Spacer()
                
                HandleView(
                    handleType: .right,
                    segmentID: segment.id
                )
            }
        }
        .frame(width: trimmedTrackWidth)
    }
}
