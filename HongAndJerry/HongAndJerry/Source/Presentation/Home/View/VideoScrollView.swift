import SwiftUI
import Photos

struct VideoScrollView: View {
    @Binding var viewModel: HomeViewModel
    @Binding var selectedAsset: PHAsset?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                spacing: 20
            ) {
                ForEach(viewModel.videos) { video in
                    VideoGridItemView(video: video)
                        .onTapGesture {
                            selectedAsset = video.asset
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

struct VideoGridItemView: View {
    let video: VideoAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VideoThumbnailView(video: video)

            Text(video.creationDateValue)
                .font(.SUITTimer)
                .foregroundStyle(.inactive)
        }
    }
}

struct VideoThumbnailView: View {
    let video: VideoAsset

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: video.thumbnail)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fill)
                .frame(height: thumbnailHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(video.durationValue)
                .font(.SUITTimer)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(6)
        }
    }

    private var aspectRatio: CGFloat {
        CGFloat(video.asset.pixelWidth) / CGFloat(video.asset.pixelHeight)
    }

    private var thumbnailHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let gridWidth = (screenWidth - 16 * 2 - 16) / 2
        return (gridWidth / aspectRatio) * 0.9
    }
}
