import AVKit
import Observation

@MainActor
@Observable
final class EditorViewModel {
  var segments: [VideoSegment] = []
  private var playerItem: AVPlayerItem?
  var isLoading: Bool = true
  var isTrimming: Bool = false
  var trimmingHandleType: HandlesView.HandleType?
  var selectedSegmentID: UUID?
  var screenWidth: CGFloat = 0
  var shouldShakeCheckButton: Bool = false
  
  var isFullScreen: Bool = false
  
  let playerController = PlayerController()
  let exportController = ExportController()
  
  private let compositionBuilder = CompositionBuilder()
  
  // MARK: - Timeline Drag State
  var isTimelineDragging: Bool = false
  var currentTimelineOffset: CGFloat = 0
  var dragDirection: DragDirection = .none
  private var startDragOffset: CGFloat = 0
  private var lastDragTranslation: CGFloat = 0
  private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  private var lastHapticSecond: Int = -1
  
  // MARK: - Export State
  private var _showExportConfirmAlert: Bool = false
  private var _showResultAlert: Bool = false
  
  init(segments: [VideoSegment]) {
    Task {
      self.segments = segments
      await initializePlayer()
    }
  }
  
  private func initializePlayer() async {
    isLoading = true
    
    guard !segments.isEmpty else {
      isLoading = false
      return
    }
    
    await rebuildPlayerItem()
    isLoading = false
  }
  
  private func rebuildPlayerItem() async {
    do {
      guard !segments.isEmpty else {
        playerController.replaceCurrentItem(with: nil)
        return
      }
      
      let buildResult = try await compositionBuilder.build(from: segments)
      self.playerItem = buildResult.playerItem
      
      playerController.replaceCurrentItem(with: buildResult.playerItem)
    } catch {
      print("Error rebuilding player item: \(error)")
    }
  }
  
  func updateScreenWidth(_ width: CGFloat) {
    screenWidth = width
  }
  
  func editVideo(operation: EditOperation) async {
    do {
      let result = try await operation.apply(on: segments)
      
      switch result {
      case .segmentsUpdated(let updatedSegments):
        self.segments = updatedSegments
        await rebuildPlayerItem()
        
      case .exportCompleted(let url):
        print("Export completed at: \(url)")
        
      case .noChange:
        break
      }
    } catch {
      print("Failed to perform edit operation: \(error)")
    }
  }
  
  func getFinalVideoAsset() -> AVAsset? {
    if let playerItem = self.playerItem {
      return playerItem.asset
    } else {
      return nil
    }
  }
  
  func getFinalVideoComposition() -> AVVideoComposition? {
    if let playerItem = self.playerItem {
      return playerItem.videoComposition
    } else {
      return nil
    }
  }
  
  func activateTrimming(segmentID: UUID) async {
    if isTrimming, let currentSelectedID = selectedSegmentID, currentSelectedID != segmentID {
      triggerCheckButtonShake()
      return
    }
    
    selectedSegmentID = segmentID
    
    if let segment = segments.first(where: { $0.id == segmentID }) {
      let singlePlayerItem = AVPlayerItem(asset: segment.source.asset)
      let endTime = CMTimeAdd(segment.startTime, segment.trimmedDuration)
      singlePlayerItem.forwardPlaybackEndTime = endTime
      
      playerController.replaceCurrentItem(with: singlePlayerItem)
      playerController.pause()
    }
  }
  
  func triggerCheckButtonShake() {
    shouldShakeCheckButton = true
    
    Task {
      try? await Task.sleep(nanoseconds: 500_000_000)
      shouldShakeCheckButton = false
    }
  }
  
  func startTrimming(handleType: HandlesView.HandleType) {
    isTrimming = true
    trimmingHandleType = handleType
  }
  
  func endTrimming() {
    trimmingHandleType = nil
  }
  
  func confirmTrimming() async {
    isTrimming = false
    trimmingHandleType = nil
    selectedSegmentID = nil
    
    await rebuildPlayerItem()
  }
  
  func updateTrimRange(start: Double, end: Double) async {
    guard let selectedID = selectedSegmentID,
          let index = segments.firstIndex(where: { $0.id == selectedID }) else { return }
    
    let segment = segments[index]
    let clampedStart = max(0, min(start, end - TrimmingConstants.minTrimDuration))
    let clampedEnd = max(clampedStart + TrimmingConstants.minTrimDuration, min(end, segment.source.duration.seconds))
    
    segments[index].startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
    segments[index].trimmedDuration = CMTime(seconds: clampedEnd - clampedStart, preferredTimescale: 600)
  }
  
  func scrollOffsetForTrimStart() -> CGFloat? {
    guard
      let handleType = trimmingHandleType,
      let selectedID = selectedSegmentID,
      let segment = segments.first(where: { $0.id == selectedID })
    else { return nil }
    
    switch handleType {
    case .left:
      return 0
      
    case .right:
      let visualRightEnd =
      segment.startTime.seconds + segment.trimmedDuration.seconds
      return -(visualRightEnd * EditConstants.pixelsPerSecond)
    }
  }
  
  func getSegmentEndTimes(excluding segmentID: UUID) -> [Double] {
    segments
      .filter { $0.id != segmentID }
      .map { $0.trimmedDuration.seconds }
  }
}

// MARK: - Timeline Drag Logic

extension EditorViewModel {
  // MARK: - Drag Handling Methods
  
  /// 드래그 시작 처리
  func handleTimelineDragStarted() {
    playerController.pause()
    self.isTimelineDragging = true
    self.startDragOffset = currentTimelineOffset
    self.lastDragTranslation = 0
  }
  
