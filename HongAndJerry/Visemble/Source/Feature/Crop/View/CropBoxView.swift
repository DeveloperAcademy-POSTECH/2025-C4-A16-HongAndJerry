import SwiftUI

typealias CropBox = CropBoxView

struct CropBoxView: View {
  @State private var initialRect: CGRect? = nil
  
  @Binding public var rect: CGRect
  
  let viewModel: CropViewModel
  let index: Int
  
  public let minSize: CGSize
  
  public init(
    rect: Binding<CGRect>,
    viewModel: CropViewModel,
    index: Int,
    minSize: CGSize = .init(width: 10, height: 10)
  ) {
    self._rect = rect
    self.viewModel = viewModel
    self.index = index
    self.minSize = minSize
  }
  
  private var frameSize: CGSize {
    viewModel.getCropBoxState(at: index).frameSize
  }
  
  public var body: some View {
    ZStack(alignment: .topLeading) {
      blur
      box
    }
    .background {
      GeometryReader { geometry in
        Color.clear
          .onAppear {
            viewModel.setCropBoxFrameSize(geometry.size, at: index)
          }
          .onChange(of: geometry.size) { _, newSize in
            viewModel.setCropBoxFrameSize(newSize, at: index)
          }
      }
    }
  }
  
  @ViewBuilder
  private var blur: some View {
    GeometryReader { geometry in
      Path { path in
        path.addRect(CGRect(origin: .zero, size: geometry.size))

        path.addRect(CGRect(
          x: rect.origin.x,
          y: rect.origin.y,
          width: rect.width,
          height: rect.height
        ))
      }
      .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
    }
  }
  
  @ViewBuilder
  private var box: some View {
    ZStack {
      grid
    }
    .border(Color.accent, width: 1)
    .background(Color.white.opacity(0.001))
    .frame(width: rect.width, height: rect.height)
    .offset(x: rect.origin.x, y: rect.origin.y)
    .gesture(rectDrag)
  }
  
  @ViewBuilder
  private var grid: some View {
    ZStack {
      HStack {
        Spacer()
        Rectangle()
          .frame(width: 1)
          .frame(maxHeight: .infinity)
        Spacer()
        Rectangle()
          .frame(width: 1)
          .frame(maxHeight: .infinity)
        Spacer()
      }
      VStack {
        Spacer()
        Rectangle()
          .frame(height: 1)
          .frame(maxWidth: .infinity)
        Spacer()
        Rectangle()
          .frame(height: 1)
          .frame(maxWidth: .infinity)
        Spacer()
      }
    }
    .foregroundColor(.gray)
  }
}

extension CropBoxView {
  private var rectDrag: some Gesture {
    DragGesture()
      .onChanged { gesture in
        if initialRect == nil {
          initialRect = rect
          viewModel.handleCropBoxDragStarted(at: index, currentRect: rect)
        }
        
        self.rect = viewModel.handleCropBoxDragChanged(
          at: index,
          initialRect: initialRect!,
          frameSize: frameSize,
          translation: gesture.translation
        )
      }
      .onEnded { _ in
        initialRect = nil
        viewModel.handleCropBoxDragEnded(at: index)
      }
  }
}
