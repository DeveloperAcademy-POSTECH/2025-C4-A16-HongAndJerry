//
//  ComponentExample.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Photos

// TODO: edit
protocol AlbumRepository {
  func checkAlbum(named title: String) throws -> PHAssetCollection
}
