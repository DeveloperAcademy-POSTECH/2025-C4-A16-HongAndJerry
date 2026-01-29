//
//  VideoTrackView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI


struct VideoTrackView: View {
    @Environment(VideoViewModel.self) private var viewModel
    let segment: VideoSegment

    var body: some View {
        ZStack(alignment: .leading) {
            ThumbnailView(segment: segment)
        }
        .frame(
            width: EditConstants.convertTimeToOffset(segment.source.duration),
            height: EditConstants.thumbnailHeight
        )
        .clipped()
        .onTapGesture {
            Task {
                await viewModel.activateTrimming(segmentID: segment.id)
            }
        }
        .background(Color.black)
        .contentShape(Rectangle())
    }
}

