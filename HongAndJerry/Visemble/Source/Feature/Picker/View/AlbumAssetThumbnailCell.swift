import SwiftUI
import Photos

struct AlbumAssetThumbnailCell: View {
  let video: PHAsset
  let downloadState: AssetPickerViewModel.VideoDownloadState?
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

        bottomTrailingOverlay()

        if isSelected || downloadState != nil {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color.accent, lineWidth: 2)
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
  
  @ViewBuilder
  private func bottomTrailingOverlay() -> some View {
    if let downloadState = downloadState {
      switch downloadState {
      case .downloading(let progress):
        ZStack {
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
          Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.accent, lineWidth: 2)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 0.1), value: progress)
        }
        .frame(width: 20, height: 20)
        .padding(12)
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .bottomTrailing
        )

      case .completed:
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

      default:
        EmptyView()
      }
    } else if !isSelected && downloadState == nil {
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

