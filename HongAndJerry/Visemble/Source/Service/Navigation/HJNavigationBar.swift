import SwiftUI

struct HJNavigationBar<TrailingContent: View>: ViewModifier {
    let title: String
    let backgroundColor: UIColor = .background
    let backButtonColor: UIColor = .white
    let trailingContent: TrailingContent

    init(title: String, @ViewBuilder trailingContent: () -> TrailingContent) {
        self.title = title
        self.trailingContent = trailingContent()
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    trailingContent
                }
            }
            .onAppear {
                setNavigationBarAppearance()
            }
    }

    private func setNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = backgroundColor

        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance

        let backIcon = UIImage(systemName: "chevron.left",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))?
            .withTintColor(
                backButtonColor,
                renderingMode: .alwaysOriginal
            )
        appearance.setBackIndicatorImage(backIcon, transitionMaskImage: backIcon)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
