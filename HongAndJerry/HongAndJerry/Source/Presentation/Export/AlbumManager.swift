//
//  AlbumManager.swift
//  HongAndJerry
//
//  Created by Hong on 7/18/25.
//

import Photos

final class AlbumManager: AlbumRepository {
    
    func checkAlbum(named title: String) throws -> PHAssetCollection {
        if let existingAlbum = fetchExistingAlbum(title: title) { return album }
        return try createAlbum(title: title)
    }

    private func fetchAlbum(title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        ).firstObject
    }

    private func createAlbum(title: String) throws -> PHAssetCollection {
        let identifier = try performAlbumCreation(title: title)
        return try fetchAlbum(with: identifier)
    }

    private func performAlbumCreation(title: String) throws -> String {
        var placeholder: PHObjectPlaceholder?

        try PHPhotoLibrary.shared().performChangesAndWait {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                withTitle: title
            )
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let id = placeholder?.localIdentifier else {
            throw AlbumError.albumCreateError
        }

        return id
    }

    private func fetchAlbum(with identifier: String) throws -> PHAssetCollection {
        guard let album = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [identifier],
            options: nil
        ).firstObject else {
            throw AlbumError.albumFetchError
        }

        return album
    }
}
