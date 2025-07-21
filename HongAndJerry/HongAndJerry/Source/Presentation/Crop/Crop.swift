//
//  Crop.swift
//  HongAndJerry
//
//  Created by Soop on 7/21/25.
//

import SwiftUI

struct Crop {
    let localIdentifier: String // PHAsset의 id
    var cropRect: CGRect        // Crop할 영역
    var thumbnail: UIImage
}
