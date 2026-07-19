import Foundation

struct DataExportService {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func exportToCSV(_ recaps: [SessionRecap]) -> URL? {
        var csv = "Date,Intention,Planned Duration (min),Focused Duration (min),Reflection\n"

        for recap in recaps {
            let date = dateFormatter.string(from: recap.startedAt)
            let intention = escapeCSV(recap.intention)
            let planned = String(format: "%.1f", recap.plannedDuration / 60)
            let focused = String(format: "%.1f", recap.focusedDuration / 60)
            let reflection = escapeCSV(recap.reflection ?? "")

            csv += "\(date),\(intention),\(planned),\(focused),\(reflection)\n"
        }

        return writeToTempFile(content: csv, filename: "orilo_sessions.csv")
    }

    func exportToJSON(_ recaps: [SessionRecap]) -> URL? {
        do {
            let data = try encoder.encode(recaps)
            return writeToTempFile(data: data, filename: "orilo_sessions.json")
        } catch {
            return nil
        }
    }

    private func escapeCSV(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    private func writeToTempFile(content: String, filename: String) -> URL? {
        guard let data = content.data(using: .utf8) else { return nil }
        return writeToTempFile(data: data, filename: filename)
    }

    private func writeToTempFile(data: Data, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }
}
