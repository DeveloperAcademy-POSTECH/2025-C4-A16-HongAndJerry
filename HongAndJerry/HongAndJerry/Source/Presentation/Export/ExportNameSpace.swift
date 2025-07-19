//
//  NameSpace.swift
//  HongAndJerry
//
//  Created by Hong on 7/19/25.
//

enum ExportNameSpace {}

extension ExportNameSpace {
    enum ExportView {
        static let export = "내보내기"
    }
    
    enum AlertRejectMessage {
        static let title = "권한 거부됨"
        static let message = "사진 접근 권한이 필요합니다"
        static let buttonTitle = "설정으로 이동"
    }
    
    enum AlertSuccessMessage {
        static let title = "성공"
        static let message = "저장 완료!"
        static let buttonTitle = "확인"
    }
    
    enum AlertFailMessage {
        static let title = "실패"
        static let message = "에러 발생"
        static let buttonTitle = "닫기"
    }
}
