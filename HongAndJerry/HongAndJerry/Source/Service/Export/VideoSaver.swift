//
//  VideoSave.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

enum ExportError: Error {
    case exportSessionCreationFailed
    case exportFailed(Error?)
    case exportCancelled
    case unknown
}

final class VideoSaver: VideoSaving {

    func save(
        video asset: AVAsset,
        videoComposition: AVVideoComposition?,
        to album: PHAssetCollection,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.exportSessionCreationFailed
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        
        let _ = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true) { timer in
                progressHandler(Double(exportSession.progress))
            }
        
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            try await saveVideoFile(at: outputURL, to: album)
            try? FileManager.default.removeItem(at: outputURL)
            
        case .failed:
            throw ExportError.exportFailed(exportSession.error)
        case .cancelled:
            throw ExportError.exportCancelled
        default:
            throw ExportError.unknown
        }
    }

    private func saveVideoFile(at fileURL: URL, to album: PHAssetCollection) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            guard
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL),
                let placeholder = assetRequest.placeholderForCreatedAsset,
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            else { return }

            albumChangeRequest.addAssets([placeholder] as NSArray)
        }
    }
}
