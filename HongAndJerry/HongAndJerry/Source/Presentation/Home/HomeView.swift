//
//  HomeView.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import SwiftUI

struct HomeView {
    @State private var router = Router()
    @State private var viewModel = AlbumVideoViewModel()
}

extension HomeView: View {
    var body: some View {
        NavigationStack(path: $router.route) {
            VStack {
                Text("swiftcut")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .font(.SUITTitle)
                    .foregroundStyle(.font)
                if viewModel.videos.isEmpty {
                    Spacer()
                    Image(.logo)
                    Spacer()
                } else {
                    VideoScrollView(viewModel: $viewModel)
                }
                CtaButton(
                    buttonType: .plus,
                    isDisabled: .constant(false)) {
                        router.push(screen: .selectFrame)
                    }
                    .padding(.horizontal)
            }
            .background(Color.background)
            .navigationDestination(for: Screen.self) { screen in
                RoutingView(navigateDestination: screen)
                .environment(router)
            }
        }
    }
}

#Preview(body: {
    HomeView()
})
