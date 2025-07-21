//
//  NavigationRouter.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import Foundation
import Photos

public enum Screen: Hashable {
    case home
    case selectFrame
    case selectVideo
    case editVideoRatio([PHAsset])
    case videoEditView
}

@Observable
final class Router: ObservableObject {
    public var route: [Screen] = []
    public init() { }
    
    @MainActor
    public func push(screen: Screen) {
        route.append(screen)
    }
    
    @MainActor
    public func pop() {
        route.removeLast()
    }
    
    @MainActor
    public func pop(depth: Int) {
        route.removeLast(depth)
    }
    
    @MainActor
    public func popToRoot() {
        route.removeAll()
    }
    
    @MainActor
    public func switchScreen(screen: Screen) {
        guard !route.isEmpty else { return }
        let lastIndex = route.count - 1
        route[lastIndex] = screen
    }
}
