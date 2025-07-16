//
//  RetryVideoSelectView.swift
//  HongAndJerry
//
//  Created by Soop on 7/16/25.
//

import SwiftUI
import PhotosUI

struct RetryVideoSelectView: View {
    @State private var pickedItem: [PhotosPickerItem] = []
    @State private var assetIdentifier: String?
    @State private var phAsset: PHAsset?

    var body: some View {
        VStack {
            if let phAsset {
                Text("PHAsset 찾음 ✅")
            }
          
          HStack {
            
          }

          PhotosPicker(
            selection: $pickedItem,
            maxSelectionCount: 3,
            selectionBehavior: .continuous,
            matching: .videos
          ) {
            Text("Select Video")
          }
        }
//        .onChange(of: pickedItem) { newItem, oldItem in
//            Task {
//                if let identifier = try? await newItem?.loadTransferable(type: PHPhotoAssetIdentifier.self) {
//                    self.assetIdentifier = identifier.localIdentifier
//                    fetchPHAsset(from: identifier.localIdentifier) { asset in
//                        self.phAsset = asset
//                    }
//                } else {
//                    print("PHAsset identifier를 가져올 수 없음")
//                }
//            }
//        }
    }

    func fetchPHAsset(from localIdentifier: String, completion: @escaping (PHAsset?) -> Void) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        completion(assets.firstObject)
    }
}

#Preview {
  RetryVideoSelectView()
}
