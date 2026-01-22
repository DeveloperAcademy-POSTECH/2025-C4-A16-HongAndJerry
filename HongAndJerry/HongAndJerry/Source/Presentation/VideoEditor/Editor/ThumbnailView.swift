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

    private var isLoading: Bool {
        segment.thumbnails.isEmpty
    }

    var body: some View {
        ZStack(alignment: .leading) {
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
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: EditConstants.convertTimeToOffset(segment.trimmedDuration))
            }
        }
        .overlay(alignment: .leading) {
            if viewModel.selectedSegmentID == segment.id {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.accent, lineWidth: 2)
                    .frame(width: EditConstants.convertTimeToOffset(segment.trimmedDuration))
            }
        }
    }
}
