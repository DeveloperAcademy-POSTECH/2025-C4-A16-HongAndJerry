import SwiftUI
import Photos

struct HomeGalleryView: View {
  @EnvironmentObject var router: Router
  @State private var viewModel = HomeGalleryViewModel()
  @State private var selectedAsset: PHAsset? = nil
  
  private let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16)
  ]
  
  var body: some View {
    VStack(alignment: .leading) {
      if viewModel.videos.isEmpty {
        emptyStateView()
      } else {
        galleryGridView()
      }
      
      CtaButton(buttonType: .plus, isDisabled: .constant(false)) {
        router.push(screen: .selectVideo)
      }
    }
    .sheet(isPresented: Binding(
      get: { selectedAsset != nil },
      set: { if !$0 { selectedAsset = nil } }
    )) {
      if let asset = selectedAsset {
        PHAssetPlayer(asset: asset)
      }
    }
    .background(Color.background)
    .onAppear { viewModel.loadVideos(albumName: "WVDO") }
  }
  
  @ViewBuilder
  private func galleryGridView() -> some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(viewModel.videos) { video in
          galleryGridItem(video: video)
            .onTapGesture { selectedAsset = video.asset }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
    }
  }
  
  @ViewBuilder
  private func galleryGridItem(video: VideoAsset) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      galleryThumbnailView(video: video)
      
      Text(video.creationDateValue)
        .font(.SUITTimer)
        .foregroundStyle(.inactive)
    }
  }
  
  @ViewBuilder
  private func galleryThumbnailView(video: VideoAsset) -> some View {
    let aspectRatio = CGFloat(video.asset.pixelWidth) / CGFloat(video.asset.pixelHeight)
    let screenWidth = UIScreen.main.bounds.width
    let gridWidth = (screenWidth - 16 * 2 - 16) / 2
    let thumbnailHeight = (gridWidth / aspectRatio) * 0.9
    
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
  
  @ViewBuilder
  private func emptyStateView() -> some View {
    VStack {
      Spacer()
      Text("아직 생성된 비디오가 없습니다")
        .frame(maxWidth: .infinity, alignment: .center)
        .font(.SUITTitle)
        .foregroundStyle(.inactive)
      Spacer()
    }
  }
}
