import Foundation
import os

struct LocalPersistenceStore {
    private static let logger = Logger(subsystem: "com.orilo.app", category: "persistence")

    private let fileManager: FileManager
    private let baseURL: URL
    private let recapsURL: URL
    private let preferencesURL: URL
    private let activeSessionURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default, baseURL: URL? = nil) {
        self.fileManager = fileManager

        if let baseURL {
            self.baseURL = baseURL
        } else {
            let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.homeDirectoryForCurrentUser.appending(path: "Library/Application Support")
            self.baseURL = supportURL.appending(path: "Orilo", directoryHint: .isDirectory)
        }

        recapsURL = self.baseURL.appending(path: "SessionRecaps.json")
        preferencesURL = self.baseURL.appending(path: "AppPreferences.json")
        activeSessionURL = self.baseURL.appending(path: "ActiveSession.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadRecaps() -> [SessionRecap] {
        guard let data = try? Data(contentsOf: recapsURL) else {
            return []
        }

        return (try? decoder.decode([SessionRecap].self, from: data)) ?? []
    }

    func saveRecaps(_ recaps: [SessionRecap]) {
        save(recaps, to: recapsURL)
    }

    func deleteAllRecaps() {
        do {
            if fileManager.fileExists(atPath: recapsURL.path) {
                try fileManager.removeItem(at: recapsURL)
            }
        } catch {
            Self.logger.error("Failed to delete all recaps: \(error.localizedDescription)")
        }
    }

    func deleteRecap(id: UUID) {
        var recaps = loadRecaps()
        recaps.removeAll { $0.id == id }
        saveRecaps(recaps)
    }

    func loadPreferences() -> AppPreferences {
        guard let data = try? Data(contentsOf: preferencesURL) else {
            return .defaults
        }

        return (try? decoder.decode(AppPreferences.self, from: data)) ?? .defaults
    }

    func savePreferences(_ preferences: AppPreferences) {
        save(preferences, to: preferencesURL)
    }

    func loadActiveSessionRecord() -> ActiveSessionRecord? {
        guard let data = try? Data(contentsOf: activeSessionURL) else {
            return nil
        }

        return try? decoder.decode(ActiveSessionRecord.self, from: data)
    }

    func saveActiveSessionRecord(_ record: ActiveSessionRecord) {
        save(record, to: activeSessionURL)
    }

    func clearActiveSessionRecord() {
        do {
            if fileManager.fileExists(atPath: activeSessionURL.path) {
                try fileManager.removeItem(at: activeSessionURL)
            }
        } catch {
            Self.logger.error("Failed to clear active session: \(error.localizedDescription)")
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            Self.logger.error("Failed to persist Orilo data: \(error.localizedDescription)")
        }
    }
}
