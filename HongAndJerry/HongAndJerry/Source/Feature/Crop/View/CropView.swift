import SwiftUI
import Photos

struct CropView: View {
  @EnvironmentObject var router: Router
  
  @Bindable var viewModel: CropViewModel
  
  var body: some View {
    ZStack(alignment: .bottom) {
      Color.background.ignoresSafeArea()
      VStack {
        pageIndicator()
        
        cropTabView()
          .onAppear {
            viewModel.send(.loadVideos)
          }
        
        nextButton()
      }
      
    }
    .hjNavigationBar(title: ExportNameSpace.AppMain.cropVideoTitle)
  }
  
  @ViewBuilder
  private func cropTabView() -> some View {
      TabView(selection: $viewModel.currentIndex) {
        ForEach(
          Array(viewModel.selectedVideos.enumerated()),
          id: \.1.localIdentifier
        ) { index, video in
          selectedVideoTab(index: index)
            .tag(index)
        }
      }
      .indexViewStyle(.page(backgroundDisplayMode: .never))
      .tabViewStyle(.page(indexDisplayMode: .never))
      .onChange(of: viewModel.currentIndex) { _, _ in
        viewModel.send(.pause)
        viewModel.send(.seek(to: .zero))
      }
  }
  
  @ViewBuilder
  private func selectedVideoTab(index: Int) -> some View {
    Group {
      if index < viewModel.crops.count {
        let crop = viewModel.crops[index]
        let video = crop.video
        let aspectRatio = CGFloat(video.pixelWidth) / CGFloat(video.pixelHeight)

        VStack(spacing: 0) {
          Spacer()

          ZStack {
            if !viewModel.isLoading {
              PlayerView(player: viewModel.player)
                .aspectRatio(aspectRatio, contentMode: .fit)
            } else {
              Image(uiImage: crop.thumbnail)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fit)
            }
          }
          .overlay(alignment: .topLeading) {
            GeometryReader { geometry in
              CropBoxView(
                rect: viewModel.bindingForCropRect(at: index),
                viewModel: viewModel,
                index: index
              )
              .allowsHitTesting(true)
              .onAppear {
                handleThumbnailAppear(videoIndex: index, geometry: geometry, crop: crop)
              }
              .onChange(of: geometry.size) { oldValue, newValue in
                viewModel.send(.setContainerSize(newValue, at: index))
              }
            }
          }
          .clipped()
          
          Spacer()

          VideoController(
            isPlaying: viewModel.isPlaying,
            currentTime: viewModel.currentTime,
            totalDuration: viewModel.totalDuration,
            onPlayPause: {
              if viewModel.isPlaying {
                viewModel.send(.pause)
              } else {
                viewModel.send(.play)
              }
            },
            onSeek: { time in
              viewModel.send(.seek(to: time))
            }
          )
          .padding(.vertical, 16)
          .padding(.horizontal, 4)
        }
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


extension CropView {
  private func handleThumbnailAppear(videoIndex: Int, geometry: GeometryProxy, crop: Crop) {
    viewModel.send(.setContainerSize(geometry.size, at: videoIndex))
    if crop.cropRect == CGRect(x: 0, y: 0, width: 10, height: 10) {
      let initialRect = viewModel.calculate16x9CropRect(in: geometry.size)
      viewModel.updateCropRect(at: videoIndex, rect: initialRect)
    }
  }
  
  private func handleNextButtonTap() {
    router.push(screen: .videoEditView(viewModel.crops))
  }
}
