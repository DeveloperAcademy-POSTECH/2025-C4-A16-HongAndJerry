//
//  ExportController.swift
//  HongAndJerry
//
//  Created by Hong on 7/19/25.
//

import AVFoundation
import Photos
import Observation

@MainActor
@Observable
class ExportController {
    private let albumTitle = ExportNameSpace.AppMain.AppName
    private let albumRepository: AlbumRepository
    private let videoSaver: VideoSaver

    var isLoading = false
    var progress: Double = 0.0

    var alertModel: ExportAlertModel = .init(
        title: ExportNameSpace.AlertSuccessMessage.title,
        message: ExportNameSpace.AlertSuccessMessage.message,
        buttonTitle: ExportNameSpace.AlertSuccessMessage.buttonTitle
    )

    init(
        albumRepository: AlbumRepository = AlbumManager(),
        videoSaver: VideoSaver = VideoSaver()
    ) {
        self.albumRepository = albumRepository
        self.videoSaver = videoSaver
    }

    func saveVideo(
        video: AVAsset,
        videoComposition: AVVideoComposition?,
        completion: @escaping () -> Void
    ) {
        MediaPermissionUtils.requestPermission { [weak self] permission in
            guard let self else { return }

            if permission == false {
                self.alertModel = ExportAlertModel(
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
            try await videoSaver.save(
                video: video,
                videoComposition: videoComposition,
                to: album
            ) { [weak self] value in
                Task { @MainActor in
                    self?.progress = value
                }
            }
            alertModel = ExportAlertModel(
                title: ExportNameSpace.AlertSuccessMessage.title,
                message: ExportNameSpace.AlertSuccessMessage.message,
                buttonTitle: ExportNameSpace.AlertSuccessMessage.buttonTitle
            )
        } catch {
            alertModel = ExportAlertModel(
                title: ExportNameSpace.AlertFailMessage.title,
                message: ExportNameSpace.AlertFailMessage.message,
                buttonTitle: ExportNameSpace.AlertFailMessage.buttonTitle
            )
        }
        isLoading = false
    }
}
