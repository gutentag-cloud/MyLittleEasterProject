import AppKit
import Combine
import UniformTypeIdentifiers

/// The overall engine state.
enum EngineState {
    case running, paused, stopped
}

/// The central coordinator — owns windows, renderers, and subsystems.
final class Engine: ObservableObject {
    
    @Published var state: EngineState = .stopped
    
    let configuration: Configuration
    let performanceMonitor = PerformanceMonitor()
    let audioEngine = AudioEngine()
    let playlistManager: PlaylistManager
    let scheduler: Scheduler
    private let batteryMonitor = BatteryMonitor()
    private let transitionEngine = TransitionEngine()
    
    /// One `WallpaperWindow` per active display.
    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    
    /// The active renderer for each display.
    private var renderers: [CGDirectDisplayID: any WallpaperRenderer] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private var fullscreenCheckTimer: Timer?
    
    var supportedContentTypes: [UTType] {
        [.movie, .video, .mpeg4Movie, .quickTimeMovie, .avi,
         .html, .webArchive, .png, .jpeg, .gif, .tiff, .heic,
         UTType("com.apple.quartz-composer-composition") ?? .data,
         UTType(filenameExtension: "metal") ?? .data]
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
        self.playlistManager = PlaylistManager(configuration: configuration)
        self.scheduler = Scheduler(configuration: configuration)
        
        // React to battery state
        batteryMonitor.$isOnBattery
            .removeDuplicates()
            .sink { [weak self] onBattery in
                guard let self, self.configuration.pauseOnBattery else { return }
                if onBattery {
                    Logger.shared.info("On battery — reducing FPS")
                    self.setTargetFPS(self.configuration.reducedFPSOnBattery)
                } else {
                    Logger.shared.info("On AC — restoring FPS")
                    self.setTargetFPS(self.configuration.targetFPS)
                }
            }
            .store(in: &cancellables)
        
        // React to playlist changes
        playlistManager.$currentURL
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] url in
                self?.loadWallpaper(from: url)
            }
            .store(in: &cancellables)
        
        // React to scheduler
        scheduler.$activeWallpaperURL
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] url in
                self?.loadWallpaper(from: url)
            }
            .store(in: &cancellables)
        
        // Forward audio data to renderers
        audioEngine.$spectrum
            .sink { [weak self] spectrum in
                guard let self else { return }
                for renderer in self.renderers.values {
                    renderer.receiveAudioSpectrum(spectrum)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Lifecycle
    
    func start() {
        guard state != .running else { return }
        
        createWindowsForActiveDisplays()
        
        // Create initial renderer from config
        if let url = configuration.wallpaperURL {
            loadWallpaper(from: url)
        } else {
            setWallpaperType(configuration.wallpaperType)
        }
        
        performanceMonitor.start()
        
        if configuration.audioReactive {
            audioEngine.start()
        }
        
        if configuration.playlistEnabled {
            playlistManager.start()
        }
        
        if configuration.schedulerEnabled {
            scheduler.start()
        }
        
        startFullscreenDetection()
        batteryMonitor.start()
        
        state = .running
    }
    
    func pause() {
        guard state == .running else { return }
        for renderer in renderers.values { renderer.pause() }
        performanceMonitor.pause()
        state = .paused
        Logger.shared.info("Engine paused")
    }
    
    func resume() {
        guard state == .paused else { return }
        for renderer in renderers.values { renderer.resume() }
        performanceMonitor.resume()
        state = .running
        Logger.shared.info("Engine resumed")
    }
    
    func shutdown() {
        state = .stopped
        for renderer in renderers.values { renderer.stop() }
        renderers.removeAll()
        for window in windows.values { window.close() }
        windows.removeAll()
        performanceMonitor.stop()
        audioEngine.stop()
        playlistManager.stop()
        scheduler.stop()
        fullscreenCheckTimer?.invalidate()
        configuration.save()
        Logger.shared.info("Engine shut down")
    }
    
    // MARK: - Display Management
    
    func handleDisplayChange() {
        // Tear down windows for removed displays, add windows for new displays
        let currentDisplays = Set(DisplayManager.shared.allDisplays().map(\.id))
        
        // Remove windows for gone displays
        for id in windows.keys where !currentDisplays.contains(id) {
            renderers[id]?.stop()
            renderers.removeValue(forKey: id)
            windows[id]?.close()
            windows.removeValue(forKey: id)
            configuration.activeDisplayIDs.remove(id)
        }
        
        // Resize existing windows
        for (id, window) in windows {
            if let screen = DisplayManager.shared.screen(for: id) {
                window.setFrame(screen.frame, display: true)
            }
        }
    }
    
    func handleSpaceChange() {
        // Re-assert window levels after space changes
        for window in windows.values {
            window.enforceDesktopLevel()
        }
    }
    
    func toggleDisplay(_ displayID: CGDirectDisplayID) {
        if configuration.activeDisplayIDs.contains(displayID) {
            configuration.activeDisplayIDs.remove(displayID)
            renderers[displayID]?.stop()
            renderers.removeValue(forKey: displayID)
            windows[displayID]?.close()
            windows.removeValue(forKey: displayID)
        } else {
            configuration.activeDisplayIDs.insert(displayID)
            if let screen = DisplayManager.shared.screen(for: displayID) {
                let window = WallpaperWindow(screen: screen, displayID: displayID)
                windows[displayID] = window
                // Clone current renderer for this display
                if let url = configuration.wallpaperURL {
                    let renderer = RendererFactory.create(
                        type: configuration.wallpaperType,
                        configuration: configuration,
                        targetView: window.contentView!
                    )
                    renderer.load(url: url)
                    renderer.start()
                    renderers[displayID] = renderer
                }
            }
        }
        configuration.save()
    }
    
    func enableAllDisplays() {
        let all = DisplayManager.shared.allDisplays()
        for display in all {
            if !configuration.activeDisplayIDs.contains(display.id) {
                toggleDisplay(display.id)
            }
        }
    }
    
    // MARK: - Wallpaper Loading
    
    func loadWallpaper(from url: URL) {
        Logger.shared.info("Loading wallpaper: \(url.lastPathComponent)")
        configuration.wallpaperURL = url
        
        // Auto-detect type from file extension
        let detectedType = WallpaperTypeDetector.detect(url: url) ?? configuration.wallpaperType
        configuration.wallpaperType = detectedType
        
        applyRenderer(type: detectedType, url: url)
        configuration.save()
    }
    
    func setWallpaperType(_ type: WallpaperType) {
        configuration.wallpaperType = type
        applyRenderer(type: type, url: configuration.wallpaperURL)
        configuration.save()
    }
    
    func setTargetFPS(_ fps: Int) {
        configuration.targetFPS = fps
        for renderer in renderers.values {
            renderer.setTargetFPS(fps)
        }
        configuration.save()
    }
    
    // MARK: - Private
    
    private func createWindowsForActiveDisplays() {
        for displayID in configuration.activeDisplayIDs {
            guard windows[displayID] == nil,
                  let screen = DisplayManager.shared.screen(for: displayID) else { continue }
            let window = WallpaperWindow(screen: screen, displayID: displayID)
            windows[displayID] = window
        }
        
        // If no windows exist (first launch), create for main display
        if windows.isEmpty {
            let mainID = CGMainDisplayID()
            configuration.activeDisplayIDs.insert(mainID)
            if let screen = NSScreen.main {
                let window = WallpaperWindow(screen: screen, displayID: mainID)
                windows[mainID] = window
            }
        }
    }
    
    private func applyRenderer(type: WallpaperType, url: URL?) {
        for (displayID, window) in windows {
            // Stop old renderer
            renderers[displayID]?.stop()
            
            guard let contentView = window.contentView else { continue }
            
            let renderer = RendererFactory.create(
                type: type,
                configuration: configuration,
                targetView: contentView
            )
            
            if let url = url {
                renderer.load(url: url)
            }
            
            renderer.setTargetFPS(configuration.targetFPS)
            renderer.start()
            renderers[displayID] = renderer
        }
    }
    
    private func startFullscreenDetection() {
        fullscreenCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, self.configuration.pauseOnFullscreenApp else { return }
            let hasFullscreen = self.isAnyAppFullscreen()
            if hasFullscreen && self.state == .running {
                self.pause()
            } else if !hasFullscreen && self.state == .paused {
                self.resume()
            }
        }
    }
    
    private func isAnyAppFullscreen() -> Bool {
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        for window in windowList {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let ownerName = window[kCGWindowOwnerName as String] as? String,
                  ownerName != "Finder", ownerName != "Dock", ownerName != "MacLiveEngine"
            else { continue }
            
            let width = bounds["Width"] ?? 0
            let height = bounds["Height"] ?? 0
            
            for screen in NSScreen.screens {
                if abs(width - screen.frame.width) < 2 && abs(height - screen.frame.height) < 2 {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Wallpaper Type Detection

enum WallpaperTypeDetector {
    static func detect(url: URL) -> WallpaperType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "m4v", "avi", "mkv", "webm":
            return .video
        case "html", "htm", "webarchive":
            return .web
        case "metal", "frag", "glsl":
            return .metalShader
        case "png", "jpg", "jpeg", "gif", "heic", "tiff", "webp":
            return .slideshow
        case "qtz":
            return .quartzComposer
        default:
            return nil
        }
    }
}

// MARK: - Renderer Factory

enum RendererFactory {
    static func create(type: WallpaperType, configuration: Configuration, targetView: NSView) -> any WallpaperRenderer {
        switch type {
        case .video:
            return VideoRenderer(targetView: targetView, configuration: configuration)
        case .web:
            return WebRenderer(targetView: targetView, configuration: configuration)
        case .metalShader:
            return MetalShaderRenderer(targetView: targetView, configuration: configuration)
        case .particleSystem:
            return ParticleSystemRenderer(targetView: targetView, configuration: configuration)
        case .slideshow:
            return SlideshowRenderer(targetView: targetView, configuration: configuration)
        case .quartzComposer:
            return QuartzComposerRenderer(targetView: targetView, configuration: configuration)
        case .generativeArt:
            return GenerativeArtRenderer(targetView: targetView, configuration: configuration)
        }
    }
}
