//
//  EditorHeaderView.swift
//  HongAndJerry
//
//  Created by Gemini on 7/21/25.
//

import SwiftUI

/// 에디터 화면 상단에 표시될 헤더 뷰입니다.
/// 뒤로가기 버튼과 내보내기 버튼을 포함합니다.
struct EditorHeaderView: View {
    var body: some View {
        HStack {
            // 뒤로가기 버튼
            Button {
                // TODO: 뒤로가기 기능 구현
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            Spacer()

            // 내보내기 버튼
            Button {
                // TODO: 내보내기 기능 구현
            } label: {
                Text("내보내기")
                    .font(.SUITHeader)
                    .foregroundColor(.accent)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 28)
    }
}
