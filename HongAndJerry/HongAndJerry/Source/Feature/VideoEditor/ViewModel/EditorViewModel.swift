import AVKit
import Observation
import Photos

@MainActor
@Observable
final class EditorViewModel {
  
  var isLoading: Bool = true
  var isTrimming: Bool = false
  var trimmingHandleType: HandlesView.HandleType?
  var selectedSegmentID: UUID?
  var screenWidth: CGFloat = 0
  var shouldShakeCheckButton: Bool = false
  var isFullScreen: Bool = false
  
  var isTimelineDragging: Bool = false
  var currentTimelineOffset: CGFloat = 0
  var dragDirection: DragDirection = .none
  private var startDragOffset: CGFloat = 0
  private var lastDragTranslation: CGFloat = 0
  private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  private var lastHapticSecond: Int = -1
  
  private var _showExportConfirmAlert: Bool = false
  private var _showResultAlert: Bool = false
  
  private let playerUseCase: PlayerUseCase
  private let editUseCase: EditUseCase
  private let exportUseCase: ExportUseCase
  
  var segments: [VideoSegment] {
    get { editUseCase.segments }
    set { editUseCase.segments = newValue }
  }
  
  var player: AVPlayer {
    playerUseCase.player
  }
  
  var isPlaying: Bool {
    playerUseCase.isPlaying
  }
  
  var currentTime: CMTime {
    playerUseCase.currentTime
  }
  
  var totalDuration: CMTime {
    playerUseCase.totalDuration
  }
  
  var showExportConfirmAlert: Bool {
    get { _showExportConfirmAlert }
    set { _showExportConfirmAlert = newValue }
  }
  
  var showResultAlert: Bool {
    get { _showResultAlert }
    set { _showResultAlert = newValue }
  }
  
  var exportIsLoading: Bool {
    exportUseCase.isLoading
  }
  
  var exportProgress: Double {
    exportUseCase.progress
  }
  
  var exportAlert: ExportAlert {
    exportUseCase.alertModel
  }
  
  init(
    crops: [Crop],
    playerUseCase: PlayerUseCase = PlayerUseCase(),
    exportUseCase: ExportUseCase = ExportUseCase(),
    editUseCase: EditUseCase = EditUseCase(
      compositionRepository: AVMutableCompositionRepository()
    )
  ) {
    self.playerUseCase = playerUseCase
    self.exportUseCase = exportUseCase
    self.editUseCase = editUseCase

    Task {
      await createSegments(from: crops)
      await initializePlayer()
    }
  }

  convenience init(segments: [VideoSegment]) {
    self.init(
      crops: [],
      playerUseCase: PlayerUseCase(),
      exportUseCase: ExportUseCase(),
      editUseCase: EditUseCase(
        compositionRepository: AVMutableCompositionRepository()
      )
    )

    Task {
      self.editUseCase.initializeSegments(segments)
      await initializePlayer()
    }
  }
  
  private func createSegments(from crops: [Crop]) async {
    isLoading = true

    do {
      let segments = try await editUseCase.createSegmentsFromCrops(crops)
    } catch {
      print("Error processing crops: \(error)")
      isLoading = false
    }
  }

  private func initializePlayer() async {
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
        playerUseCase.replaceCurrentItem(with: nil)
        return
      }
      
