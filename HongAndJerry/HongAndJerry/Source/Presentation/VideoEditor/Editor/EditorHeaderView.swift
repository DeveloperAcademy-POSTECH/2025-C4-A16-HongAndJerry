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
    @EnvironmentObject var router: Router
    
    var body: some View {
        HStack {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer()
            
            Button {
                // TODO: 내보내기 기능 구현
            } label: {
                Text("내보내기")
                    .font(.SUITHeader)
                    .foregroundColor(.accent)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 28)
        .padding(.vertical, 16)
    }
}
