//
//  Untitled.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

enum AlbumError: Error {
  case albumCreateError
  case albumFetchError
  case albumPermissionError
  
  var message: String {
    switch self {
    case .albumCreateError:
      return "앨범 생성 실패"
    case .albumFetchError:
      return "앨범 불러오기 실패"
    case .albumPermissionError:
      return "앨번 권한 없음"
    }
  }
}

enum VideoError: Error {
  case videoFileError
  case videoCreateError
  
  var message: String {
    switch self {
    case .videoCreateError:
      return "영상 생성에 실패했습니다"
    case .videoFileError:
      return "영상 파일을 찾을 수 없음"
    }
  }
}
