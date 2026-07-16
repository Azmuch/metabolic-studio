import Foundation
import Observation

/// How a resolved clip should be played back, per the bundled manifest's `type`:
///   - `.loop`  — seamless loop (a rep whose motion returns to its start, or a boomerang-baked clip).
///   - `.hold`  — play the entry once and freeze on the last frame (the held position) for the full
///     isometric countdown; no exit animation is needed since the UI moves to the Rest screen.
enum ClipPlayback: Equatable {
    case loop
    case hold
}

/// Resolves the best available exercise-demo video clip for an exercise id, honoring the user's
/// chosen visual **style** ("skin pack"), in priority order:
///
///   1. **Styled, bundled** — `Metabolic/ExerciseClips/{id}.{style}.mp4`.
///   2. **Anatomy, bundled** — `Metabolic/ExerciseClips/{id}.mp4` (the shipped écorché pack, which
///      carries no style suffix). A pack therefore only needs to supply the exercises it restyles;
///      anything it omits falls back to the anatomy clip rather than to nothing.
///   3. **Styled / anatomy, cached** — the same two, previously downloaded to `Caches/ExerciseClips`.
///   4. **Remote** — streamed/downloaded per the bundled manifest (`exercise-clips.json`), styled
///      key first, then the anatomy key. Returns `nil` for now and downloads in the background; the
///      hero shows its still/vector fallback until the clip lands, then re-resolves.
///
/// When no clip exists at any tier it returns `nil` and the still/vector fallback simply stays.
@Observable
final class ExerciseClipStore {
    static let shared = ExerciseClipStore()

    struct Manifest: Decodable {
        struct Entry: Decodable {
            let file: String
            let bytes: Int?
            /// `"hold"` for isometric clips (entry-into-hold), `"rep"`/absent for looping motion.
            let type: String?
        }
        let version: Int
        let baseUrl: String
        /// Keyed by clip *stem*: `"squat"` for the anatomy pack, `"squat.realistic"` for a style.
        let clips: [String: Entry]
    }

    /// The active skin pack. Set from `AppState.clipStyle`; reading it inside a view body registers
    /// an observation dependency, so heroes re-resolve live when the user switches packs.
    var style: ClipStyle = .ecorche

    /// Clip stems whose file has just become available in the cache (drives re-resolution after a
    /// download completes). Stems are `"{id}"` or `"{id}.{token}"`.
    private(set) var downloadedStems: Set<String> = []

    /// On-Demand Resource tags whose Apple-hosted asset pack is downloaded and accessible.
    /// Observed by heroes so pack clips appear the moment the ODR download lands.
    private(set) var odrLoadedTags: Set<String> = []

    private let manifest: Manifest?
    private let cacheDir: URL
    private var inFlight: Set<String> = []
    /// Live requests, kept for the app's lifetime so accessed ODR resources stay available.
    private var odrRequests: [String: NSBundleResourceRequest] = [:]

