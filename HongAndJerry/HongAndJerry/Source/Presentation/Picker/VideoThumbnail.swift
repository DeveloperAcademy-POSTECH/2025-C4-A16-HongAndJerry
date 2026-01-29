//
//  HJVideoThumbnail.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct VideoThumbnail: View {
    let video: PHAsset
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void
    @State private var thumbnail: UIImage?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                thumbnailImage(width: geometry.size.width, height: geometry.size.height)
                if isSelected {
                    selectedState()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    func thumbnailImage(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                    }
                }
            )
    }
    private func selectedState() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accent, lineWidth: 2)
            if let index = selectionIndex {
                Text("\(index)")
                    .font(.SUITTimer)
                    .foregroundColor(.background)
                    .frame(width: 20, height: 20)
                    .background(Color.accent)
                    .clipShape(Circle())
                    .padding(12)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottomTrailing
                    )
            }
        }
    }
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        manager.requestImage(
            for: video,
            targetSize: CGSize(width: 130, height: 130),
            contentMode: .aspectFill,
            options: option
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}
