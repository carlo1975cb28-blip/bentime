import Foundation

/// Represents a single subtitle entry with timing and text content.
struct SubtitleEntry: Identifiable, Equatable {
    let id: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String

    /// Returns true if this subtitle should be displayed at the given time.
    func isActive(at time: TimeInterval) -> Bool {
        return time >= startTime && time <= endTime
    }
}

/// Represents a complete subtitle track containing ordered entries.
struct SubtitleTrack: Identifiable {
    let id: String
    let name: String
    let entries: [SubtitleEntry]
    let source: SubtitleSource

    /// Returns the subtitle entry active at the given time, if any.
    func activeEntry(at time: TimeInterval) -> SubtitleEntry? {
        return entries.first { $0.isActive(at: time) }
    }
}

/// Indicates where a subtitle track originated from.
enum SubtitleSource: Equatable {
    case external(url: URL)
    case embedded(trackIndex: Int)
}
