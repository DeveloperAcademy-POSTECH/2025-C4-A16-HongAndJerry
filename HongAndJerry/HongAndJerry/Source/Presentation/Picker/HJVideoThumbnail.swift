//
//  HJVideoThumbnail.swift
//  HongAndJerry
//
//  Created by Soop on 7/19/25.
//

import SwiftUI
import Photos

struct HJVideoThumbnail: View {
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
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue, lineWidth: 3)
            
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                        
                        if let index = selectionIndex {
                            Text("\(index)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                Spacer()
            }
            .padding(4)
        }
    }
    
    // func
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        manager.requestImage(
            for: video,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: option
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

}
