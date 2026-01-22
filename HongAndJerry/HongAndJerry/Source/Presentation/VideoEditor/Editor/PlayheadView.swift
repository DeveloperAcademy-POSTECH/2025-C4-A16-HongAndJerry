//
//  PlayheadView.swift
//  HongAndJerry
//
//  Created by Rama on 1/22/26.
//

import SwiftUI

struct PlayheadView: View {
    var body: some View {
        Rectangle()
            .fill(.white)
            .frame(width: 2)
            .padding(.vertical, EditConstants.rulerHeight)
            .frame(maxWidth: .infinity)
    }
}
