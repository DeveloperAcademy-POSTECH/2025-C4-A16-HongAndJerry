//
//  SplashView.swift
//  HongAndJerry
//
//  Created by Hong on 7/30/25.
//

import SwiftUI

struct SplashView {
    @State private var isLaunch: Bool = true
    @State private var router = Router()
}

extension SplashView: View {
    var body: some View {
        if isLaunch {
            VStack {
                LottieView(fileName: "splash300", loopMode: .playOnce)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                    self.isLaunch = false
                }
            }
        } else {
            NavigationStack(path: $router.route) {
                HomeView()
                    .navigationDestination(for: Screen.self) { screen in
                        RoutingView(navigateDestination: screen)
                    }
            }
            .environmentObject(router)
        }
    }
}