  /// 드래그 중 처리
  func handleTimelineDragChanged(translation: CGFloat) {
    let delta = translation - lastDragTranslation
    self.dragDirection = calculateDragDirection(delta: delta)
    self.lastDragTranslation = translation
    
    let newOffset = startDragOffset + translation
    updateTimelineOffset(newOffset, isDragging: true, direction: dragDirection)
  }
  
  /// 드래그 종료 처리
  func handleTimelineDragEnded() {
    self.isTimelineDragging = false
    self.lastHapticSecond = -1
    self.lastDragTranslation = 0
    
    let clampedOffset = clampTimelineOffset(currentTimelineOffset)
    seekToTimelineOffset(clampedOffset, direction: .none)
  }
  
  /// 타임라인 스크롤 처리 (NotificationCenter용)
  func handleTimelineScroll(to offset: CGFloat) {
    self.currentTimelineOffset = clampTimelineOffset(offset)
  }
  
  /// 재생 상태 변경 처리
  func handlePlayingStateChanged(isPlaying: Bool) {
    guard isPlaying, !isTimelineDragging else { return }
    
    let currentSeconds = playerController.player.currentTime().seconds
    self.currentTimelineOffset = -(currentSeconds * EditConstants.pixelsPerSecond)
  }
  
  /// 현재 시간 변경 처리
  func handleCurrentTimeChanged() {
    guard !isTimelineDragging else { return }
    
    checkPlaybackEnd()
    
    let isTrimmingRightHandle = isTrimming && trimmingHandleType == .right
    if isTrimmingRightHandle {
      updateOffsetForTrimmingRightHandle()
    } else if playerController.isPlaying {
      let newOffset = -(playerController.currentTime.seconds * EditConstants.pixelsPerSecond)
      self.currentTimelineOffset = newOffset
    }
  }
  
  // MARK: - Private Helper Methods
  
  private func calculateDragDirection(delta: CGFloat) -> DragDirection {
    if delta > 0 {
      return .backward
    } else if delta < 0 {
      return .forward
    } else {
      return .none
    }
  }
  
  private func clampTimelineOffset(_ offset: CGFloat) -> CGFloat {
    let maxOffset: CGFloat = 0
    let minOffset: CGFloat
    
    if let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let trimmedWidth = segment.trimmedDuration.seconds * EditConstants.pixelsPerSecond
      minOffset = -trimmedWidth
    } else {
      let totalTimelineWidth = playerController.totalDuration.seconds * EditConstants.pixelsPerSecond
      minOffset = -totalTimelineWidth
    }
    
    return min(maxOffset, max(minOffset, offset))
  }
  
  private func updateTimelineOffset(_ newOffset: CGFloat, isDragging: Bool, direction: DragDirection) {
    let clampedOffset = clampTimelineOffset(newOffset)
    self.currentTimelineOffset = clampedOffset
    if isDragging {
      seekToTimelineOffset(clampedOffset, direction: direction)
    }
  }
  
  private func seekToTimelineOffset(_ offset: CGFloat, direction: DragDirection) {
    let newTimeInSeconds = -offset / EditConstants.pixelsPerSecond
    let clampedTime = max(0, newTimeInSeconds)
    
    // Haptic feedback
    let currentSecond = Int(clampedTime)
    if currentSecond != lastHapticSecond {
      feedbackGenerator.impactOccurred()
      lastHapticSecond = currentSecond
    }
    
    playerController.seek(
      to: CMTime(seconds: clampedTime, preferredTimescale: 600),
      direction: direction
    )
  }
  
  private func checkPlaybackEnd() {
    guard playerController.isPlaying else { return }
    
    let currentSeconds = playerController.currentTime.seconds
    let threshold = 0.05
    
    if let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let endTime = segment.startTime.seconds + segment.trimmedDuration.seconds
      if abs(currentSeconds - endTime) < threshold || currentSeconds >= endTime {
        playerController.pause()
      }
    } else {
      let totalDuration = playerController.totalDuration.seconds
      if abs(currentSeconds - totalDuration) < threshold || currentSeconds >= totalDuration {
        playerController.pause()
      }
    }
  }
  
  private func updateOffsetForTrimmingRightHandle() {
    guard let selectedID = selectedSegmentID,
          let segment = segments.first(where: { $0.id == selectedID }) else {
      return
    }
    
    let visualRightEnd = playerController.currentTime.seconds - segment.startTime.seconds
    self.currentTimelineOffset = -(visualRightEnd * EditConstants.pixelsPerSecond)
  }
}

// MARK: - Export Logic

extension EditorViewModel {
  // MARK: - Export State Properties
  
  var showExportConfirmAlert: Bool {
    get { _showExportConfirmAlert }
    set { _showExportConfirmAlert = newValue }
  }
  
  var showResultAlert: Bool {
    get { _showResultAlert }
    set { _showResultAlert = newValue }
  }
  
  // MARK: - Export Methods
  
  /// 내보내기 요청
  func requestExport() {
    showExportConfirmAlert = true
  }
  
  /// 내보내기 처리
  func handleExport(router: Router) {
    guard let video = getFinalVideoAsset() else { return }
    let composition = getFinalVideoComposition()
    
    exportController.saveVideo(
      video: video,
      videoComposition: composition
    ) { [weak self] in
      self?.showResultAlert = true
    }
  }
  
  /// Alert 닫기 처리
  func handleAlertDismiss(router: Router) {
    if exportController.alertModel.title == ExportNameSpace.AlertSuccessMessage.title {
      router.popToRoot()
    }
  }
}
