//
//  SelectedVideoThumbnail.swift
//  HongAndJerry
//
//  Created by Soop on 7/17/25.
//

import Foundation
import SwiftUI
import Photos

struct SelectedVideoThumbnail: View {
    let video: PHAsset
    let index: Int
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        manager.requestImage(
            for: video,
            targetSize: CGSize(width: 60, height: 60),
            contentMode: .aspectFill,
            options: option
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}
