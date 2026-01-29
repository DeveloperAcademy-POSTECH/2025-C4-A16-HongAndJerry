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
}

extension ExportNameSpace {
    enum AlertConfirmMessage {
        static let title = "비디오 저장"
        static let message = "비디오를 저장하시겠습니까?"
        static let confirmButton = "확인"
        static let cancelButton = "취소"
    }

    enum AlertRejectMessage {
        static let title = "권한 거부됨"
        static let message = "사진 접근 권한이 필요합니다"
        static let buttonTitle = "설정으로 이동"
    }

    enum AlertSuccessMessage {
        static let title = "성공"
        static let message = "비디오를 사진에 저장했습니다"
        static let buttonTitle = "확인"
    }

    enum AlertFailMessage {
        static let title = "실패"
        static let message = "에러 발생"
        static let buttonTitle = "닫기"
    }
}

extension ExportNameSpace {
    enum AppMain {
        static let AppName = "V3DO"
        static let frameNavigationTitle = "프레임 선택"
        static let selectVideoTitle = "영상 선택"
        static let cropVideoTitle = " 비율 조정"
    }
}
