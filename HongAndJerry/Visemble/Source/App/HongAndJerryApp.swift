import SwiftUI

@main
struct HongAndJerryApp: App {
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
    }
  }
}