      let playerItem = try await editUseCase.rebuildPlayerItem()
      playerUseCase.replaceCurrentItem(with: playerItem)
      
    } catch {
      print("Error rebuilding player item: \(error)")
    }
  }
  
  func getFinalVideoAsset() -> AVAsset? {
    editUseCase.getFinalVideoAsset()
  }
  
  func getFinalVideoComposition() -> AVVideoComposition? {
    editUseCase.getFinalVideoComposition()
  }
  
  func activateTrimming(segmentID: UUID) async {
    if isTrimming,
       let currentSelectedID = selectedSegmentID,
       currentSelectedID != segmentID {
      triggerCheckButtonShake()
      return
    }
    
    selectedSegmentID = segmentID
    
    if let playerItem = editUseCase.createTrimmingPlayerItem(for: segmentID) {
      playerUseCase.replaceCurrentItem(with: playerItem)
      playerUseCase.pause()
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
    guard let selectedID = selectedSegmentID else { return }
    editUseCase.updateTrimRange(segmentID: selectedID, start: start, end: end)
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
      let visualRightEnd = segment.startTime.seconds + segment.trimmedDuration.seconds
      return -(visualRightEnd * EditConstants.pixelsPerSecond)
    }
  }
  
  func getSegmentEndTimes(excluding segmentID: UUID) -> [Double] {
    editUseCase.getSegmentEndTimes(excluding: segmentID)
  }
  
  func toggleAudioMute(segmentID: UUID) async throws {
    if let playerItem = try await editUseCase.toggleAudioMute(segmentID: segmentID) {
      playerUseCase.replaceCurrentItem(with: playerItem)
    }
  }
  
  func play() {
    playerUseCase.play()
  }
  
  func pause() {
    playerUseCase.pause()
  }
  
  func seek(to time: CMTime, direction: DragDirection = .none) {
    playerUseCase.seek(to: time, direction: direction)
  }
  
  func updateScreenWidth(_ width: CGFloat) {
    screenWidth = width
  }
  
  func handleTimelineDragStarted() {
    playerUseCase.pause()
    isTimelineDragging = true
    startDragOffset = currentTimelineOffset
    lastDragTranslation = 0
  }
  
  func handleTimelineDragChanged(translation: CGFloat) {
    let delta = translation - lastDragTranslation
    dragDirection = calculateDragDirection(delta: delta)
    lastDragTranslation = translation
    
    let newOffset = startDragOffset + translation
    updateTimelineOffset(newOffset, isDragging: true, direction: dragDirection)
  }
  
  func handleTimelineDragEnded() {
    isTimelineDragging = false
    lastHapticSecond = -1
    lastDragTranslation = 0
    
    let clampedOffset = clampTimelineOffset(currentTimelineOffset)
    seekToTimelineOffset(clampedOffset, direction: .none)
  }
  
  func handleTimelineScroll(to offset: CGFloat) {
    currentTimelineOffset = clampTimelineOffset(offset)
  }
  
  func handlePlayingStateChanged(isPlaying: Bool) {
    guard isPlaying, !isTimelineDragging else { return }
    
    let currentSeconds = playerUseCase.player.currentTime().seconds
    currentTimelineOffset = -(currentSeconds * EditConstants.pixelsPerSecond)
  }
  
  func handleCurrentTimeChanged() {
    guard !isTimelineDragging else { return }
    
    checkPlaybackEnd()
    
    if isTrimming, trimmingHandleType == .right {
      updateOffsetForTrimmingRightHandle()
    } else if playerUseCase.isPlaying {
      currentTimelineOffset = -(playerUseCase.currentTime.seconds * EditConstants.pixelsPerSecond)
    }
  }
  
  private func calculateDragDirection(delta: CGFloat) -> DragDirection {
    delta > 0 ? .backward : (delta < 0 ? .forward : .none)
  }
  
  private func clampTimelineOffset(_ offset: CGFloat) -> CGFloat {
    let maxOffset: CGFloat = 0
    let minOffset: CGFloat
    
    if let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let trimmedWidth = segment.trimmedDuration.seconds * EditConstants.pixelsPerSecond
      minOffset = -trimmedWidth
    } else {
      let totalTimelineWidth = totalDuration.seconds * EditConstants.pixelsPerSecond
      minOffset = -totalTimelineWidth
    }
    
    return min(maxOffset, max(minOffset, offset))
  }
  
  private func updateTimelineOffset(
    _ newOffset: CGFloat,
    isDragging: Bool,
    direction: DragDirection
  ) {
    let clampedOffset = clampTimelineOffset(newOffset)
    currentTimelineOffset = clampedOffset
    
    if isDragging {
      seekToTimelineOffset(clampedOffset, direction: direction)
    }
  }
  
  private func seekToTimelineOffset(_ offset: CGFloat, direction: DragDirection) {
    let newTime = max(0, -offset / EditConstants.pixelsPerSecond)
    
    let currentSecond = Int(newTime)
    if currentSecond != lastHapticSecond {
      feedbackGenerator.impactOccurred()
      lastHapticSecond = currentSecond
    }
    
    playerUseCase.seek(
      to: CMTime(seconds: newTime, preferredTimescale: 600),
      direction: direction
    )
  }
  
  private func checkPlaybackEnd() {
    guard playerUseCase.isPlaying else { return }
    
    let currentSeconds = playerUseCase.currentTime.seconds
    let threshold = 0.05
    
    if let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let endTime = segment.startTime.seconds + segment.trimmedDuration.seconds
      if abs(currentSeconds - endTime) < threshold || currentSeconds >= endTime {
        playerUseCase.pause()
      }
    } else if abs(currentSeconds - totalDuration.seconds) < threshold
                || currentSeconds >= totalDuration.seconds {
      playerUseCase.pause()
    }
  }
  
  private func updateOffsetForTrimmingRightHandle() {
    guard let selectedID = selectedSegmentID,
          let segment = segments.first(where: { $0.id == selectedID }) else { return }
    
    let visualRightEnd = playerUseCase.currentTime.seconds - segment.startTime.seconds
    currentTimelineOffset = -(visualRightEnd * EditConstants.pixelsPerSecond)
  }
  
  func requestExport() {
    showExportConfirmAlert = true
  }
  
  func handleExport(router: Router) {
    guard let video = getFinalVideoAsset() else { return }
    let composition = getFinalVideoComposition()
    
    exportUseCase.saveVideo(
      video: video,
      videoComposition: composition
    ) { [weak self] in
      self?.showResultAlert = true
    }
  }
  
  func handleAlertDismiss(router: Router) {
    if exportUseCase.alertModel.title == ExportNameSpace.AlertSuccessMessage.title {
      router.popToRoot()
    }
  }
}
