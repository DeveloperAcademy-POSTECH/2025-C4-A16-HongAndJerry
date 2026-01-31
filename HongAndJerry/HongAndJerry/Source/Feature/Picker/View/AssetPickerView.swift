import SwiftUI
import Photos

struct AssetPickerView: View {
  @EnvironmentObject var router: Router
  
  @State var viewModel = AssetPickerViewModel()
  
  var body: some View {
    ZStack {
      Color.background.ignoresSafeArea()
      
      VStack(spacing: 0) {
        if !viewModel.selectedVideos.isEmpty {
          selectedAssetsSection()
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: viewModel.selectedVideos)
        }
        
        assetPickerSection()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .hjNavigationBar(title: ExportNameSpace.AppMain.selectVideoTitle)
  }
  
  @ViewBuilder
  private func selectedAssetsSection() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 20) {
        ForEach(
          Array(viewModel.selectedVideos.enumerated()),
          id: \.element.localIdentifier
        ) { index, video in
          SelectedAssetThumbnailCell(video: video, index: index + 1) {
            viewModel.send(.removeSelection(video))
          }
        }
      }
      .padding(.vertical, 14)
      .padding(.leading, 28)
    }
    .frame(height: 100)
    .background(Color.background)
  }
  
  @ViewBuilder
  private func assetPickerSection() -> some View {
    ZStack {
      albumGridView()
        .animation(.easeInOut, value: viewModel.videos)
      
      VStack {
        Spacer()
        
        if viewModel.canProceedToEdit {
          CtaButton(buttonType: .next, isDisabled: .constant(false)) {
            router.push(screen: .editVideoRatio(viewModel.selectedVideos))
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private func albumGridView() -> some View {
    VStack {
      ScrollView {
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
          spacing: 2
        ) {
          ForEach(viewModel.videos, id: \.localIdentifier) { video in
            AlbumAssetThumbnailCell(
              video: video,
              isSelected: viewModel.selectedVideos.contains(video),
              selectionIndex: viewModel.getSelectionIndex(for: video),
              onTap: { viewModel.send(.toggleSelection(video)) }
            )
          }
        }
        .padding(.bottom, 70)
        .scrollIndicators(.hidden)
      }
    }
    .task { await viewModel.loadVideos() }
  }
}
