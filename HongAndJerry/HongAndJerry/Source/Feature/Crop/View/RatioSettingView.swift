import SwiftUI
import Photos

struct RatioSettingView: View {
  @EnvironmentObject var router: Router
  
  @Bindable var viewModel: RatioSettingViewModel
  
  var body: some View {
    ZStack {
      Color.background.ignoresSafeArea()
      
      VStack {
        Group {
          switch viewModel.state {
          case .thumbnailLoading:
            loadingView()
          case .thumbnailLoaded:
            tabView()
          case .cropping:
            croppingView()
          case .completedConvertToAsset:
            Text("Complete")
          }
        }
      }
      .onAppear {
        viewModel.send(.loadThumbnail)
      }
    }
    .hjNavigationBar(title: ExportNameSpace.AppMain.cropVideoTitle)
  }

  @ViewBuilder
  private func loadingView() -> some View {
    ProgressView("로딩 중...")
      .frame(width: 300, height: 300)
  }

  @ViewBuilder
  private func croppingView() -> some View {
    ProgressView("자른 비디오 로딩 중...")
      .frame(width: 300, height: 300)
      .navigationBarBackButtonHidden()
  }
  
  @ViewBuilder
  private func tabView() -> some View {
    VStack {
      TabView(selection: $viewModel.currentIndex) {
        ForEach(
          Array(viewModel.selectedVideos.enumerated()),
          id: \.1.localIdentifier
        ) { index, video in
          thumbnailCell(videoIndex: index)
            .tag(index)
        }
      }
      .indexViewStyle(.page(backgroundDisplayMode: .never))
      .tabViewStyle(.page(indexDisplayMode: .never))
      
      pageIndicator()
        .padding(.vertical, 8)
      
      nextButton()
    }
  }
  
  @ViewBuilder
  private func thumbnailCell(videoIndex: Int) -> some View {
    Group {
      if videoIndex < viewModel.crops.count {
        let crop = viewModel.crops[videoIndex]
        Image(uiImage: crop.thumbnail)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .overlay(alignment: .topLeading) {
            GeometryReader { geometry in
              CropBoxView(
                rect: viewModel.bindingForCropRect(at: videoIndex),
                viewModel: viewModel,
                index: videoIndex
              )
              .allowsHitTesting(true)
              .onAppear {
                handleThumbnailAppear(videoIndex: videoIndex, geometry: geometry, crop: crop)
              }
              .onChange(of: geometry.size) { oldValue, newValue in
                viewModel.send(.setContainerSize(newValue, at: videoIndex))
              }
            }
          }
          .clipped()
      }
    }
  }
  
  @ViewBuilder
  private func pageIndicator() -> some View {
    HStack(spacing: 8) {
      ForEach(0..<viewModel.selectedVideos.count, id: \.self) { index in
        Circle()
          .fill(index == viewModel.currentIndex ? Color.font : Color.font.opacity(0.3))
          .frame(width: 8, height: 8)
          .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
      }
    }
  }
  
  @ViewBuilder
  private func nextButton() -> some View {
    CtaButton(
      buttonType: .next,
      isDisabled: .constant(viewModel.currentIndex != 2)
    ) {
      handleNextButtonTap()
    }
  }
}


extension RatioSettingView {
  private func handleThumbnailAppear(videoIndex: Int, geometry: GeometryProxy, crop: Crop) {
    viewModel.send(.setContainerSize(geometry.size, at: videoIndex))
    if crop.cropRect == CGRect(x: 0, y: 0, width: 10, height: 10) {
      let initialRect = viewModel.calculate16x9CropRect(in: geometry.size)
      viewModel.updateCropRect(at: videoIndex, rect: initialRect)
    }
  }
  
  private func handleNextButtonTap() {
    Task {
      await viewModel.cropVideos()
      let segments = await viewModel.createVideoSegments()
      router.push(screen: .videoEditView(segments))
    }
  }
}
