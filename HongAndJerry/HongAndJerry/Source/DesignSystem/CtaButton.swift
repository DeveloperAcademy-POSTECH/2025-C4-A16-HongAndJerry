//
//  CtaButton.swift
//  HongAndJerry
//
//  Created by Hong on 7/17/25.
//

import SwiftUI

/// **
/// 공통 CTA 버튼
/// ```swift
/// CtaButton(
///   buttonType: .next,
///   isDisabled: false
/// ) {
///   print("버튼 액션")
/// }
///
struct CtaButton {
    let buttonType: ButtonType
    @Binding var isDisabled: Bool
    let action: () -> Void
}

extension CtaButton: View {
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                if let title = buttonType.title {
                    Text(title)
                        .font(.SUITHeader)
                        .foregroundStyle(isDisabled ? .font : .pureBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let systemName = buttonType.systemImageName {
                    Image(systemName: systemName)
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(isDisabled ? .font : .pureBlack)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(isDisabled ? .inactive : Color.accent)
        }
        .disabled(isDisabled)
    }
}

