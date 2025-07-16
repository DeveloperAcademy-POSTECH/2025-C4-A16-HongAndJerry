//
//  PHPhotoAssetIdentifier.swift
//  HongAndJerry
//
//  Created by Soop on 7/16/25.
//

import Foundation
import Photos
import PhotosUI
import UniformTypeIdentifiers
import CoreTransferable

struct PHPhotoAssetIdentifier: Transferable {
    let localIdentifier: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.localIdentifier)
    }

    static var supportedContentTypes: [UTType] {
      [.movie]
    }
}
