//
//  EditorWorkspaceView.swift
//  HongAndJerry
//
//  Created by Gemini on 7/19/25.
//

import AVKit
import SwiftUI

struct EditorWorkspaceView: View {
    @Environment(VideoViewModel.self) private var viewModel
    
    let namespace: Namespace.ID
    
    private var currentSegment: VideoSegment? {
        guard let selectedID = viewModel.selectedSegmentID else { return nil }
        return viewModel.segments.first(where: { $0.id == selectedID })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            EditorHeaderView(
                videoAsset: viewModel.getFinalVideoAsset(),
                videoComposition: viewModel.getFinalVideoComposition()
            )
            
            VideoPlayerView(playerController: viewModel.playerController)
                .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                .padding(.top, 21)
                .padding(.bottom, 8)
                .padding(.horizontal, 80)
            
            PlaybackControlsView()
            
            ZStack(alignment: .topLeading) {
                EditorTimelineView()
                
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .padding(.vertical, EditConstants.rulerHeight) // 상하 여백
                    .frame(maxWidth: .infinity)
                
                Text("\(viewModel.playerController.currentTime.formattedString) / \(viewModel.playerController.totalDuration.formattedString)")
                    .font(.SUITTimer)
                    .foregroundColor(.white)
                    .frame(height: EditConstants.rulerHeight)
                    .background(
                        Rectangle().fill(.black)
                    )
                    .padding(.leading, 16)
            }
            .frame(height: UIScreen.main.bounds.height / 3)
            
            TrimmingTrackViewRepresentable(
                segment: currentSegment,
                onTrimChanged: { startTime, endTime in
                    Task {
                        await viewModel.updateTrimRange(start: startTime, end: endTime)
                    }
                    
                    viewModel.playerController.seek(
                        to: CMTime(seconds: startTime, preferredTimescale: 600)
                    )
                },
                onTrimConfirmed: {
                    Task {
                        await viewModel.confirmTrimming()
                    }
                }
            )
            .frame(height: 60)
            .padding(.horizontal, 16)
        }
        .background(Color.black)
    }
}
