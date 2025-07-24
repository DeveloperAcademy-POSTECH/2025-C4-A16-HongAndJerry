//
//  ThumbnailView.swift
//  HongAndJerry
//
//  Created by Rama on 7/25/25.
//

import SwiftUI

struct ThumbnailView: View {
    let segment: VideoSegment
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(segment.thumbnails, id: \.self) { uiImage in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                // TODO: rawVal 수정
                    .frame(width: EditConstants.pixelsPerSecond * 3, height: EditConstants.pixelsPerSecond * 3 * (9 / 16))
                    .clipped()
            }
        }
    }
}
