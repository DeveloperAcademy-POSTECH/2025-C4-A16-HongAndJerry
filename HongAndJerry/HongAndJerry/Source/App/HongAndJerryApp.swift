//
//  HongAndJerryApp.swift
//  HongAndJerry
//
//  Created by Rama on 7/8/25.
//

import SwiftUI

@main
struct HongAndJerryApp: App {
    
    @State private var router = Router()
    
    var body: some Scene {
        WindowGroup {
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
