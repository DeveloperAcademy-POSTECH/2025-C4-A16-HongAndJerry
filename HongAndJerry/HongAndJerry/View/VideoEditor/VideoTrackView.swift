
//
//  VideoTrackView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/13/25.
//

import SwiftUI
import AVFoundation

struct VideoTrackView: View {
    let segment: VideoSegment
    let viewModel: VideoViewModel
    
    @State private var thumbnails: [UIImage] = []
    
    private let thumbnailHeight: CGFloat = (170.0 - 20) / 3 // Total height minus ruler, divided by 3
    
    var body: some View {
        HStack(spacing: 0) {
            if !thumbnails.isEmpty {
                // Show a placeholder while thumbnails are loading
                ForEach(thumbnails.indices, id: \.self) { index in
                    Image(uiImage: thumbnails[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: viewModel.pixelsPerSecond * viewModel.thumbnailTimeStep, height: thumbnailHeight)
                        .clipped()
                }
            }
        }
        .frame(height: thumbnailHeight)
        .onAppear {
            generateThumbnails()
        }
    }
    
    private func generateThumbnails() {
        Task {
            let asset = segment.asset
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Optimize for performance
            imageGenerator.maximumSize = CGSize(width: viewModel.pixelsPerSecond * 2, height: thumbnailHeight * 2)
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero

            guard let duration = try? await asset.load(.duration) else { return }
            let durationInSeconds = duration.seconds
            guard durationInSeconds > 0 else { return }
            
            let timeStep = viewModel.thumbnailTimeStep
            var generatedImages: [UIImage] = []
            
            for timeInSeconds in stride(from: 0, to: durationInSeconds, by: timeStep) {
                let time = CMTime(seconds: timeInSeconds, preferredTimescale: 600)
                do {
                    let cgImage = try await imageGenerator.image(at: time).image
                    generatedImages.append(UIImage(cgImage: cgImage))
                } catch {
                    print("Failed to generate thumbnail at time \(time): \(error)")
                    if let errorImage = UIImage(systemName: "exclamationmark.triangle.fill") {
                        generatedImages.append(errorImage)
                    }
                }
            }
            
            await MainActor.run {
                self.thumbnails = generatedImages
            }
        }
    }
}
