//
//  AlbumPermission.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

struct MediaPermissionUtils {
  
  static func requestPermission(completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      Task { @MainActor in
        switch status {
        case .authorized, .limited:
          completion(true)
        case .denied, .restricted, .notDetermined:
          completion(false)
        @unknown default:
          completion(false)
        }
      }
    }
  }
}
