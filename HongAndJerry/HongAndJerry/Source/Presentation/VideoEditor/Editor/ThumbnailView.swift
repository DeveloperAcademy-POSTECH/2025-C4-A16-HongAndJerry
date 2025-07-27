import SwiftUI

struct ThumbnailView: View {
    let segment: VideoSegment
    let trackWidth: CGFloat
    
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
            width: trackWidth,
            height: EditConstants.thumbnailHeight
        )
        .offset(x: -(segment.startTime.seconds * EditConstants.pixelsPerSecond))
    }
}
