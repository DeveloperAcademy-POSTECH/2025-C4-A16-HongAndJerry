//
//  FrameSelectView.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import SwiftUI

struct FrameSelectView {
    @EnvironmentObject var router: Router
}

extension FrameSelectView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("추가예정")
                .foregroundStyle(.font)
                .frame(maxWidth: .infinity)
            Spacer()
            CtaButton(
                buttonType: .next,
                isDisabled: .constant(false)) {
                    router.push(screen: .selectVideo)
                }
                .padding()
        }
        .navigationDestination(for: Screen.self) { _ in
            GalleryView()
                .environment(router)
        }
        .background(Color.background)
        .navigationTitle("프레임 선택")
        .foregroundStyle(.font)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}
