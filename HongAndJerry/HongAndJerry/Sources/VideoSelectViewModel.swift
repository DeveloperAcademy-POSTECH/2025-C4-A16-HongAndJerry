
import SwiftUI
import PhotosUI
import AVFoundation

@MainActor final class VideoSelectViewModel: ObservableObject {
  @Published var selection = [PhotosPickerItem]() {
      didSet {
          // Update the attachments according to the current picker selection.
          let newAttachments = selection.map { item in
              // Access an existing attachment, if it exists; otherwise, create a new attachment.
              attachmentByIdentifier[item.identifier] ?? VideoAttachment(item)
          }
          // Update the saved attachments array for any new attachments loaded in scope.
          let newAttachmentByIdentifier = newAttachments.reduce(into: [:]) { partialResult, attachment in
              partialResult[attachment.id] = attachment
          }
          // To support asynchronous access, assign new arrays to the instance properties rather than updating the existing arrays.
          attachments = newAttachments
          attachmentByIdentifier = newAttachmentByIdentifier
      }
  }
  @Published var attachments = [VideoAttachment]()
  
  private var attachmentByIdentifier = [String: VideoAttachment]()
}


/// 사용자가 선택한 동영상
@MainActor final class VideoAttachment: ObservableObject, Identifiable {
  
//  let id = UUID().uuidString
  @Published var url: URL?
  @Published var thumbnail: Image?
  private let videoSelection: PhotosPickerItem
  
  nonisolated var id: String {
      videoSelection.identifier
  }
  var videoStatus: Status?
  
  
  /// init VideoAttachment
  init(_ videoSelection: PhotosPickerItem) {
    self.videoSelection = videoSelection
  }
  
  /// 영상 첨부 상태
  enum Status: Equatable {
    
    case loading          /// 섬네일 생성 중
    case finished(Image)  /// 섬네일 생성 완료
    case failed           /// 섬네일 생성 실패
    
    /// Determines whether the photo has failed to load.
    var isFailed: Bool {
      return switch self {
      case .failed: true
      default: false
      }
    }
  }
  
  func pickerItemToAVAsset(from videoSelection: PhotosPickerItem) async -> AVAsset? {
    videoSelection.loadTransferable(type: URL.self) { result in
      DispatchQueue.main.async {
        guard videoSelection == self.videoSelection else { return }
        switch result {
        case .success(let url):
          self.url = url
          print("success to load url : \(String(describing: url))")
//          AVURLAsset(url: url!)
        case .failure:
          print("failed to load url")
          break
//          return nil
        }
      }
    }
    return AVURLAsset(url: url!)
    
  }
  
  func loadThumbnail() async {
    print("loadThumbnail()")
    if let asset = await pickerItemToAVAsset(from: videoSelection) {
      let generator = AVAssetImageGenerator(asset: asset)
      let thumbnail = try? await generator.image(at: .zero)
      self.thumbnail = Image(uiImage: UIImage(cgImage: thumbnail as! CGImage))
      print("success to loadThumbnail")
    } else {
      self.videoStatus = .failed
      print("failed to loadThumbnail")
    }
  }
}

/// A extension that handles the situation in which a picker item lacks a photo library.
private extension PhotosPickerItem {
    var identifier: String {
//        guard let identifier = itemIdentifier else {
//            fatalError("The photos picker lacks a photo library.")
//        }
//        return identifier
      
      itemIdentifier ?? UUID().uuidString
    }
}
