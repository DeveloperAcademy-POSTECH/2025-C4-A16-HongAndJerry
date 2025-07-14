//
//  VideoEditor.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/12/25.
//

import SwiftUI
import Foundation

import SwiftUI
import CoreMedia

struct VideoEditor: View {
    let viewModel: VideoViewModel
    
    @State private var previousTime: CMTime = .zero
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Use GeometryReader to get the width of the container view
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Main content area for the timeline
                        VStack(alignment: .leading, spacing: 15) {
                            // 1. Time Ruler
                            TimeRulerView(viewModel: viewModel)
                            
                            // 2. Video Tracks Area
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.segments) { segment in
                                    VideoTrackView(segment: segment, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .offset(x: geometry.size.width / 2 - (viewModel.currentTime.seconds * viewModel.pixelsPerSecond))
                    .animation(.linear(duration: 0.01), value: viewModel.currentTime)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !viewModel.isScrubbing {
                                    viewModel.isScrubbing = true
                                    previousTime = viewModel.currentTime
                                    viewModel.pause()
                                }
                                
                                let translationX = value.translation.width
                                let timeOffset = -translationX / viewModel.pixelsPerSecond
                                let newTime = CMTimeAdd(previousTime, CMTime(seconds: timeOffset, preferredTimescale: 600))
                                
                                // Ensure the new time is within the valid range
                                let clampedTime = max(.zero, min(newTime, viewModel.totalDuration))
                                viewModel.seek(to: clampedTime)
                            }
                            .onEnded { _ in
                                viewModel.isScrubbing = false
                                previousTime = .zero
                            }
                    )
                }
            }
            
            // Playhead
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 170)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: 25)

            // Time Display (Top-Left Corner)
            Text("\(viewModel.currentTime.toTimeFormat()) / \(viewModel.totalDuration.toTimeFormat())")
                .foregroundColor(.white)
        }
        .frame(height: 250) // Set a fixed height for the editor area
    }
}

// Helper extension to format time in MM:SS
private extension CMTime {
    func toTimeFormat() -> String {
        let totalSeconds = Int(self.seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
