//
//  Crop.swift
//  HongAndJerry
//
//  Created by Soop on 7/21/25.
//

import SwiftUI
import Photos

struct Crop {
    let video: PHAsset
    let localIdentifier: String 
    var cropRect: CGRect        
    var thumbnail: UIImage
    var containerSize: CGSize = .zero 
}
