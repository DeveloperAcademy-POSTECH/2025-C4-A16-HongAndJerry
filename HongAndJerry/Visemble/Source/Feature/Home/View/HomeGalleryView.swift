import SwiftUI
import Photos

struct HomeGalleryView: View {
  @EnvironmentObject var router: Router
  @State private var viewModel = HomeGalleryViewModel()
  @State private var currentOnboardingPage = 0

  private let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16)
  ]

  private let onboardingItems: [(text: String, imageName: String)] = [
    ("세 컷 비디오을 만들기 위한 비디오를 선택하세요", "onboarding0"),
    ("각 컷에 나올 영역을 선택하세요", "onboarding1"),
    ("만들어진 세컷 비디오를 확인하고 길이를 조절하세요", "onboarding2"),
    ("트랙을 터치하면, 하단에서 비디오 길이를 조절할 수 있어요 ", "onboarding3")
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
    .background(Color.background)
    .onAppear { viewModel.loadVideos(albumName: "Visemble") }
    .sheet(isPresented: Binding(
      get: { viewModel.selectedAsset != nil },
      set: { if !$0 { viewModel.closePlayer() } }
    )) {
      if let asset = viewModel.selectedAsset {
        playerView(for: asset)
      }
    }
  }
  
  @ViewBuilder
  private func galleryGridView() -> some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(viewModel.videos) { video in
          galleryGridItem(video: video)
            .onTapGesture { viewModel.selectAsset(video.asset) }
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
    VStack(spacing: 24) {
      Spacer()

      TabView(selection: $currentOnboardingPage) {
        ForEach(0..<onboardingItems.count, id: \.self) { index in
          onboardingPage(
            text: onboardingItems[index].text,
            imageName: onboardingItems[index].imageName
          )
          .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .frame(height: UIScreen.main.bounds.height * 0.6)

      pageIndicator()

      Spacer()
    }
  }

  @ViewBuilder
  private func onboardingPage(text: String, imageName: String) -> some View {
    VStack(spacing: 36) {
      Image(imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity)
      
      Text(text)
        .font(.SUITBody)
        .foregroundStyle(.inactive)
        .multilineTextAlignment(.center)
        .lineLimit(nil)

    }
  }

  @ViewBuilder
  private func pageIndicator() -> some View {
    HStack(spacing: 8) {
      ForEach(0..<onboardingItems.count, id: \.self) { index in
        Circle()
          .fill(index == currentOnboardingPage ? Color.accent : Color.font.opacity(0.3))
          .frame(width: 8, height: 8)
          .animation(.easeInOut(duration: 0.3), value: currentOnboardingPage)
      }
    }
  }

  @ViewBuilder
  private func playerView(for asset: PHAsset) -> some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        if viewModel.isLoadingVideo {
          ProgressView()
            .tint(.white)
        } else {
          PlayerView(player: viewModel.player)
            .aspectRatio(
              CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight),
              contentMode: .fit
            )
        }

        Spacer()

        VideoController(
          isPlaying: viewModel.isPlaying,
          currentTime: viewModel.currentTime,
          totalDuration: viewModel.totalDuration,
          onPlayPause: {
            if viewModel.isPlaying {
              Task { @MainActor in
                viewModel.pause()
              }
            } else {
              Task { @MainActor in
                viewModel.play()
              }
            }
          },
          onSeek: { time in
            Task { @MainActor in
              viewModel.seek(to: time)
            }
          }
        )
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
      }
    }
  }
}
