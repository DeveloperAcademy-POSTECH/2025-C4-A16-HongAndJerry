import AVKit

extension VideoSegment: Hashable {
  public static func == (lhs: VideoSegment, rhs: VideoSegment) -> Bool {
    return lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
