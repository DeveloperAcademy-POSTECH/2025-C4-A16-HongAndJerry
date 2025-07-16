//
//  ContentView.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI

// 사용 예시
struct ContentView: View {
    var body: some View {
        NavigationView {
            VideoGalleryView()
                .navigationTitle("비디오 선택")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
