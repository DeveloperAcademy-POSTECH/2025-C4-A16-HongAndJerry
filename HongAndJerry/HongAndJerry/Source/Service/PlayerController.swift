//
//  PlayerController.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit
import Observation

@MainActor
@Observable
class PlayerController {
  let player = AVPlayer()
  
  var isPlaying: Bool = false
  var currentTime: CMTime = .zero
  var totalDuration: CMTime = .zero
  
  private var timeObserverToken: Any? // AVPlayer의 시간 변경을 감지하는 옵저버의 토큰
  
  // 트리밍 등의 편집이 발생하면 새로운 composition으로 교체
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
  
  func play() {
    currentTime = player.currentTime()
    player.rate = 1
    isPlaying = true
  }
  
  func pause() {
    player.rate = 0
    isPlaying = false
  }
  
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
  
  private func removeTimeObserver() {
    if let token = timeObserverToken {
      player.removeTimeObserver(token)
      timeObserverToken = nil
    }
  }
}
