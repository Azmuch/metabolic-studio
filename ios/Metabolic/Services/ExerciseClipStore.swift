import Foundation
import Observation

/// Resolves the best available exercise-demo video clip for an exercise id, in priority order:
///
///   1. **Bundled** — `Metabolic/ExerciseClips/{id}.mp4` shipped in the app (instant, offline).
///   2. **Cached** — a clip previously downloaded to `Caches/ExerciseClips/{id}.mp4`.
///   3. **Remote** — streamed/downloaded per the bundled manifest (`exercise-clips.json`).
///
/// When only a remote clip exists, `clipURL(for:)` kicks off a background download and returns
/// `nil` for now; the hero shows its still/vector fallback until the download lands, then
/// re-resolves (SwiftUI observes `downloadedIDs`). When no clip exists at any tier it returns
/// `nil` and the fallback simply stays — so the app behaves exactly as before until clips ship.
@Observable
final class ExerciseClipStore {
    static let shared = ExerciseClipStore()

    struct Manifest: Decodable {
        struct Entry: Decodable {
            let file: String
            let bytes: Int?
        }
        let version: Int
        let baseUrl: String
        let clips: [String: Entry]
    }

    /// Ids whose clip has just become available in the cache. Reading this inside a view body
    /// registers an observation dependency, so a hero re-resolves once a download completes.
    private(set) var downloadedIDs: Set<String> = []

    private let manifest: Manifest?
    private let cacheDir: URL
    private var inFlight: Set<String> = []

    private init() {
        manifest = Self.loadBundledManifest()
        cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExerciseClips", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        // Seed from whatever is already cached on disk from previous runs.
        if let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil) {
            downloadedIDs = Set(
                files.filter { $0.pathExtension == "mp4" }
                    .map { $0.deletingPathExtension().lastPathComponent })
        }
    }

    // MARK: - Resolution

    /// Best local URL for an exercise, or `nil`. Kicks off a background download when only a
    /// remote clip is available.
    func clipURL(for exerciseID: String) -> URL? {
        if let bundled = bundledURL(for: exerciseID) { return bundled }
        // Touch `downloadedIDs` so the caller re-evaluates when a download completes.
        if downloadedIDs.contains(exerciseID), let cached = cachedURL(for: exerciseID) {
            return cached
        }
        if manifest?.clips[exerciseID] != nil {
            startDownload(exerciseID)
        }
        return nil
    }

    func hasClip(for exerciseID: String) -> Bool {
        clipURL(for: exerciseID) != nil
    }

    /// Ids the manifest knows about (used for a "Download all for offline" action).
    var remoteClipIDs: [String] {
        manifest.map { Array($0.clips.keys) } ?? []
    }

    /// Force a clip to be fetched now.
    func download(_ exerciseID: String) {
        startDownload(exerciseID)
    }

    // MARK: - Local lookups

    private func bundledURL(for id: String) -> URL? {
        // Cover both flattened and folder-preserving bundling of the synchronized group.
        Bundle.main.url(forResource: id, withExtension: "mp4", subdirectory: "ExerciseClips")
            ?? Bundle.main.url(forResource: id, withExtension: "mp4")
    }

    private func cachedURL(for id: String) -> URL? {
        let url = cacheDir.appendingPathComponent("\(id).mp4")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Download

    private func startDownload(_ id: String) {
        guard let manifest, let entry = manifest.clips[id] else { return }
        guard !inFlight.contains(id), cachedURL(for: id) == nil else { return }
        guard let base = URL(string: manifest.baseUrl), !manifest.baseUrl.isEmpty else { return }
        let remote = base.appendingPathComponent(entry.file)
        let dest = cacheDir.appendingPathComponent("\(id).mp4")
        inFlight.insert(id)
        Task {
            do {
                let (tmp, _) = try await URLSession.shared.download(from: remote)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: tmp, to: dest)
                await MainActor.run {
                    self.downloadedIDs.insert(id)
                    self.inFlight.remove(id)
                }
            } catch {
                await MainActor.run { self.inFlight.remove(id) }
            }
        }
    }

    private static func loadBundledManifest() -> Manifest? {
        let url = Bundle.main.url(forResource: "exercise-clips", withExtension: "json",
                                  subdirectory: "ExerciseClips")
            ?? Bundle.main.url(forResource: "exercise-clips", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Manifest.self, from: data)
    }
}
