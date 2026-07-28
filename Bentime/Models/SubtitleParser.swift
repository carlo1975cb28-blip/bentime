import Foundation

/// Parser for external subtitle files supporting .srt and .ass/.ssa formats.
struct SubtitleParser {

    // MARK: - Public API

    /// Parses a subtitle file at the given URL and returns a SubtitleTrack.
    /// Detects format based on file extension.
    static func parse(url: URL) throws -> SubtitleTrack {
        let content = try String(contentsOf: url, encoding: .utf8)
        let ext = url.pathExtension.lowercased()
        let name = url.deletingPathExtension().lastPathComponent

        let entries: [SubtitleEntry]

        switch ext {
        case "srt":
            entries = parseSRT(content: content)
        case "ass", "ssa":
            entries = parseASS(content: content)
        default:
            throw SubtitleParserError.unsupportedFormat(ext)
        }

        return SubtitleTrack(
            id: url.absoluteString,
            name: name,
            entries: entries,
            source: .external(url: url)
        )
    }

    // MARK: - SRT Parsing

    /// Parses SubRip (.srt) formatted subtitle content.
    ///
    /// Format:
    /// ```
    /// 1
    /// 00:01:20,000 --> 00:01:24,000
    /// Subtitle text line 1
    /// Subtitle text line 2
    ///
    /// 2
    /// ...
    /// ```
    static func parseSRT(content: String) -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        let blocks = content.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)

            guard lines.count >= 3 else { continue }

            // First line is the sequence number
            guard let index = Int(lines[0].trimmingCharacters(in: .whitespaces)) else { continue }

            // Second line is the timing
            let timingLine = lines[1]
            guard let (startTime, endTime) = parseSRTTimeline(timingLine) else { continue }

            // Remaining lines are the subtitle text
            let textLines = lines[2...]
            let text = textLines.joined(separator: "\n")
            let cleanedText = stripHTMLTags(from: text)

            let entry = SubtitleEntry(
                id: index,
                startTime: startTime,
                endTime: endTime,
                text: cleanedText
            )
            entries.append(entry)
        }

        return entries
    }

    /// Parses an SRT timeline string like "00:01:20,000 --> 00:01:24,000"
    private static func parseSRTTimeline(_ line: String) -> (TimeInterval, TimeInterval)? {
        let parts = line.components(separatedBy: " --> ")
        guard parts.count == 2 else { return nil }

        guard let start = parseSRTTimestamp(parts[0].trimmingCharacters(in: .whitespaces)),
              let end = parseSRTTimestamp(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        return (start, end)
    }

    /// Parses an SRT timestamp like "00:01:20,000" into seconds.
    private static func parseSRTTimestamp(_ timestamp: String) -> TimeInterval? {
        // Format: HH:MM:SS,mmm
        let cleaned = timestamp.replacingOccurrences(of: ",", with: ".")
        let components = cleaned.components(separatedBy: ":")
        guard components.count == 3 else { return nil }

        guard let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            return nil
        }

        return hours * 3600 + minutes * 60 + seconds
    }

    // MARK: - ASS/SSA Parsing

    /// Parses Advanced SubStation Alpha (.ass) or SubStation Alpha (.ssa) formatted content.
    ///
    /// Looks for the [Events] section and parses Dialogue lines.
    /// Format line defines column order, Dialogue lines contain the data.
    static func parseASS(content: String) -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        let lines = content.components(separatedBy: .newlines)

        var inEventsSection = false
        var formatColumns: [String] = []
        var entryIndex = 1

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect section headers
            if trimmed.hasPrefix("[") {
                inEventsSection = trimmed.lowercased().hasPrefix("[events]")
                continue
            }

            guard inEventsSection else { continue }

            // Parse Format line to determine column order
            if trimmed.lowercased().hasPrefix("format:") {
                let columnsString = String(trimmed.dropFirst("format:".count))
                formatColumns = columnsString.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                continue
            }

            // Parse Dialogue lines
            if trimmed.lowercased().hasPrefix("dialogue:") {
                let dataString = String(trimmed.dropFirst("dialogue:".count))
                    .trimmingCharacters(in: .whitespaces)

                guard let entry = parseASSDialogue(
                    data: dataString,
                    formatColumns: formatColumns,
                    index: entryIndex
                ) else { continue }

                entries.append(entry)
                entryIndex += 1
            }
        }

        return entries
    }

    /// Parses a single ASS Dialogue line into a SubtitleEntry.
    private static func parseASSDialogue(
        data: String,
        formatColumns: [String],
        index: Int
    ) -> SubtitleEntry? {
        // ASS format: fields are comma-separated, but the Text field (last) may contain commas
        let fieldCount = formatColumns.count
        guard fieldCount > 0 else { return nil }

        var fields: [String] = []
        var remaining = data

        // Split by comma, but the last field gets all remaining text
        for i in 0..<(fieldCount - 1) {
            guard let commaRange = remaining.range(of: ",") else {
                // Not enough fields
                return nil
            }
            let field = String(remaining[remaining.startIndex..<commaRange.lowerBound])
            fields.append(field.trimmingCharacters(in: .whitespaces))
            remaining = String(remaining[commaRange.upperBound...])
            _ = i // suppress unused variable warning
        }
        // Last field is everything remaining
        fields.append(remaining.trimmingCharacters(in: .whitespaces))

        // Find start, end, and text columns
        guard let startIndex = formatColumns.firstIndex(of: "start"),
              let endIndex = formatColumns.firstIndex(of: "end"),
              let textIndex = formatColumns.firstIndex(of: "text") else {
            return nil
        }

        guard startIndex < fields.count,
              endIndex < fields.count,
              textIndex < fields.count else {
            return nil
        }

        guard let startTime = parseASSTimestamp(fields[startIndex]),
              let endTime = parseASSTimestamp(fields[endIndex]) else {
            return nil
        }

        let rawText = fields[textIndex]
        let cleanedText = stripASSStyleTags(from: rawText)
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")

        return SubtitleEntry(
            id: index,
            startTime: startTime,
            endTime: endTime,
            text: cleanedText
        )
    }

    /// Parses an ASS timestamp like "0:01:20.00" into seconds.
    private static func parseASSTimestamp(_ timestamp: String) -> TimeInterval? {
        // Format: H:MM:SS.cc (centiseconds)
        let components = timestamp.components(separatedBy: ":")
        guard components.count == 3 else { return nil }

        guard let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            return nil
        }

        return hours * 3600 + minutes * 60 + seconds
    }

    // MARK: - Text Cleaning

    /// Removes HTML tags from subtitle text (common in .srt files).
    private static func stripHTMLTags(from text: String) -> String {
        // Remove common HTML tags: <b>, </b>, <i>, </i>, <u>, </u>, <font...>, </font>
        var result = text
        let pattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes ASS/SSA style override tags like {\b1}, {\an8}, etc.
    private static func stripASSStyleTags(from text: String) -> String {
        var result = text
        let pattern = "\\{[^}]*\\}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum SubtitleParserError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileReadError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported subtitle format: .\(ext)"
        case .fileReadError(let message):
            return "Failed to read subtitle file: \(message)"
        }
    }
}
