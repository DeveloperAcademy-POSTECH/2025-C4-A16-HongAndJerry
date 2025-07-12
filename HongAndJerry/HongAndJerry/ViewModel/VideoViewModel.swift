//
//  VideoPlayerViewModel.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/11/25.
//

import SwiftUI
import Foundation

@Observable public final class VideoViewModel {
    var segments: [VideoSegment];
    
    init() {
        self.segments = []
    }
    
    init(segments: [VideoSegment]) {
        self.segments = segments
    }
}

extension VideoViewModel {
    func loadInitialData() async {
        Task {
            print("---비디오 데이터 초기화---")
            do {
                let video1 = try await VideoSegment.sample1()
                let video2 = try await VideoSegment.sample2()
                let video3 = try await VideoSegment.sample3()
                
                self.segments = [video1, video2, video3]
                
                print("segmnets: \(self.segments)")
                print("---비디오 데이터 초기화 완료---")
            } catch {
                print("Failed to load video segments: \(error)")
                print("---비디오 데이터 초기화 실패---")
            }
        }
    }
}
