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
    let localIdentifier: String // PHAsset의 id
    var cropRect: CGRect        // Crop할 영역
    var thumbnail: UIImage
    var containerSize: CGSize = .zero // 각 썸네일 뷰의 컨테이너 크기
}
