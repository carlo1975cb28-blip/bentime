import Foundation

/// Utility for formatting time intervals into human-readable strings.
struct TimeFormatter {

    /// Formats a time interval (in seconds) into "HH:MM:SS" format.
    /// - Parameter seconds: The time interval in seconds.
    /// - Returns: A formatted string like "01:23:45".
    static func format(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else {
            return "00:00:00"
        }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    /// Formats a time interval into a short format.
    /// Uses "MM:SS" when duration is under one hour, otherwise "HH:MM:SS".
    /// - Parameters:
    ///   - seconds: The time interval in seconds.
    ///   - totalDuration: The total duration for context (determines format).
    /// - Returns: A formatted time string.
    static func formatShort(_ seconds: TimeInterval, totalDuration: TimeInterval = 0) -> String {
        guard seconds.isFinite && seconds >= 0 else {
            return totalDuration >= 3600 ? "00:00:00" : "00:00"
        }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if totalDuration >= 3600 || hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
