//
//  ThumbnailView.swift
//  HongAndJerry
//
//  Created by Rama on 7/25/25.
//

import SwiftUI

struct ThumbnailView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let segment: VideoSegment
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(segment.thumbnails, id: \.self) { uiImage in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: EditConstants.pixelsPerSecond * 3,
                        height: EditConstants.thumbnailHeight
                    )
                    .clipped()
            }
        }
        .frame(
            width: EditConstants.convertTimeToOffset(segment.source.duration),
            height: EditConstants.thumbnailHeight
        )
        .offset(x: -(segment.startTime.seconds * EditConstants.pixelsPerSecond))
        .mask(alignment: .leading) {
            Rectangle()
                .frame(width: EditConstants.convertTimeToOffset(segment.trimmedDuration))
        }
        .overlay {
            if viewModel.selectedSegmentID == segment.id {
                Rectangle()
                    .stroke(.accent, lineWidth: 1)
            }
        }
    }
}
