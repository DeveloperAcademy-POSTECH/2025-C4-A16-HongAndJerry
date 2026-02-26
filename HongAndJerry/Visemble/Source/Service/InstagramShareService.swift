import UIKit
import Photos

enum InstagramShareService {

  static var canShareToInstagramStories: Bool {
    guard let url = URL(string: "instagram-stories://share") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  static func shareVideoToStories(asset: PHAsset) {
    loadVideoData(from: asset) { videoData in
      guard let videoData else {
        print("[InstagramShareService] ❌ Failed to load video data")
        return
      }
      postToInstagramStories(videoData: videoData)
    }
  }

  private static func loadVideoData(from asset: PHAsset, completion: @escaping (Data?) -> Void) {
    guard let resource = PHAssetResource.assetResources(for: asset).first(where: {
      $0.type == .video
    }) else {
      completion(nil)
      return
    }

    var data = Data()
    let options = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = true

    PHAssetResourceManager.default().requestData(
      for: resource,
      options: options,
      dataReceivedHandler: { chunk in
        data.append(chunk)
      },
      completionHandler: { error in
        if let error {
          print("[InstagramShareService] ❌ Resource request error: \(error)")
          completion(nil)
        } else {
          completion(data)
        }
      }
    )
  }

  private static func postToInstagramStories(videoData: Data) {
    guard let url = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")") else { return }

    let pasteboardItems: [[String: Any]] = [[
      "com.instagram.sharedSticker.backgroundVideo": videoData
    ]]

    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(300)
    ]

    UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
