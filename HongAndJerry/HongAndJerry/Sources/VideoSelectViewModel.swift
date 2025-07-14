
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
  @Published var thumbnail: UIImage?
  private let videoSelection: PhotosPickerItem
  
  nonisolated var id: String {
      videoSelection.identifier
  }
  var videoStatus: Status?
  
  
  /// init VideoAttachment
  init(_ videoSelection: PhotosPickerItem) {
    self.videoSelection = videoSelection
//    Task {
//            await self.loadThumbnail()
//        }
  }
  
  /// 영상 첨부 상태
  enum Status: Equatable {
    
    case loading          /// 섬네일 생성 중
    case finished(UIImage)  /// 섬네일 생성 완료
    case failed           /// 섬네일 생성 실패
    
    /// Determines whether the photo has failed to load.
    var isFailed: Bool {
      return switch self {
      case .failed: true
      default: false
      }
    }
  }
  
  private func loadVideo(_ item: PhotosPickerItem) async throws -> URL? {
    print(" 3) loadVideo")
    guard let video = try await item.loadTransferable(type: VideoTransferable.self) else {
      return nil
    }
    return video.url
  }
//  
//  private func urlToAVAsset(url: URL) -> AVAsset? {
//    print("pickerItemToAVAsset from \(url)")
//    return AVURLAsset(url: url)
//  }
  
  func pickerItemToAVAsset(from videoSelection: PhotosPickerItem) async -> AVAsset? {
    print(" 2) pickerItemToAVAsset()")
    guard let url = try? await loadVideo(videoSelection) else { return nil }
    let asset = AVURLAsset(url: url)
    print(" 4) asset : \(asset)")
    return asset
  }
  
//  func loadThumbnail() async {
//    print(" 1) loadThumbnail()")
//    
//    if let asset = await pickerItemToAVAsset(from: videoSelection) {
//      let generator = AVAssetImageGenerator(asset: asset)
//      print(" 5) generator : \(generator)")
//      do {
//        let thumbnailImge: CGImage = try await generator.image(at: .zero).image
//        self.thumbnail = UIImage(cgImage: thumbnailImge)
//        print(" 6) thumbnail : \(String(describing: self.thumbnail))")
//      } catch {
//        print("failt to get 0sec thumbnail(CGImage)")
//      }
//      
//      print(" 7) finish")
//      self.videoStatus = .finished(self.thumbnail ?? .checkmark)
////      print("success to loadThumbnail")
//    } else {
//      self.videoStatus = .failed
//      print("failed to pickerItemTOAVAsset")
//    }
//  }
  func loadThumbnail() async {
      // 이미 썸네일이 있거나 로딩 중이면 중복 실행 방지
      if videoStatus == .loading || thumbnail != nil { return }
      videoStatus = .loading

      if let asset = await pickerItemToAVAsset(from: videoSelection) {
          let generator = AVAssetImageGenerator(asset: asset)
          do {
              let thumbnailImge: CGImage = try await generator.image(at: .zero).image
              self.thumbnail = UIImage(cgImage: thumbnailImge)
              self.videoStatus = .finished(self.thumbnail!)
          } catch {
              self.videoStatus = .failed
          }
      } else {
          self.videoStatus = .failed
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
