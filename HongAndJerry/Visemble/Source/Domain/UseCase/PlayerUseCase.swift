//
//  PlayerUseCase.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit
import Observation

/// 비디오 재생 UseCase
/// Domain Layer - AVPlayer 제어 + 재생 상태 관리
@Observable
class PlayerUseCase {
  let player = AVPlayer()

  @MainActor var isPlaying: Bool = false
  @MainActor var currentTime: CMTime = .zero
  @MainActor var totalDuration: CMTime = .zero

  private var timeObserverToken: Any? // AVPlayer의 시간 변경을 감지하는 옵저버의 토큰

  init() {}
  
  // 트리밍 등의 편집이 발생하면 새로운 composition으로 교체
  @MainActor
  func replaceCurrentItem(with item: AVPlayerItem?) {
    removeTimeObserver()
    player.replaceCurrentItem(with: item)

    let prevCurrentTime = currentTime
    guard let item = item else {
      totalDuration = .zero
      currentTime = .zero
      return
    }

    totalDuration = item.duration
    addTimeObserver()

    currentTime = min(prevCurrentTime, totalDuration)
    seek(to: currentTime)
  }

  @MainActor
  func play() {
    currentTime = player.currentTime()
    player.rate = 1
    isPlaying = true
  }

  @MainActor
  func pause() {
    player.rate = 0
    isPlaying = false
  }

  @MainActor
  func seek(to time: CMTime, direction: DragDirection = .none) {
    // 역방향 드래그일 때만 tolerance를 적용하고, 그 외에는 정확한 위치로 이동
    let tolerance = (
      direction == .backward
    ) ? CMTime(
      seconds: 0.5,
      preferredTimescale: 600
    ) : .zero

    player.seek(
      to: time,
      toleranceBefore: tolerance,
      toleranceAfter: tolerance
    )
  }
  
  @MainActor
  private func addTimeObserver() {
    removeTimeObserver()

    timeObserverToken = player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 60)
      , queue: .main
    ) { [weak self] time in
      Task { @MainActor in
        guard let self else { return }
        self.currentTime = time
      }
    }
  }

  @MainActor
  private func removeTimeObserver() {
    if let token = timeObserverToken {
      player.removeTimeObserver(token)
      timeObserverToken = nil
    }
  }

  @MainActor
  func cleanup() {
    pause()
    removeTimeObserver()
    player.replaceCurrentItem(with: nil)
    currentTime = .zero
    totalDuration = .zero
  }
}
