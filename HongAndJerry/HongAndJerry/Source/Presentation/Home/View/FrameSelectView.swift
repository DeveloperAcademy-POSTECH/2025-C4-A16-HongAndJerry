//
//  FrameSelectView.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import SwiftUI

struct FrameSelectView {
    @EnvironmentObject var router: Router
    @State private var viewModel = FrameSelectViewModel()
    @State private var frameSelected: Bool = true
}

extension FrameSelectView: View {
    var body: some View {
        VStack {
            Spacer()
            FrameView(
                frameSelected: $frameSelected,
                viewModel: $viewModel
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            Spacer()
            
            CtaButton(
                buttonType: .next,
                isDisabled: $frameSelected
            ) {
                router.push(screen: .selectVideo)
            }
            .padding()
        }
        .navigationDestination(for: Screen.self) { _ in
            GalleryView()
                .environment(router)
        }
        .background(Color.background)
        .navigationTitle(ExportNameSpace.AppMain.frameNavigationTitle)
        .foregroundStyle(.font)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: Icon.SFsymbol.chevronLeft)
                }
            }
        }
    }
}

#Preview {
    FrameSelectView()
}
