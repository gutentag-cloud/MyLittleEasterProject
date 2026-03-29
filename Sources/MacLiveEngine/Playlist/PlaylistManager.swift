import Foundation
import Combine

/// Manages a playlist of wallpapers with automatic advancement.
final class PlaylistManager: ObservableObject {
    
    @Published var currentURL: URL?
    @Published var currentIndex: Int = -1
    @Published var items: [URL] = []
    
    private let configuration: Configuration
    private var timer: Timer?
    private var shuffledIndices: [Int] = []
    private var shufflePosition: Int = 0
    
    init(configuration: Configuration) {
        self.configuration = configuration
        self.items = configuration.playlistURLs
        if !items.isEmpty {
            reshuffleIfNeeded()
        }
    }
    
    func start() {
        guard !items.isEmpty else { return }
        
        if currentIndex < 0 {
            advanceToIndex(0)
        }
        
        startTimer()
        Logger.shared.info("Playlist started with \(items.count) items, interval: \(configuration.playlistInterval)s")
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func next() {
        guard !items.isEmpty else { return }
        if configuration.playlistShuffle {
            shufflePosition = (shufflePosition + 1) % shuffledIndices.count
            advanceToIndex(shuffledIndices[shufflePosition])
        } else {
            advanceToIndex((currentIndex + 1) % items.count)
        }
    }
    
    func previous() {
        guard !items.isEmpty else { return }
        if configuration.playlistShuffle {
            shufflePosition = shufflePosition > 0 ? shufflePosition - 1 : shuffledIndices.count - 1
            advanceToIndex(shuffledIndices[shufflePosition])
        } else {
            advanceToIndex(currentIndex > 0 ? currentIndex - 1 : items.count - 1)
        }
    }
    
    func add(_ url: URL) {
        if url.hasDirectoryPath {
            let fm = FileManager.default
            let supportedExtensions = ["mp4", "mov", "m4v", "mkv", "webm", "html", "htm",
                                        "png", "jpg", "jpeg", "gif", "heic", "metal", "qtz"]
            if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                        items.append(fileURL)
                    }
                }
            }
        } else {
            items.append(url)
        }
        configuration.playlistURLs = items
        configuration.save()
        reshuffleIfNeeded()
        Logger.shared.info("Added to playlist: \(url.lastPathComponent) (\(items.count) total)")
    }
    
    func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        configuration.playlistURLs = items
        configuration.save()
        reshuffleIfNeeded()
    }
    
    func clear() {
        items.removeAll()
        configuration.playlistURLs = []
        configuration.save()
        currentIndex = -1
        currentURL = nil
        stop()
    }
    
    func updateInterval(_ interval: TimeInterval) {
        startTimer()
    }
    
    // MARK: - Private
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: configuration.playlistInterval, repeats: true) { [weak self] _ in
            self?.next()
        }
    }
    
    private func advanceToIndex(_ index: Int) {
        guard items.indices.contains(index) else { return }
        currentIndex = index
        currentURL = items[index]
    }
    
    private func reshuffleIfNeeded() {
        if configuration.playlistShuffle {
            shuffledIndices = Array(items.indices).shuffled()
            shufflePosition = 0
        }
    }
}
