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
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            
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
            
            if viewModel.selectedSegmentID != nil {
                TrimmingTrackViewRepresentable(
                    segment: currentSegment,
                    onTrimStarted: { handleType in
                        viewModel.startTrimming(handleType: handleType)
                        
                        if let offset = viewModel.scrollOffsetForTrimStart() {
                            NotificationCenter.default.post(
                                name: .timelineScrollToOffset,
                                object: offset
                            )
                        }
                    },
                    onTrimChanged: { startTime, endTime, handleType in
                        Task {
                            await viewModel.updateTrimRange(start: startTime, end: endTime)
                        }

                        let seekTime = handleType == .left ? startTime : endTime
                        viewModel.playerController.seek(
                            to: CMTime(seconds: seekTime, preferredTimescale: 600)
                        )
                    },
                    onTrimEnded: {
                        viewModel.endTrimming()
                    },
                    onTrimConfirmed: {
                        Task {
                            await viewModel.confirmTrimming()
                        }
                    }
                )
                .frame(height: 60)
                .padding(.leading, 16)
                .padding(.trailing, 20)
            }

        }
        .background(Color.black)
    }
}
