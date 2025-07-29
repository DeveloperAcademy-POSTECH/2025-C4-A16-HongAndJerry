//
//  ExportViewModel.swift
//  HongAndJerry
//
//  Created by Hong on 7/19/25.
//

import AVFoundation
import UIKit

@Observable
final class ExportViewModel {
    private let albumTitle = "WVDO"
    private let albumRepository: AlbumRepository
    private let videoSaver: VideoSaver
    
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
    
    func saveVideo(_ video: AVAsset, videoComposition: AVVideoComposition?) {
        MediaPermissionUtils.requestPermission { [weak self] permission in
            guard let self else { return }
            
            if permission == false {
                self.alertModel = ExportAlertModel(
                    title: ExportNameSpace.AlertRejectMessage.title,
                    message: ExportNameSpace.AlertRejectMessage.message,
                    buttonTitle: ExportNameSpace.AlertRejectMessage.buttonTitle
                )
                return
            }
            self.saveToAlbum(video, videoComposition: videoComposition)
        }
    }
    
    private func saveToAlbum(_ video: AVAsset, videoComposition: AVVideoComposition?) {
        Task {
            do {
                let album = try albumRepository.checkAlbum(named: albumTitle)
                try await videoSaver.save(video: video, videoComposition: videoComposition, to: album)
                alertModel = ExportAlertModel(
                    title: ExportNameSpace.AlertSuccessMessage
                        .title,
                    message: ExportNameSpace.AlertSuccessMessage
                        .message,
                    buttonTitle: ExportNameSpace.AlertSuccessMessage
                        .buttonTitle
                )
            } catch {
                alertModel = ExportAlertModel(
                    title: ExportNameSpace.AlertFailMessage.title,
                    message: ExportNameSpace.AlertFailMessage.message,
                    buttonTitle: ExportNameSpace.AlertFailMessage.buttonTitle
                )
            }
        }
    }
}