    private init() {
        manifest = Self.loadBundledManifest()
        cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExerciseClips", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        if let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil) {
            downloadedStems = Set(
                files.filter { $0.pathExtension == "mp4" }
                    .map { $0.deletingPathExtension().lastPathComponent })
        }
    }

    // MARK: - Resolution

    /// Best local clip URL for an exercise under the active style, or `nil`. Expansion-pack
    /// exercises resolve only when their pack is purchased (their clips arrive via ODR after
    /// unlock). Kicks off a background download when only a remote clip is available.
    /// Main-actor: consults `PackStore`'s purchase state (a MainActor store), and is only ever
    /// called from view bodies, which are MainActor.
    @MainActor
    func clipURL(for exerciseID: String) -> URL? {
        // Expansion gate: locked pack content never resolves; owned-but-not-downloaded content
        // triggers the ODR fetch and resolves once `odrLoadedTags` updates (observed).
        if let pack = ExpansionPack.pack(containing: exerciseID) {
            guard PackStore.shared.purchasedPackIDs.contains(pack.id) else { return nil }
            if !odrLoadedTags.contains(pack.odrTag) {
                beginODRAccess(tag: pack.odrTag)
            }
        }

        let style = self.style   // observed — re-resolves when the pack changes
        // Styled token first (if any), then the unstyled anatomy fallback.
        let tokens: [String?] = style.filenameToken.map { [$0, nil] } ?? [nil]

        for token in tokens {
            if let url = bundledURL(stem: stem(exerciseID, token)) { return url }
        }
        for token in tokens {
            let s = stem(exerciseID, token)
            // Touch `downloadedStems` so the caller re-evaluates when a download lands.
            if downloadedStems.contains(s), let url = cachedURL(stem: s) { return url }
        }
        for token in tokens {
            let s = stem(exerciseID, token)
            if manifest?.clips[s] != nil { startDownload(s); break }
        }
        return nil
    }

    // MARK: - On-Demand Resources (Apple-hosted expansion packs)

    /// Requests an ODR asset pack by tag. Uses `conditionallyBeginAccessingResources` first (free
    /// if already on device), else downloads from Apple's hosting. Once access succeeds, the tag's
    /// files resolve through the normal `Bundle.main` lookups and `odrLoadedTags` notifies heroes.
    /// Safe to call when the tag has no assets yet (clips not shipped) — the request simply fails
    /// and the still/vector fallback stays.
    func beginODRAccess(tag: String) {
        guard odrRequests[tag] == nil else { return }
        let request = NSBundleResourceRequest(tags: [tag])
        request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
        odrRequests[tag] = request
        request.conditionallyBeginAccessingResources { [weak self] available in
            if available {
                Task { @MainActor in self?.odrLoadedTags.insert(tag) }
            } else {
                request.beginAccessingResources { error in
                    Task { @MainActor in
                        if error == nil {
                            self?.odrLoadedTags.insert(tag)
                        } else {
                            self?.odrRequests[tag] = nil   // allow retry later
                        }
                    }
                }
            }
        }
    }

    @MainActor
    func hasClip(for exerciseID: String) -> Bool {
        clipURL(for: exerciseID) != nil
    }

    /// Playback mode for an exercise's clip. Motion is defined by the anatomy clip, so a skin pack
    /// only restyles the look — the `type` is keyed by the bare exercise id. Unknown/absent ⇒ loop.
    func playback(for exerciseID: String) -> ClipPlayback {
        manifest?.clips[exerciseID]?.type == "hold" ? .hold : .loop
    }

    /// Force the current style's clip for an exercise to be fetched now (e.g. "Download for offline").
    func download(_ exerciseID: String) {
        startDownload(stem(exerciseID, style.filenameToken))
    }

    // MARK: - Naming helpers

    /// `"squat"` for the anatomy pack (nil token), `"squat.realistic"` for a style token.
    private func stem(_ id: String, _ token: String?) -> String {
        token.map { "\(id).\($0)" } ?? id
    }

    private func bundledURL(stem: String) -> URL? {
        // Cover both flattened and folder-preserving bundling of the synchronized group.
        Bundle.main.url(forResource: stem, withExtension: "mp4", subdirectory: "ExerciseClips")
            ?? Bundle.main.url(forResource: stem, withExtension: "mp4")
    }

    private func cachedURL(stem: String) -> URL? {
        let url = cacheDir.appendingPathComponent("\(stem).mp4")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Download

    private func startDownload(_ stem: String) {
        guard let manifest, let entry = manifest.clips[stem] else { return }
        guard !inFlight.contains(stem), cachedURL(stem: stem) == nil else { return }
        guard let base = URL(string: manifest.baseUrl), !manifest.baseUrl.isEmpty else { return }
        let remote = base.appendingPathComponent(entry.file)
        let dest = cacheDir.appendingPathComponent("\(stem).mp4")
        inFlight.insert(stem)
        Task {
            do {
                let (tmp, _) = try await URLSession.shared.download(from: remote)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: tmp, to: dest)
                await MainActor.run {
                    self.downloadedStems.insert(stem)
                    self.inFlight.remove(stem)
                }
            } catch {
                await MainActor.run { self.inFlight.remove(stem) }
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
