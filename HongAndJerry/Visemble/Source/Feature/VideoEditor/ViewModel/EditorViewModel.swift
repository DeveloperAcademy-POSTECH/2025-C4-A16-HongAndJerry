import AVKit
import Observation
import Photos

@MainActor
@Observable
final class EditorViewModel {

  enum EditorState {
    case loading
    case editing
    case trimming
    case fullScreen
  }

  enum Action {
    // Lifecycle
    case load

    // Playback
    case play
    case pause
    case seek(to: CMTime, direction: DragDirection = .none)

    // Trimming
    case activateTrimming(segmentID: UUID)
    case deactivateTrimming
    case startTrimming(handleType: HandlesView.HandleType)
    case endTrimming
    case confirmTrimming
    case updateTrimRange(start: Double, end: Double)
    case seekSelectedOnly(to: CMTime)

    // Audio
    case toggleAudioMute(segmentID: UUID)

    // Timeline
    case timelineScroll(to: CGFloat)
    case playingStateChanged(isPlaying: Bool)
    case currentTimeChanged
    case updateScreenWidth(CGFloat)

    // Timeline drag
    case timelineDragStarted
    case timelineDragChanged(translation: CGFloat)
    case timelineDragEnded

    // Full screen
    case enterFullScreen
    case exitFullScreen

    // Export
    case requestExport
    case handleExport(router: Router)
    case handleAlertDismiss(router: Router)
  }

  var state: EditorState = .loading
  var trimmingHandleType: HandlesView.HandleType?
  var selectedSegmentID: UUID?
  var screenWidth: CGFloat = 0
  var shouldShakeCheckButton: Bool = false

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
  private let cropUseCase: CropUseCase
  private let exportUseCase: ExportUseCase
  private var trimmingPlayerUseCase: TrimmingPlayerUseCase?

  // MARK: - Computed Properties

  var isLoading: Bool { state == .loading }
  var isTrimming: Bool { state == .trimming }
  var isFullScreen: Bool { state == .fullScreen }

  var isTrimmingPreviewActive: Bool {
    selectedSegmentID != nil && trimmingPlayerUseCase != nil
  }

  var trimmingSegmentPlayers: [TrimmingPlayerUseCase.SegmentPlayer] {
    trimmingPlayerUseCase?.segmentPlayers ?? []
  }

  var segments: [VideoSegment] {
    get { editUseCase.segments }
    set { editUseCase.segments = newValue }
  }

  var player: AVPlayer {
    playerUseCase.player
  }

  var isPlaying: Bool {
    trimmingPlayerUseCase?.isPlaying ?? playerUseCase.isPlaying
  }

  var currentTime: CMTime {
    trimmingPlayerUseCase?.currentTime ?? playerUseCase.currentTime
  }

