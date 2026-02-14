import AVKit
import Observation

@Observable
@MainActor
final class TrimmingPlayerUseCase {

  struct SegmentPlayer {
    let segmentID: UUID
    let player: AVPlayer
    let segment: VideoSegment
    let transformedSize: CGSize
    let preferredTransform: CGAffineTransform
    let naturalSize: CGSize
  }

  private(set) var segmentPlayers: [SegmentPlayer] = []
  private(set) var selectedSegmentID: UUID?
  private var timeObserverToken: Any?

  var isPlaying: Bool = false
  var currentTime: CMTime = .zero
  var totalDuration: CMTime = .zero

  init() {}

  func setup(segments: [VideoSegment], selectedID: UUID) async {
    cleanup()
    selectedSegmentID = selectedID

    var players: [SegmentPlayer] = []

    for segment in segments {
      let playerItem = AVPlayerItem(asset: segment.source.asset)
      let endTime = CMTimeAdd(segment.startTime, segment.trimmedDuration)
      playerItem.forwardPlaybackEndTime = endTime

      let player = AVPlayer(playerItem: playerItem)
      player.isMuted = segment.isMuted

      var preferredTransform: CGAffineTransform = .identity
      var naturalSize: CGSize = .zero

      if let videoTrack = try? await segment.source.asset.loadTracks(
        withMediaType: .video
      ).first {
        preferredTransform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
        naturalSize = (try? await videoTrack.load(.naturalSize)) ?? .zero
      }

      let transformedSize = CGSize(
        width: abs(naturalSize.applying(preferredTransform).width),
        height: abs(naturalSize.applying(preferredTransform).height)
      )

      players.append(SegmentPlayer(
        segmentID: segment.id,
        player: player,
        segment: segment,
        transformedSize: transformedSize,
        preferredTransform: preferredTransform,
        naturalSize: naturalSize
      ))
    }

    segmentPlayers = players

    for sp in segmentPlayers {
      await sp.player.seek(
        to: sp.segment.startTime,
        toleranceBefore: .zero,
        toleranceAfter: .zero
      )
      sp.player.rate = 0
    }

    if let selected = segmentPlayers.first(where: { $0.segmentID == selectedID }) {
      totalDuration = selected.segment.trimmedDuration
      currentTime = selected.segment.startTime
    }

    addTimeObserver()
  }

  func seekSelected(to time: CMTime, direction: DragDirection = .none) {
    guard let sp = segmentPlayers.first(where: { $0.segmentID == selectedSegmentID }) else {
      return
    }

    let tolerance = (direction == .backward)
      ? CMTime(seconds: 0.5, preferredTimescale: 600)
      : .zero

    sp.player.seek(
      to: time,
      toleranceBefore: tolerance,
      toleranceAfter: tolerance
    )

    currentTime = time
  }

  func seekAll(to time: CMTime, direction: DragDirection = .none) {
    let tolerance = (direction == .backward)
      ? CMTime(seconds: 0.5, preferredTimescale: 600)
      : .zero

    guard let selected = segmentPlayers.first(where: { $0.segmentID == selectedSegmentID }) else {
      return
    }

    let elapsed = time.seconds - selected.segment.startTime.seconds

    for sp in segmentPlayers {
      let seg = sp.segment
      let targetSeconds = seg.startTime.seconds + elapsed
      let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
      let clampedTime = CMTimeClampToRange(
        targetTime,
        start: seg.startTime,
        end: CMTimeAdd(seg.startTime, seg.trimmedDuration)
      )

      sp.player.seek(
        to: clampedTime,
        toleranceBefore: tolerance,
        toleranceAfter: tolerance
      )
    }

    currentTime = time
  }

  func playAll() {
    for sp in segmentPlayers {
      sp.player.rate = 1
    }
    isPlaying = true
  }

  func pauseAll() {
    for sp in segmentPlayers {
      sp.player.rate = 0
    }
    isPlaying = false
  }

  func updateSelectedSegment(newID: UUID) {
    removeTimeObserver()
    selectedSegmentID = newID

    if let selected = segmentPlayers.first(where: { $0.segmentID == newID }) {
      totalDuration = selected.segment.trimmedDuration
      currentTime = selected.player.currentTime()
    }

    addTimeObserver()
  }

  func cleanup() {
    pauseAll()
    removeTimeObserver()

    for sp in segmentPlayers {
      sp.player.replaceCurrentItem(with: nil)
    }

    segmentPlayers = []
    selectedSegmentID = nil
    currentTime = .zero
    totalDuration = .zero
    isPlaying = false
  }

  private func addTimeObserver() {
    removeTimeObserver()

    guard let selectedPlayer = segmentPlayers.first(
      where: { $0.segmentID == selectedSegmentID }
    )?.player else { return }

    timeObserverToken = selectedPlayer.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 60),
      queue: .main
    ) { [weak self] time in
      Task { @MainActor in
        guard let self else { return }
        self.currentTime = time
      }
    }
  }

  private func removeTimeObserver() {
    guard let token = timeObserverToken,
          let selectedPlayer = segmentPlayers.first(
            where: { $0.segmentID == selectedSegmentID }
          )?.player else {
      timeObserverToken = nil
      return
    }

    selectedPlayer.removeTimeObserver(token)
    timeObserverToken = nil
  }
}

private func CMTimeClampToRange(
  _ time: CMTime,
  start: CMTime,
  end: CMTime
) -> CMTime {
  if time < start { return start }
  if time > end { return end }
  return time
}
