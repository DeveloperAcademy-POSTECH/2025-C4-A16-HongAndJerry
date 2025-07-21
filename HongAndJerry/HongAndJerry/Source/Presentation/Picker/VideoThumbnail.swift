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
                
                // 선택 상태 표시
                if isSelected {
                    selectedState
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    // View
    // soop TODO: - 컴포넌트 뺼래 말래
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
    
    var selectedState: some View {
        ZStack {
            Rectangle()
                .strokeBorder(Color.accent, lineWidth: 2)
            
            if let index = selectionIndex {
                Text("\(index)")
                    .font(.SUITBody)    // soop TODO: - Font
                    .foregroundColor(Color.accent)
            }
        }
    }
    
    // soop TODO: - SelectedViewThumbnail에도 같은 함수가 있어서 수정해야 함...
    // func
    
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
