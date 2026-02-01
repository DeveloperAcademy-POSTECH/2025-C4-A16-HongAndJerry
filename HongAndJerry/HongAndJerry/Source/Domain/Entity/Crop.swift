//
//  Crop.swift
//  HongAndJerry
//
//  Created by Soop on 7/21/25.
//

import SwiftUI
import Photos

struct Crop: Hashable {
  let video: PHAsset
  let localIdentifier: String
  var cropRect: CGRect
  var thumbnail: UIImage
  var containerSize: CGSize = .zero

  static func == (lhs: Crop, rhs: Crop) -> Bool {
    lhs.localIdentifier == rhs.localIdentifier
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(localIdentifier)
  }
}
