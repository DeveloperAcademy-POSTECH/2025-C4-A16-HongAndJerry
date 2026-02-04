import SwiftUI
import Photos

struct AlbumAssetThumbnailCell: View {
  let video: PHAsset
  let isSelected: Bool
  let selectionIndex: Int?
  let onTap: () -> Void
  
  @State private var thumbnail: UIImage?
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .overlay(
            Group {
              if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: geometry.size.width, height: geometry.size.height)
                  .clipped()
              }
            }
          )

        if video.duration > 0 && !isSelected {
          Text(formattedDuration(video.duration))
            .font(.SUITTimer)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.6))
            .cornerRadius(4)
            .padding(6)
            .frame(
              maxWidth: .infinity,
              maxHeight: .infinity,
              alignment: .bottomTrailing
            )
        }

        if isSelected {
          ZStack {
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color.accent, lineWidth: 2)
            if let index = selectionIndex {
              Text("\(index)")
                .font(.SUITTimer)
                .foregroundColor(.background)
                .frame(width: 20, height: 20)
                .background(Color.accent)
                .clipShape(Circle())
                .padding(12)
                .frame(
                  maxWidth: .infinity,
                  maxHeight: .infinity,
                  alignment: .bottomTrailing
                )
            }
          }
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .contentShape(Rectangle())
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .onTapGesture(perform: onTap)
    .onAppear {
      loadThumbnail()
    }
  }
  
  private func formattedDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = Int(duration)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func loadThumbnail() {
    let manager = PHImageManager.default()
    let option = PHImageRequestOptions()
    option.deliveryMode = .highQualityFormat
    option.isSynchronous = false
    manager.requestImage(
      for: video,
      targetSize: CGSize(width: 130, height: 130),
      contentMode: .aspectFill,
      options: option
    ) { image, _ in
      DispatchQueue.main.async {
        self.thumbnail = image
      }
    }
  }
}

