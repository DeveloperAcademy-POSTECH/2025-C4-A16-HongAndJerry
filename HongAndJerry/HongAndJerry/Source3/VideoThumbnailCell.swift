//
//  VideoThumbnailCell.swift
//  HongAndJerry
//
//  Created by Soop on 7/17/25.
//

import SwiftUI
import Photos

struct VideoThumbnailCell: View {
    let video: PHAsset
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Group {
                            if let thumbnail = thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            }
                        }
                    )
                
                // 비디오 재생 아이콘
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                
                // 비디오 길이 표시
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(video.duration))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                }
                .padding(4)
                
                // 선택 상태 표시
                if isSelected {
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
            .cornerRadius(4)
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            onTap()
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
