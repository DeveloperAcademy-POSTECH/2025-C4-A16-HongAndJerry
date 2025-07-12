//
//  ContentView.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = VideoViewModel(segments: [])
    
    var body: some View {
        VStack {
            VideoPlayer(viewModel: viewModel)
        }.task {
            await viewModel.loadInitialData()
        }
    }
}

#Preview {
    ContentView()
}
