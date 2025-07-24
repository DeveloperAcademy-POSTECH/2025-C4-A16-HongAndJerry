//
//  VideoViewModel.swift
//  HongAndJerry
//
//  Created by Gemini on 7/18/25.
//

import AVKit
import Observation

/// 앱의 모든 비디오 편집 상태와 비즈니스 로직을 총괄하는 중앙 허브입니다.
///
/// 이 ViewModel은 "Executive Producer" 역할을 수행하며, 다음을 책임집니다:
/// - `VideoSegment` 배열을 "Single Source of Truth"로 관리합니다.
/// - `CompositionBuilder`를 사용하여 AVFoundation 컴포지션을 생성합니다.
/// - `PlayerController`를 통해 비디오 재생을 제어합니다.
/// - UI로부터 모든 편집 요청(예: 트림, 순서 변경)을 받아 처리합니다.
@MainActor
@Observable
final class VideoViewModel {
    /// 프로젝트의 현재 상태를 나타내는 비디오 세그먼트의 배열입니다. 이 배열이 앱의 유일한 진실 공급원(Source of Truth)입니다.
    var segments: [VideoSegment] = []
    
    /// 비디오 재생을 관리하는 `AVPlayer`의 래퍼(wrapper)입니다.
    let playerController = PlayerController()
    
    private var trimController = TrimController()
    
    /// 컴포지션 생성을 담당하는 상태 없는(stateless) 빌더입니다.
    private let compositionBuilder = CompositionBuilder()

    /// 현재 비디오 플레이어가 전체 화면 모드인지 여부를 나타냅니다.
    var isFullScreen: Bool = false
    
    /// 각 세그먼트의 좌측/우측 핸들 오프셋을 저장하는 딕셔너리
    /// Key: 세그먼트 ID, Value: (좌측 핸들 오프셋, 우측 핸들 오프셋)
    var segmentHandleOffsets: [UUID: (left: CGFloat, right: CGFloat)] = [:]

    /// 현재 선택된 세그먼트의 ID (트림 작업 대상)
    var selectedSegmentID: UUID?
    
    var scrollOffset: CGFloat = 0
    var screenWidth: CGFloat = 0
    var trackWidth: CGFloat = 0
    
    func getHandleOffset(
        segmentID: UUID,
        handleType: HandleType,
        trackWidth: CGFloat
    ) -> CGFloat {
        guard let offsets = segmentHandleOffsets[segmentID] else { return 0 }
        
        switch handleType {
        case .left:
            return offsets.left
        case .right:
            return offsets.right - trackWidth
        case .none:
            return 0
        }
    }

    init() {
        Task {
            await loadInitialSegments()
            setHandleOffsets()
            if let firstSegment = segments.first {
                selectSegment(firstSegment.id)
            }
            await rebuildPlayerItem()
        }
    }
    
    init(segments: [VideoSegment]) {
        Task {
            self.segments = segments
            await rebuildPlayerItem()
        }
    }
    
    /// 앱 시작 시 초기 비디오 세그먼트를 비동기적으로 로드합니다.
    /// `VideoSegment.mockList()` 비동기 함수를 사용합니다.
    private func loadInitialSegments() async {
        self.segments = await VideoSegment.mockList()
    }
    
    /// 현재 `segments` 배열의 상태를 기반으로 `AVPlayerItem`을 다시 빌드하고 플레이어를 업데이트합니다.
    /// 편집 작업(트림, 재정렬 등)이 발생할 때마다 호출되어야 합니다.
    private func rebuildPlayerItem() async {
        do {
            // 세그먼트가 비어있으면 플레이어를 비웁니다.
            guard !segments.isEmpty else {
                playerController.replaceCurrentItem(with: nil)
                return
            }
            
            let buildResult = try await compositionBuilder.build(from: segments)
            playerController.replaceCurrentItem(with: buildResult.playerItem)
        } catch {
            print("플레이어 아이템을 다시 빌드하는 중 오류 발생: \(error)")
        }
    }
    
