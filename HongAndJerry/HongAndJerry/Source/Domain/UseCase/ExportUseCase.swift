//
//  ExportUseCase.swift
//  HongAndJerry
//
//  Created by Hong on 7/19/25.
//

import AVFoundation
import Photos
import Observation

/// 비디오 내보내기 UseCase
/// Domain Layer - Export 프로세스 조율 + 상태 관리
@MainActor
@Observable
class ExportUseCase {
  private let albumTitle = ExportNameSpace.AppMain.AppName
  private let albumRepository: AlbumRepository
  private let videoRepository: VideoRepository
  
  var isLoading = false
  var progress: Double = 0.0
  
  var alertModel: ExportAlert = .init(
    title: ExportNameSpace.AlertSuccessMessage.title,
    message: ExportNameSpace.AlertSuccessMessage.message,
    buttonTitle: ExportNameSpace.AlertSuccessMessage.buttonTitle
  )

  nonisolated init(
    albumRepository: AlbumRepository = PhotoLibraryAlbumRepository(),
    videoRepository: VideoRepository = AVAssetExportRepository()
  ) {
    self.albumRepository = albumRepository
    self.videoRepository = videoRepository
  }
  
  func saveVideo(
    video: AVAsset,
    videoComposition: AVVideoComposition?,
    completion: @escaping () -> Void
  ) {
    MediaPermissionUtils.requestPermission { [weak self] permission in
      guard let self else { return }
      
      if permission == false {
        self.alertModel = ExportAlert(
          title: ExportNameSpace.AlertRejectMessage.title,
          message: ExportNameSpace.AlertRejectMessage.message,
          buttonTitle: ExportNameSpace.AlertRejectMessage.buttonTitle
        )
        completion()
        return
      }
      
      Task {
        await self.saveToAlbum(video, videoComposition: videoComposition)
        completion()
      }
    }
  }
  
  private func saveToAlbum(_ video: AVAsset, videoComposition: AVVideoComposition?) async {
    isLoading = true
    
    do {
      let album = try albumRepository.checkAlbum(named: albumTitle)
      try await videoRepository.save(
        video: video,
        videoComposition: videoComposition,
        to: album
      ) { [weak self] value in
        Task { @MainActor in
          self?.progress = value
        }
      }
      alertModel = ExportAlert(
        title: ExportNameSpace.AlertSuccessMessage.title,
        message: ExportNameSpace.AlertSuccessMessage.message,
        buttonTitle: ExportNameSpace.AlertSuccessMessage.buttonTitle
      )
    } catch {
      alertModel = ExportAlert(
        title: ExportNameSpace.AlertFailMessage.title,
        message: ExportNameSpace.AlertFailMessage.message,
        buttonTitle: ExportNameSpace.AlertFailMessage.buttonTitle
      )
    }
    isLoading = false
  }
}
