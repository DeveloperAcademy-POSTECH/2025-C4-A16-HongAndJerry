//
//  RetryVideoSelectViewModel.swift
//  HongAndJerry
//
//  Created by Soop on 7/16/25.
//

import Foundation
import SwiftUI
import PhotosUI

class RetryVideoSelectViewModel: ObservableObject {
  @Published var photosPickerItems: [PhotosPickerItem] = []
  @Published var selectedAssets: [PHAsset] = []
  
  init(photosPickerItems: [PhotosPickerItem], selectedAssets: [PHAsset]) {
    self.photosPickerItems = photosPickerItems
    self.selectedAssets = selectedAssets
  }
  
}

extension RetryVideoSelectViewModel {
  
//  func loadAllVideos() async {
//      var results: [PHAsset] = []
//      for item in photosPickerItems {
//          if let asset = await loadVideo(item) {
//              results.append(asset)
//          }
//      }
//      DispatchQueue.main.async {
//          self.selectedAssets = results
//      }
//  }
  
  func loadVideo(_ item: PhotosPickerItem) async -> PHAsset? {
      do {
          if let identifier = try await item.loadTransferable(type: PHPhotoAssetIdentifier.self) {
              let asset = await fetchPHAsset(from: identifier.localIdentifier)
              return asset
          } else {
              print("❌ identifier 가져오기 실패")
              return nil
          }
      } catch {
          print("❌ loadTransferable error:", error)
          return nil
      }
  }
  
  
  func fetchPHAsset(from localIdentifier: String) async -> PHAsset? {
      return await withCheckedContinuation { continuation in
          let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
          continuation.resume(returning: assets.firstObject)
      }
  }
}