    /// 현재 화면의 너비를 업데이트합니다.
    /// - Parameter width: 새로운 화면 너비 (CGFloat)
    func updateScreenWidth(_ width: CGFloat) {
        screenWidth = width
    }
    
    /// 스크롤 오프셋을 업데이트합니다.
    /// - Parameter offset: 새로운 스크롤 오프셋 (ScrollView에서 현재 화면 좌측면이 위치한 offset입니다)
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset - (screenWidth / 2)
    }
    
    /// 현재 조작하고자 하는 트랙을 선택합니다.
    /// - Parameter segmentID: 선택할 세그먼트의 고유 식별자
    func selectSegment(_ segmentID: UUID) {
       selectedSegmentID = segmentID
    }
    
    /// 각 트랙 핸들의 offset을 초기화합니다.
    /// 모든 세그먼트에 대해 시작 시간과 지속 시간을 기반으로 핸들 위치를 계산합니다.
    private func setHandleOffsets() {
        for segment in segments {
            let offsets = trimController.initializeHandleOffsets(
                segmentID: segment.id,
                segments: segments
            )
            segmentHandleOffsets[segment.id] = offsets
        }
    }
    
    /// 핸들을 드래그할 때 호출합니다. 핸들의 offset을 업데이트 합니다.
    /// - Parameters:
    ///   - type: 드래그 중인 핸들의 타입 (좌측/우측)
    ///   - translation: 드래그로 인한 이동 거리 (픽셀 단위)
    func onHandleDrag(
        type: HandleType,
        translation: CGFloat
    ) {
        guard let selectedID = selectedSegmentID,
        let oldOffsets = segmentHandleOffsets[selectedID] else {
            return
        }
        
        let newOffsets = trimController.dragHandle(
            oldOffsets: oldOffsets,
            handleType: type,
            translation: translation,
            screenWidth: screenWidth
        )
        
        segmentHandleOffsets[selectedID] = newOffsets
    }
    
    /// 핸들 드래그가 끝나면 호출하며 Operation의 apply를 호출해서 segment를 업데이트 합니다.
    /// 최종적으로 변경된 오프셋을 시간으로 변환하여 세그먼트에 적용하고 플레이어를 다시 빌드합니다.
    func onHandleDragEnd() async {
        guard let selectedID = selectedSegmentID,
              let currentOffsets = segmentHandleOffsets[selectedID],
              let segment = segments.first(where: { $0.id == selectedID }) else {
            return
        }
        
        let newStartTime = EditConstants.convertOffsetToTime(currentOffsets.left)
        let newDuration = EditConstants.convertOffsetToTime(currentOffsets.right - currentOffsets.left)
        
        let trimOperation = TrimOperation(
            segmentID: selectedID,
            newStartTime: newStartTime,
            newDuration: newDuration
        )
        
        do {
            let result = try await trimOperation.apply(on: segments)
            
            if case .segmentsUpdated(let updatedSegments) = result {
                segments = updatedSegments
                await rebuildPlayerItem()
            }
        } catch {
            print("@log - failed Trimming: \(error)")
        }
    }
    
    func editVideo(operation: EditOperation) async {
        do {
            // 1. 전달받은 operation을 현재 segments에 적용합니다.
            let result = try await operation.apply(on: segments)
            
            // 2. operation의 실행 결과를 처리합니다.
            switch result {
            case .segmentsUpdated(let updatedSegments):
                // 3. 결과로 받은 segments로 교체합니다.
                self.segments = updatedSegments
                
                // 4. 변경된 segments를 기반으로 플레이어를 다시 빌드합니다.
                await rebuildPlayerItem()
                
            case .exportCompleted(let url):
                // 비디오 익스포트가 완료되었을 때의 로직 (필요시 구현)
                print("Export completed at: \(url)")
                
            case .noChange:
                // 변경 사항이 없을 경우 아무것도 하지 않습니다.
                break
            }
        } catch {
            // operation 적용 중 에러가 발생하면 로그를 출력합니다.
            print("Failed to perform edit operation: \(error)")
        }
    }
}
