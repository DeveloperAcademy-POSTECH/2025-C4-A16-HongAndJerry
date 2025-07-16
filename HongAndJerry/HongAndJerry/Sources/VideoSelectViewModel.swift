import SwiftUI
import PhotosUI
import AVFoundation

@MainActor final class VideoSelectViewModel: ObservableObject {
  @Published var selection = [PhotosPickerItem]() {
    didSet {
      var newAttachmentByIdentifier = self.attachmentByIdentifier

      let newAttachments = selection.map { item in
        if let existing = newAttachmentByIdentifier[item.identifier] {
          return existing
        } else {
          let newAttachment = VideoAttachment(item)
          if let cached = thumbnailCache[item.identifier] {
            newAttachment.thumbnail = cached
            newAttachment.videoStatus = .finished(cached)
          }
          newAttachmentByIdentifier[item.identifier] = newAttachment
          return newAttachment
        }
      }

      self.attachments = newAttachments
      self.attachmentByIdentifier = newAttachmentByIdentifier
    }
  }
  @Published var attachments = [VideoAttachment]()
    
  private var attachmentByIdentifier = [String: VideoAttachment]()
  private var thumbnailCache: [String: UIImage] = [:]
  
  func cacheThumbnail(_ image: UIImage, for id: String) {
    thumbnailCache[id] = image
  }
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
    let asset = AVURLAsset(url: url) // 비동기
    print(" 4) asset : \(asset)")
    return asset
  }
  
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
        if let image = self.thumbnail {
          DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didGenerateThumbnail, object: nil, userInfo: ["id": self.id, "image": image])
          }
        }
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
    itemIdentifier ?? UUID().uuidString
  }
}

extension Notification.Name {
  static let didGenerateThumbnail = Notification.Name("didGenerateThumbnail")
}