  var totalDuration: CMTime {
    trimmingPlayerUseCase?.totalDuration ?? playerUseCase.totalDuration
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

  private var crops: [Crop]
  private var initialSegments: [VideoSegment]?

  init(
    crops: [Crop],
    playerUseCase: PlayerUseCase = PlayerUseCase(),
    cropUseCase: CropUseCase = CropUseCase(
      assetLoadRepository: PHAssetRepository(),
      videoEditRepository: AVVideoEditRepository()
    ),
    exportUseCase: ExportUseCase = ExportUseCase(
      albumRepository: PHAssetRepository(),
      videoEditRepository: AVVideoEditRepository()
    ),
    editUseCase: EditUseCase = EditUseCase(
      compositionRepository: AVMutableCompositionRepository()
    )
  ) {
    self.crops = crops
    self.initialSegments = nil
    self.playerUseCase = playerUseCase
    self.cropUseCase = cropUseCase
    self.exportUseCase = exportUseCase
    self.editUseCase = editUseCase
  }

  init(
    segments: [VideoSegment],
    playerUseCase: PlayerUseCase = PlayerUseCase(),
    cropUseCase: CropUseCase = CropUseCase(
      assetLoadRepository: PHAssetRepository(),
      videoEditRepository: AVVideoEditRepository()
    ),
    exportUseCase: ExportUseCase = ExportUseCase(
      albumRepository: PHAssetRepository(),
      videoEditRepository: AVVideoEditRepository()
    ),
    editUseCase: EditUseCase = EditUseCase(
      compositionRepository: AVMutableCompositionRepository()
    )
  ) {
    self.crops = []
    self.initialSegments = segments
    self.playerUseCase = playerUseCase
    self.cropUseCase = cropUseCase
    self.exportUseCase = exportUseCase
    self.editUseCase = editUseCase
  }

  func send(_ action: Action) {
    switch action {
    case .load:
      Task { await load() }

    case .play:
      if let tuc = trimmingPlayerUseCase { tuc.playAll() }
      else { playerUseCase.play() }
    case .pause:
      if let tuc = trimmingPlayerUseCase { tuc.pauseAll() }
      else { playerUseCase.pause() }
    case .seek(let time, let direction):
      if let tuc = trimmingPlayerUseCase { tuc.seekAll(to: time, direction: direction) }
      else { playerUseCase.seek(to: time, direction: direction) }
    case .activateTrimming(let segmentID):
      Task { await activateTrimming(segmentID: segmentID) }
    case .deactivateTrimming:
      Task { await deactivateTrimming() }
    case .startTrimming(let handleType):
      state = .trimming
      trimmingHandleType = handleType
    case .endTrimming:
      trimmingHandleType = nil
    case .confirmTrimming:
      Task { await confirmTrimming() }
    case .updateTrimRange(let start, let end):
      Task { await updateTrimRange(start: start, end: end) }
    case .seekSelectedOnly(let time):
      trimmingPlayerUseCase?.seekSelected(to: time)

    case .toggleAudioMute(let segmentID):
      Task { try? await toggleAudioMute(segmentID: segmentID) }

    case .timelineScroll(let offset):
      handleTimelineScroll(to: offset)
    case .playingStateChanged(let isPlaying):
      handlePlayingStateChanged(isPlaying: isPlaying)
    case .currentTimeChanged:
      handleCurrentTimeChanged()
    case .updateScreenWidth(let width):
      screenWidth = width

    case .timelineDragStarted:
      handleTimelineDragStarted()
    case .timelineDragChanged(let translation):
      handleTimelineDragChanged(translation: translation)
    case .timelineDragEnded:
      handleTimelineDragEnded()

    case .enterFullScreen:
      state = .fullScreen
    case .exitFullScreen:
      state = .editing

    case .requestExport:
      showExportConfirmAlert = true
    case .handleExport(let router):
      handleExport(router: router)
    case .handleAlertDismiss(let router):
      handleAlertDismiss(router: router)
    }
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

  private func load() async {
    guard segments.isEmpty else {
      await initializePlayer()
      return
    }

    if let initialSegments {
      editUseCase.setSegments(initialSegments)
    } else if !crops.isEmpty {
      await createSegments(from: crops)
    }
    await initializePlayer()
  }

  private func createSegments(from crops: [Crop]) async {
    state = .loading
    

    do {
      let cropResults = try await cropUseCase.execute(crops: crops)
      editUseCase.initializeSegmentsFromCropResults(cropResults)
    } catch {
      print("Error processing crops: \(error)")
      state = .editing
    }
  }

  private func initializePlayer() async {
    guard !segments.isEmpty else {
      state = .editing
      return
    }

    await rebuildPlayerItem()

    state = .editing

    if let firstSegmentID = segments.first?.id {
      await activateTrimming(segmentID: firstSegmentID)
    }
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

  private func getFinalVideoAsset() -> AVAsset? {
    editUseCase.getFinalVideoAsset()
  }

  private func getFinalVideoComposition() -> AVVideoComposition? {
    editUseCase.getFinalVideoComposition()
  }

  private func activateTrimming(segmentID: UUID) async {
    if let currentSelectedID = selectedSegmentID {
      if currentSelectedID == segmentID {
        await deactivateTrimming()
        return
      } else {
        // 다른 세그먼트로 전환: 기존 3-Player 유지하며 선택만 변경
        selectedSegmentID = segmentID
        trimmingPlayerUseCase?.updateSelectedSegment(newID: segmentID)
        return
      }
    }

    selectedSegmentID = segmentID

    // 3-Player 생성
    let tuc = TrimmingPlayerUseCase()
    await tuc.setup(segments: segments, selectedID: segmentID)
    trimmingPlayerUseCase = tuc

    // 메인 플레이어 pause (화면에서 숨김)
    playerUseCase.pause()
  }

  private func triggerCheckButtonShake() {
    shouldShakeCheckButton = true

    Task {
      try? await Task.sleep(nanoseconds: 500_000_000)
      shouldShakeCheckButton = false
    }
  }

  private func deactivateTrimming() async {
    guard selectedSegmentID != nil else { return }
    state = .editing
    trimmingHandleType = nil
    selectedSegmentID = nil
    trimmingPlayerUseCase?.cleanup()
    trimmingPlayerUseCase = nil
    await rebuildPlayerItem()
  }

  private func confirmTrimming() async {
    state = .editing
    trimmingHandleType = nil
    selectedSegmentID = nil
    trimmingPlayerUseCase?.cleanup()
    trimmingPlayerUseCase = nil
    await rebuildPlayerItem()
  }

  private func updateTrimRange(start: Double, end: Double) async {
    guard let selectedID = selectedSegmentID else { return }
    editUseCase.updateTrimRange(segmentID: selectedID, start: start, end: end)
  }

  private func toggleAudioMute(segmentID: UUID) async throws {
    if let playerItem = try await editUseCase.toggleAudioMute(segmentID: segmentID) {
      playerUseCase.replaceCurrentItem(with: playerItem)
    }
  }

  private func handleTimelineDragStarted() {
    if let tuc = trimmingPlayerUseCase { tuc.pauseAll() }
    else { playerUseCase.pause() }
    isTimelineDragging = true
    startDragOffset = currentTimelineOffset
    lastDragTranslation = 0
  }

  private func handleTimelineDragChanged(translation: CGFloat) {
    let delta = translation - lastDragTranslation
    dragDirection = calculateDragDirection(delta: delta)
    lastDragTranslation = translation

    let newOffset = startDragOffset + translation
    updateTimelineOffset(newOffset, isDragging: true, direction: dragDirection)
  }

  private func handleTimelineDragEnded() {
    isTimelineDragging = false
    lastHapticSecond = -1
    lastDragTranslation = 0

    let clampedOffset = clampTimelineOffset(currentTimelineOffset)
    seekToTimelineOffset(clampedOffset, direction: .none)
  }

  private func handleTimelineScroll(to offset: CGFloat) {
    currentTimelineOffset = clampTimelineOffset(offset)
  }

  private func handlePlayingStateChanged(isPlaying: Bool) {
    guard isPlaying, !isTimelineDragging else { return }

    if trimmingPlayerUseCase != nil,
       let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let relativeSeconds = currentTime.seconds - segment.startTime.seconds
      currentTimelineOffset = -(relativeSeconds * EditConstants.pixelsPerSecond)
    } else {
      let currentSeconds = currentTime.seconds
      currentTimelineOffset = -(currentSeconds * EditConstants.pixelsPerSecond)
    }
  }

  private func handleCurrentTimeChanged() {
    guard !isTimelineDragging else { return }

    checkPlaybackEnd()

    if isTrimming, trimmingHandleType == .right {
      updateOffsetForTrimmingRightHandle()
    } else if isPlaying {
      if trimmingPlayerUseCase != nil,
         let selectedID = selectedSegmentID,
         let segment = segments.first(where: { $0.id == selectedID }) {
        // 절대 시간 → 상대 진행 시간으로 변환
        let relativeSeconds = currentTime.seconds - segment.startTime.seconds
        currentTimelineOffset = -(relativeSeconds * EditConstants.pixelsPerSecond)
      } else {
        currentTimelineOffset = -(currentTime.seconds * EditConstants.pixelsPerSecond)
      }
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

    if let tuc = trimmingPlayerUseCase,
       let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      // newTime은 상대 시간(0 ~ trimmedDuration) → 절대 시간으로 변환
      let absoluteTime = segment.startTime.seconds + newTime
      let seekTime = CMTime(seconds: absoluteTime, preferredTimescale: 600)
      tuc.seekAll(to: seekTime, direction: direction)
    } else {
      let seekTime = CMTime(seconds: newTime, preferredTimescale: 600)
      playerUseCase.seek(to: seekTime, direction: direction)
    }
  }

  private func checkPlaybackEnd() {
    guard isPlaying else { return }

    let currentSeconds = currentTime.seconds
    let threshold = 0.05

    if let selectedID = selectedSegmentID,
       let segment = segments.first(where: { $0.id == selectedID }) {
      let endTime = segment.startTime.seconds + segment.trimmedDuration.seconds
      if abs(currentSeconds - endTime) < threshold || currentSeconds >= endTime {
        if let tuc = trimmingPlayerUseCase { tuc.pauseAll() }
        else { playerUseCase.pause() }
      }
    } else if abs(currentSeconds - totalDuration.seconds) < threshold
                || currentSeconds >= totalDuration.seconds {
      if let tuc = trimmingPlayerUseCase { tuc.pauseAll() }
      else { playerUseCase.pause() }
    }
  }

  private func updateOffsetForTrimmingRightHandle() {
    guard let selectedID = selectedSegmentID,
          let segment = segments.first(where: { $0.id == selectedID }) else { return }

    let visualRightEnd = currentTime.seconds - segment.startTime.seconds
    currentTimelineOffset = -(visualRightEnd * EditConstants.pixelsPerSecond)
  }

  private func handleExport(router: Router) {
    guard let video = getFinalVideoAsset() else { return }
    let composition = getFinalVideoComposition()

    exportUseCase.saveVideo(
      video: video,
      videoComposition: composition
    ) { [weak self] in
      self?.showResultAlert = true
    }
  }

  private func handleAlertDismiss(router: Router) {
    if exportUseCase.alertModel.title == ExportNameSpace.AlertSuccessMessage.title {
      router.popToRoot()
    }
  }
}
