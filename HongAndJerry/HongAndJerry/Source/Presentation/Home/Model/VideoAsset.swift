//
//  VideoAsset.swift
//  HongAndJerry
//
//  Created by Hong on 7/20/25.
//

import Photos
import UIKit

struct VideoAsset {
    let asset: PHAsset
    let thumbnail: UIImage
    let duration: TimeInterval
    let creationDate: Date?
    let creationTime: Date?

    var durationValue: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var creationDateValue: String {
        guard
            let date = creationDate
        else { return "알 수 없음" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.M.d"
        return formatter.string(from: date)
    }
    
    var creationTimeValue: String {
        guard
            let date = creationTime
        else { return "알 수 없음" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

