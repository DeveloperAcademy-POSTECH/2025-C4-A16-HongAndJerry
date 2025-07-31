//
//  PlayerController.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import AVKit
import Observation

/// `AVPlayer`를 래핑하여 재생, 일시정지, 탐색 및 시간 관리를 위한 간단한 인터페이스를 제공하는 컨트롤러입니다.
///
/// 이 클래스는 UI와 안전하게 상호작용하기 위해 메인 액터(`@MainActor`)에서 실행되며,
/// SwiftUI 뷰가 상태 변화를 감지할 수 있도록 `@Observable`로 선언되었습니다.
@MainActor
@Observable
class PlayerController {
    /// 비디오 재생을 처리하는 핵심 AVPlayer 객체입니다.
    /// 외부에서는 읽기만 가능하도록 제한합니다.
    let player = AVPlayer()
    
    /// 현재 플레이어가 재생 중인지 여부를 나타냅니다.
    /// UI의 재생/일시정지 버튼 상태를 바인딩하는 데 사용됩니다.
    var isPlaying: Bool = false
    
    /// 현재 재생 시간을 나타냅니다.
    /// 타임라인의 플레이헤드 위치나 시간 표시에 사용됩니다.
    var currentTime: CMTime = .zero
    
    /// 현재 재생 아이템의 총 길이를 나타냅니다.
    var totalDuration: CMTime = .zero
    
    /// AVPlayer의 시간 변경을 감지하는 옵저버의 토큰입니다.
    /// 옵저버를 제거할 때 필요하므로 속성으로 저장해야 합니다.
    private var timeObserverToken: Any?
    
    /// 현재 재생 아이템을 새로운 AVPlayerItem으로 교체합니다.
    ///
    /// - Parameter item: 새로 재생할 `AVPlayerItem`. `nil`일 경우 플레이어를 비웁니다.
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
    
    /// 재생을 시작합니다.
    func play() {
        player.play()
        isPlaying = true
    }
    
    /// 재생을 일시정지합니다.
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    /// 지정된 시간으로 플레이헤드를 이동시킵니다.
    ///
    /// - Parameter time: 이동할 대상 시간.
    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - Private Methods
    
    /// 플레이어에 주기적인 시간 옵저버를 추가합니다.
    private func addTimeObserver() {
        // 기존 옵저버가 있다면 중복 추가를 방지하기 위해 먼저 제거합니다.
        removeTimeObserver()
        
        // 1/60초 간격으로 메인 스레드에서 currentTime을 업데이트합니다.
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
    
    /// 플레이어에서 주기적인 시간 옵저버를 제거합니다.
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
