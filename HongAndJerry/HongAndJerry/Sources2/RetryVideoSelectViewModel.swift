//
//  RetryVideoSelectViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/16/25.
//

import SwiftUI
import PhotosUI

struct SelectedVideo: Identifiable, Equatable {
    let id = UUID()
    let asset: PHAsset
    let thumbnail: UIImage
}

class RetryVideoSelectViewModel: ObservableObject {
    @Published var selectedVideos: [SelectedVideo] = []

    func handleNewItem(_ item: PhotosPickerItem) {
      print("⭐️ handleNewItem")
        Task {
            if let asset = await loadVideo(item),
               let image = await fetchThumbnail(from: asset) {
                DispatchQueue.main.async {
                  print("⭐️ append \(image)")
                    self.selectedVideos.append(SelectedVideo(asset: asset, thumbnail: image))
                }
            }
        }
    }

    func loadVideo(_ item: PhotosPickerItem) async -> PHAsset? {
      print("⭐️ loadVideo \(item)")
    
      do {
          if let identifier = try await item.loadTransferable(type: PHPhotoAssetIdentifier.self) {
              print("✅ loadTransferable 성공: \(identifier.localIdentifier)")
              return await fetchPHAsset(from: identifier.localIdentifier)
          } else {
              print("❌ loadTransferable 반환값이 nil")
          }
      } catch {
          print("❌ loadTransferable 실패: \(error)")
      }
      return nil
    }

    func fetchPHAsset(from localIdentifier: String) async -> PHAsset? {
      print("⭐️ fetchPHAsset")
      return await withCheckedContinuation { continuation in
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            continuation.resume(returning: assets.firstObject)
        }
    }

    func fetchThumbnail(from asset: PHAsset) async -> UIImage? {
      print("⭐️ fetchThumbnail")
      return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false

            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}


