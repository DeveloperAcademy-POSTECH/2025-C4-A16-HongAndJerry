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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Use GeometryReader to get the width of the container view
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Left padding to center the "0s" mark at the start
                        Spacer()
                            .frame(width: geometry.size.width / 2)
                        
                        // Main content area for the timeline
                        VStack(alignment: .leading, spacing: 0) {
                            // 1. Time Ruler
                            TimeRulerView(viewModel: viewModel)
                            
                            // 2. Video Tracks Area (Placeholder)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 170)
                        }
                        //.frame(width: 2000) // No longer needed, width is now dynamic
                        
                        // Right padding to allow scrolling to the end
                        Spacer()
                            .frame(width: geometry.size.width / 2)
                    }
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
