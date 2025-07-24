//
//  HandlesView.swift
//  HongAndJerry
//
//  Created by Rama on 7/25/25.
//

import SwiftUI

struct HandlesView: View {
    let segment: VideoSegment
    let trackWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            HandleView(
                handleType: .left,
                trackWidth: trackWidth,
                segmentID: segment.id
            )
            
            Spacer()
            
            HandleView(
                handleType: .right,
                trackWidth: trackWidth,
                segmentID: segment.id
            )
        }
        
    }
}
