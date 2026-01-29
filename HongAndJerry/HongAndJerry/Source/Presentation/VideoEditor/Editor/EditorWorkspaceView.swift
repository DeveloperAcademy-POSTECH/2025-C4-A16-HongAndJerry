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
    
    private var snapEndTimes: [Double] {
        guard let selectedID = viewModel.selectedSegmentID else { return [] }
        return viewModel.getSegmentEndTimes(excluding: selectedID)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                EditorHeaderView()
                .padding(.vertical, 12)
                .padding(.leading, 28)
                .padding(.trailing, 20)

                VideoPlayerView(playerController: viewModel.playerController)
                    .matchedGeometryEffect(id: "videoPlayer", in: namespace)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .padding(.bottom, 12)

                PlaybackControlsView()
                    .padding(.bottom, 12)
            }

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    EditorTimelineView()

                    PlayheadView()

                    TimeDisplayView()
                }

                ZStack {
                    if viewModel.selectedSegmentID != nil {
                        TrimmingTrackViewRepresentable(
                            segment: currentSegment,
                            snapEndTimes: snapEndTimes,
                            shouldShake: viewModel.shouldShakeCheckButton,
                            isTrimming: viewModel.isTrimming,
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
                        .padding(.leading, 12)
                        .padding(.trailing, 24)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: -15).combined(with: .opacity),
                                removal: .offset(y: -15).combined(with: .opacity)
                            )
                        )
                    }
                }
                .frame(height: 60)
                .animation(
                    .spring(
                        response: 0.3,
                        dampingFraction: 0.8
                    ),
                    value: viewModel.selectedSegmentID
                )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}
