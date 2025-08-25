//
//  FrameSelectViewModel.swift
//  HongAndJerry
//
//  Created by Hong on 7/24/25.
//

import Foundation
import SwiftUI

@Observable
final class FrameSelectViewModel {
    var frames = [
        FrameItem(image: Image(.inactiveFrame)),
        FrameItem(image: Image(.comingSoon)),
        FrameItem(image: Image(.comingSoon)),
        FrameItem(image: Image(.comingSoon))
    ]
    
    func getImage(isFrameSelected: Bool) {
        if isFrameSelected {
            self.frames =  [
                FrameItem(image: Image(.activeFrame)),
                FrameItem(image: Image(.comingSoon)),
                FrameItem(image: Image(.comingSoon)),
                FrameItem(image: Image(.comingSoon))
            ]
        } else {
            self.frames = [
                FrameItem(image: Image(.inactiveFrame)),
                FrameItem(image: Image(.comingSoon)),
                FrameItem(image: Image(.comingSoon)),
                FrameItem(image: Image(.comingSoon))
            ]
        }
    }
}
