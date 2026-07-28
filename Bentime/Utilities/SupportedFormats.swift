import Foundation

/// Constants defining supported file formats for Bentime.
struct SupportedFormats {

    /// Supported video file extensions.
    static let videoExtensions: Set<String> = [
        "mp4",
        "mkv",
        "avi",
        "mov",
        "wmv",
        "flv",
        "webm",
        "m4v",
        "mpg",
        "mpeg",
        "ts",
        "vob",
        "3gp",
        "ogv"
    ]

    /// Supported subtitle file extensions.
    static let subtitleExtensions: Set<String> = [
        "srt",
        "ass",
        "ssa"
    ]

    /// All supported extensions combined.
    static let allExtensions: Set<String> = videoExtensions.union(subtitleExtensions)

    /// Checks if a given file extension corresponds to a supported video format.
    /// - Parameter ext: The file extension (without the dot).
    /// - Returns: True if the extension is a supported video format.
    static func isVideoFile(_ ext: String) -> Bool {
        return videoExtensions.contains(ext.lowercased())
    }

    /// Checks if a given file extension corresponds to a supported subtitle format.
    /// - Parameter ext: The file extension (without the dot).
    /// - Returns: True if the extension is a supported subtitle format.
    static func isSubtitleFile(_ ext: String) -> Bool {
        return subtitleExtensions.contains(ext.lowercased())
    }

    /// Checks if a URL points to a supported video file.
    /// - Parameter url: The file URL to check.
    /// - Returns: True if the file is a supported video format.
    static func isVideoURL(_ url: URL) -> Bool {
        return isVideoFile(url.pathExtension)
    }

    /// Checks if a URL points to a supported subtitle file.
    /// - Parameter url: The file URL to check.
    /// - Returns: True if the file is a supported subtitle format.
    static func isSubtitleURL(_ url: URL) -> Bool {
        return isSubtitleFile(url.pathExtension)
    }
}
