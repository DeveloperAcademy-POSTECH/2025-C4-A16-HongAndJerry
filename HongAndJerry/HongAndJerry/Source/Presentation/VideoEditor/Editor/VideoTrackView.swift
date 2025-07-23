//
//  VideoTrackView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/21/25.
//

import SwiftUI

/// 타임라인에 표시되는 단일 비디오 트랙을 나타내는 뷰입니다.
struct VideoTrackView: View {
    let segment: VideoSegment
    let pixelsPerSecond: CGFloat

    var body: some View {
        // 각 썸네일은 2초 분량의 너비를 가집니다.
        let thumbnailWidth = pixelsPerSecond * 3
        // 16:9 비율에 맞춰 높이를 계산합니다.
        let thumbnailHeight = thumbnailWidth * (9 / 16)
        
        // 트랙의 전체 너비는 세그먼트의 길이에 비례합니다.
        let totalTrackWidth = segment.trimmedDuration.seconds * pixelsPerSecond

        HStack(spacing: 0) {
            // VideoSegment에서 생성된 썸네일 배열을 순회하며 표시합니다.
            ForEach(segment.thumbnails, id: \.self) { uiImage in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailWidth, height: thumbnailHeight)
                    .clipped()
            }
        }
        // 썸네일이 아직 로드되지 않았을 경우를 대비해 배경색을 지정합니다.
        .background(Color.gray.opacity(0.5))
        .frame(width: totalTrackWidth, height: thumbnailHeight)
    }
}
