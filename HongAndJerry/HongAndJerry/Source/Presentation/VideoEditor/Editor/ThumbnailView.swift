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
    let initialTrackWidth: CGFloat
    
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
            width: initialTrackWidth,
            height: EditConstants.thumbnailHeight
        )
        .offset(x: -(segment.startTime.seconds * EditConstants.pixelsPerSecond))
    }
}
