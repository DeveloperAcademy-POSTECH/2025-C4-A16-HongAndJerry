//
//  CtaButton.swift
//  HongAndJerry
//
//  Created by Hong on 7/17/25.
//

import SwiftUI

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
            HStack(spacing: 8) {
                if let systemName = buttonType.systemImageName {
                    Image(systemName: systemName)
                        .font(.SUITBody)
                        .foregroundStyle(isDisabled ? .font : .pureBlack)
                }
                
                if let title = buttonType.title {
                    Text(title)
                        .font(.SUITHeader)
                        .foregroundStyle(isDisabled ? .font : .pureBlack)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isDisabled ? .inactive : Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}


