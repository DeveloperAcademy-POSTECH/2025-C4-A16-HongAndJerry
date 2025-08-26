//
//  PHAsset++.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 8/25/25.
//

import Photos
import SwiftUI

extension PHAsset {
    func fetchThumbnail() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            manager.requestImage(
                for: self,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
