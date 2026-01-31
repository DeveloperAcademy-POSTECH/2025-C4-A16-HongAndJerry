//
//  VideoRepository.swift
//  HongAndJerry
//
//  Created by Claude on 1/31/26.
//

import AVFoundation
import Photos

/// 비디오 저장 Repository Interface
/// Domain Layer - 비디오 내보내기 및 저장 추상화
protocol VideoRepository {
  /// 비디오를 앨범에 저장
  /// - Parameters:
  ///   - asset: 저장할 비디오 에셋
  ///   - videoComposition: 비디오 컴포지션 (옵셔널)
  ///   - album: 저장할 대상 앨범
  ///   - progressHandler: 진행률 콜백
  func save(
    video asset: AVAsset,
    videoComposition: AVVideoComposition?,
    to album: PHAssetCollection,
    progressHandler: @escaping (Double) -> Void
  ) async throws
}
