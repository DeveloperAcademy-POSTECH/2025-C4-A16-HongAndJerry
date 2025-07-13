
//
//  TimeRulerView.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 7/13/25.
//

import SwiftUI

struct TimeRulerView: View {
    let viewModel: VideoViewModel
    
    private let pixelsPerSecond: CGFloat = 25.0
    
    // MARK: - Computed Properties
    
    private var totalDurationSeconds: Int {
        Int(viewModel.totalDuration.seconds)
    }
    
    private var majorInterval: Int {
        if totalDurationSeconds < 10 {
            return 1
        } else if totalDurationSeconds < 60 {
            return 5
        } else if totalDurationSeconds < 300 {
            return 10
        } else {
            return 30
        }
    }
    
    private var rulerWidth: CGFloat {
        CGFloat(totalDurationSeconds) * pixelsPerSecond
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(0...totalDurationSeconds, id: \.self) { second in
                VStack(spacing: 4) {
                    Spacer()
                    
                    // Label for major intervals
                    if second % majorInterval == 0 {
                        Text("\(second)s")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .fixedSize()
                    } else {
                        // Tick mark
                        Rectangle()
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 1, height: 2)
                    }
                }
                .frame(width: pixelsPerSecond)
            }
        }
        .frame(width: rulerWidth)
        .frame(height: 20)
        .border(.blue)
    }
}
