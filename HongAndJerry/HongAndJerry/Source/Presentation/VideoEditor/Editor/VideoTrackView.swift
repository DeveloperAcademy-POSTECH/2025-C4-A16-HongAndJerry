//
//  VideoTrackView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI

/// 타임라인에 표시되는 단일 비디오 트랙을 나타내는 뷰입니다.
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
            guard !viewModel.isTrimming else { return }
            
            Task {
                await viewModel.activateTrimming(segmentID: segment.id)
            }
        }
        .background(Color.black)
        .contentShape(Rectangle())
    }
}

