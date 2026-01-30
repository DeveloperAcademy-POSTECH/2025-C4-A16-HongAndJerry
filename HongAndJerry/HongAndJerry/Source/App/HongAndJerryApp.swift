//
//  HongAndJerryApp.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI

@main
struct HongAndJerryApp: App {
  @State private var segments: [VideoSegment] = []
  @State private var router = Router()
  
  var body: some Scene {
    WindowGroup {
      NavigationStack(path: $router.route) {
        HomeGalleryView()
          .navigationDestination(for: Screen.self) { screen in
            RoutingView(navigateDestination: screen)
          }
      }
      .environmentObject(router)
      //
      //            Group {
      //                if segments.isEmpty {
      //                    ProgressView("Mock 데이터 로딩 중...")
      //                } else {
      //                    EditorView(segments: segments)
      //                }
      //            }
      //            .task {
      //                segments = await VideoSegment.mockList()
      //            }
    }
  }
}
