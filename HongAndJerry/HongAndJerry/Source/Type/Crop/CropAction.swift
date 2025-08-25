//
//  CropAction.swift
//  HongAndJerry
//
//  Created by Donggyun Yang on 8/25/25.
//
import SwiftUI

enum CropAction {
    case onAppear
    case nextButtonTapped
    case prevButtonTapped
    case containerDidChangeSize(size: CGSize, at: Int)
}
