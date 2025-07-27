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
        let initialTrackWidth = EditConstants.convertTimeToOffset(segment.source.duration)
        let trimmedTrackWidth = EditConstants.convertTimeToOffset(segment.trimmedDuration)
        
        ZStack(alignment: .leading) {
            ThumbnailView(
                segment: segment,
                initialTrackWidth: initialTrackWidth
            )
            
            HandlesView(
                segment: segment,
                trimmedTrackWidth: trimmedTrackWidth
            )
        }
        .frame(
            width: initialTrackWidth,
            height: EditConstants.thumbnailHeight
        )
        .clipped()
        .onTapGesture {
            viewModel.selectSegment(segment.id)
        }
        .background(Color.black)
        .contentShape(Rectangle())
    }
}

