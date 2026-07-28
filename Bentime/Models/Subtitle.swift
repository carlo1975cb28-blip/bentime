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
    /// Uses binary search for O(log n) performance on large subtitle files.
    func activeEntry(at time: TimeInterval) -> SubtitleEntry? {
        guard !entries.isEmpty else { return nil }

        // Binary search for the last entry whose startTime <= time
        var low = 0
        var high = entries.count - 1
        var candidateIndex = -1

        while low <= high {
            let mid = (low + high) / 2
            if entries[mid].startTime <= time {
                candidateIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // Check if the candidate entry is active (time is within its range)
        guard candidateIndex >= 0 else { return nil }

        // Scan forward from candidateIndex in case multiple entries overlap
        // (unusual but possible with some subtitle formats)
        var index = candidateIndex
        while index >= 0 && entries[index].startTime <= time {
            if entries[index].isActive(at: time) {
                return entries[index]
            }
            index -= 1
        }

        // Also check the entry at candidateIndex directly
        if entries[candidateIndex].isActive(at: time) {
            return entries[candidateIndex]
        }

        return nil
    }
}

/// Indicates where a subtitle track originated from.
enum SubtitleSource: Equatable {
    case external(url: URL)
    case embedded(trackIndex: Int)
}
