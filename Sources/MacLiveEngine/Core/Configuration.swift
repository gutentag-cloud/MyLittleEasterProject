import Foundation

/// Every wallpaper type the engine supports.
enum WallpaperType: String, Codable, CaseIterable {
    case video
    case web
    case metalShader
    case particleSystem
    case slideshow
    case quartzComposer
    case generativeArt
}

/// Transition style between wallpapers.
enum TransitionStyle: String, Codable, CaseIterable {
    case none
    case crossfade
    case slideLeft
    case slideRight
    case dissolve
    case zoomIn
    case zoomOut
}

/// All persisted configuration.
final class Configuration: Codable, ObservableObject {
    
    // ── Wallpaper ──
    @Published var wallpaperType: WallpaperType = .video
    @Published var wallpaperURL: URL?
    @Published var wallpaperVolume: Float = 0.0
    @Published var wallpaperPlaybackSpeed: Float = 1.0
    @Published var wallpaperLoops: Bool = true
    @Published var wallpaperScaleMode: ScaleMode = .fill
    
    // ── Display ──
    @Published var activeDisplayIDs: Set<CGDirectDisplayID> = [CGMainDisplayID()]
    @Published var spanAcrossDisplays: Bool = false
    
    // ── Performance ──
    @Published var targetFPS: Int = 30
    @Published var pauseOnBattery: Bool = true
    @Published var pauseOnFullscreenApp: Bool = true
    @Published var pauseWhenInactive: Bool = false
    @Published var reducedFPSOnBattery: Int = 15
    @Published var maxCPUPercent: Double = 25.0
    @Published var maxMemoryMB: Double = 512.0
    
    // ── Audio ──
    @Published var audioReactive: Bool = false
    @Published var audioSensitivity: Float = 1.0
    @Published var audioSmoothing: Float = 0.7
    @Published var audioFrequencyBands: Int = 64
    
    // ── Playlist ──
    @Published var playlistEnabled: Bool = false
    @Published var playlistShuffle: Bool = false
    @Published var playlistInterval: TimeInterval = 300
    @Published var playlistURLs: [URL] = []
    @Published var transitionStyle: TransitionStyle = .crossfade
    @Published var transitionDuration: TimeInterval = 1.5
    
    // ── Scheduler ──
    @Published var schedulerEnabled: Bool = false
    @Published var dayWallpaperURL: URL?
    @Published var nightWallpaperURL: URL?
    @Published var sunriseHour: Int = 7
    @Published var sunsetHour: Int = 19
    
    // ── General ──
    @Published var launchAtLogin: Bool = false
    @Published var showNotifications: Bool = true
    
    // ── Shader ──
    @Published var shaderName: String = "plasma"
    @Published var shaderSpeed: Float = 1.0
    @Published var shaderParameters: [String: Float] = [:]
    
    // ── Particles ──
    @Published var particleCount: Int = 5000
    @Published var particlePreset: String = "starfield"
    
    // ── Slideshow ──
    @Published var slideshowDirectoryURL: URL?
    @Published var slideshowInterval: TimeInterval = 10
    @Published var slideshowTransition: TransitionStyle = .crossfade
    
    // ── Generative ──
    @Published var generativePreset: String = "flow_field"
    @Published var generativeSeed: UInt64 = 0
    
    enum ScaleMode: String, Codable {
        case fill, fit, stretch, center, tile
    }
    
    // MARK: - Codable Conformance (manual because of @Published)
    
    enum CodingKeys: String, CodingKey {
        case wallpaperType, wallpaperURL, wallpaperVolume, wallpaperPlaybackSpeed
        case wallpaperLoops, wallpaperScaleMode
        case activeDisplayIDs, spanAcrossDisplays
        case targetFPS, pauseOnBattery, pauseOnFullscreenApp, pauseWhenInactive
        case reducedFPSOnBattery, maxCPUPercent, maxMemoryMB
        case audioReactive, audioSensitivity, audioSmoothing, audioFrequencyBands
        case playlistEnabled, playlistShuffle, playlistInterval, playlistURLs
        case transitionStyle, transitionDuration
        case schedulerEnabled, dayWallpaperURL, nightWallpaperURL, sunriseHour, sunsetHour
        case launchAtLogin, showNotifications
        case shaderName, shaderSpeed, shaderParameters
        case particleCount, particlePreset
        case slideshowDirectoryURL, slideshowInterval, slideshowTransition
        case generativePreset, generativeSeed
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wallpaperType = (try? c.decode(WallpaperType.self, forKey: .wallpaperType)) ?? .video
        wallpaperURL = try? c.decode(URL.self, forKey: .wallpaperURL)
        wallpaperVolume = (try? c.decode(Float.self, forKey: .wallpaperVolume)) ?? 0
        wallpaperPlaybackSpeed = (try? c.decode(Float.self, forKey: .wallpaperPlaybackSpeed)) ?? 1
        wallpaperLoops = (try? c.decode(Bool.self, forKey: .wallpaperLoops)) ?? true
        wallpaperScaleMode = (try? c.decode(ScaleMode.self, forKey: .wallpaperScaleMode)) ?? .fill
        
        if let ids = try? c.decode([CGDirectDisplayID].self, forKey: .activeDisplayIDs) {
            activeDisplayIDs = Set(ids)
        }
        spanAcrossDisplays = (try? c.decode(Bool.self, forKey: .spanAcrossDisplays)) ?? false
        
        targetFPS = (try? c.decode(Int.self, forKey: .targetFPS)) ?? 30
        pauseOnBattery = (try? c.decode(Bool.self, forKey: .pauseOnBattery)) ?? true
        pauseOnFullscreenApp = (try? c.decode(Bool.self, forKey: .pauseOnFullscreenApp)) ?? true
        pauseWhenInactive = (try? c.decode(Bool.self, forKey: .pauseWhenInactive)) ?? false
        reducedFPSOnBattery = (try? c.decode(Int.self, forKey: .reducedFPSOnBattery)) ?? 15
        maxCPUPercent = (try? c.decode(Double.self, forKey: .maxCPUPercent)) ?? 25
        maxMemoryMB = (try? c.decode(Double.self, forKey: .maxMemoryMB)) ?? 512
        
        audioReactive = (try? c.decode(Bool.self, forKey: .audioReactive)) ?? false
        audioSensitivity = (try? c.decode(Float.self, forKey: .audioSensitivity)) ?? 1
        audioSmoothing = (try? c.decode(Float.self, forKey: .audioSmoothing)) ?? 0.7
        audioFrequencyBands = (try? c.decode(Int.self, forKey: .audioFrequencyBands)) ?? 64
        
        playlistEnabled = (try? c.decode(Bool.self, forKey: .playlistEnabled)) ?? false
        playlistShuffle = (try? c.decode(Bool.self, forKey: .playlistShuffle)) ?? false
        playlistInterval = (try? c.decode(TimeInterval.self, forKey: .playlistInterval)) ?? 300
        playlistURLs = (try? c.decode([URL].self, forKey: .playlistURLs)) ?? []
        transitionStyle = (try? c.decode(TransitionStyle.self, forKey: .transitionStyle)) ?? .crossfade
        transitionDuration = (try? c.decode(TimeInterval.self, forKey: .transitionDuration)) ?? 1.5
        
        schedulerEnabled = (try? c.decode(Bool.self, forKey: .schedulerEnabled)) ?? false
        dayWallpaperURL = try? c.decode(URL.self, forKey: .dayWallpaperURL)
        nightWallpaperURL = try? c.decode(URL.self, forKey: .nightWallpaperURL)
        sunriseHour = (try? c.decode(Int.self, forKey: .sunriseHour)) ?? 7
        sunsetHour = (try? c.decode(Int.self, forKey: .sunsetHour)) ?? 19
        
        launchAtLogin = (try? c.decode(Bool.self, forKey: .launchAtLogin)) ?? false
        showNotifications = (try? c.decode(Bool.self, forKey: .showNotifications)) ?? true
        
        shaderName = (try? c.decode(String.self, forKey: .shaderName)) ?? "plasma"
        shaderSpeed = (try? c.decode(Float.self, forKey: .shaderSpeed)) ?? 1
        shaderParameters = (try? c.decode([String: Float].self, forKey: .shaderParameters)) ?? [:]
        
        particleCount = (try? c.decode(Int.self, forKey: .particleCount)) ?? 5000
        particlePreset = (try? c.decode(String.self, forKey: .particlePreset)) ?? "starfield"
        
        slideshowDirectoryURL = try? c.decode(URL.self, forKey: .slideshowDirectoryURL)
        slideshowInterval = (try? c.decode(TimeInterval.self, forKey: .slideshowInterval)) ?? 10
        slideshowTransition = (try? c.decode(TransitionStyle.self, forKey: .slideshowTransition)) ?? .crossfade
        
        generativePreset = (try? c.decode(String.self, forKey: .generativePreset)) ?? "flow_field"
        generativeSeed = (try? c.decode(UInt64.self, forKey: .generativeSeed)) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(wallpaperType, forKey: .wallpaperType)
        try c.encodeIfPresent(wallpaperURL, forKey: .wallpaperURL)
        try c.encode(wallpaperVolume, forKey: .wallpaperVolume)
        try c.encode(wallpaperPlaybackSpeed, forKey: .wallpaperPlaybackSpeed)
        try c.encode(wallpaperLoops, forKey: .wallpaperLoops)
        try c.encode(wallpaperScaleMode, forKey: .wallpaperScaleMode)
        try c.encode(Array(activeDisplayIDs), forKey: .activeDisplayIDs)
        try c.encode(spanAcrossDisplays, forKey: .spanAcrossDisplays)
        try c.encode(targetFPS, forKey: .targetFPS)
        try c.encode(pauseOnBattery, forKey: .pauseOnBattery)
        try c.encode(pauseOnFullscreenApp, forKey: .pauseOnFullscreenApp)
        try c.encode(pauseWhenInactive, forKey: .pauseWhenInactive)
        try c.encode(reducedFPSOnBattery, forKey: .reducedFPSOnBattery)
        try c.encode(maxCPUPercent, forKey: .maxCPUPercent)
        try c.encode(maxMemoryMB, forKey: .maxMemoryMB)
        try c.encode(audioReactive, forKey: .audioReactive)
        try c.encode(audioSensitivity, forKey: .audioSensitivity)
        try c.encode(audioSmoothing, forKey: .audioSmoothing)
        try c.encode(audioFrequencyBands, forKey: .audioFrequencyBands)
        try c.encode(playlistEnabled, forKey: .playlistEnabled)
        try c.encode(playlistShuffle, forKey: .playlistShuffle)
        try c.encode(playlistInterval, forKey: .playlistInterval)
        try c.encode(playlistURLs, forKey: .playlistURLs)
        try c.encode(transitionStyle, forKey: .transitionStyle)
        try c.encode(transitionDuration, forKey: .transitionDuration)
        try c.encode(schedulerEnabled, forKey: .schedulerEnabled)
        try c.encodeIfPresent(dayWallpaperURL, forKey: .dayWallpaperURL)
        try c.encodeIfPresent(nightWallpaperURL, forKey: .nightWallpaperURL)
        try c.encode(sunriseHour, forKey: .sunriseHour)
        try c.encode(sunsetHour, forKey: .sunsetHour)
        try c.encode(launchAtLogin, forKey: .launchAtLogin)
        try c.encode(showNotifications, forKey: .showNotifications)
        try c.encode(shaderName, forKey: .shaderName)
        try c.encode(shaderSpeed, forKey: .shaderSpeed)
        try c.encode(shaderParameters, forKey: .shaderParameters)
        try c.encode(particleCount, forKey: .particleCount)
        try c.encode(particlePreset, forKey: .particlePreset)
        try c.encodeIfPresent(slideshowDirectoryURL, forKey: .slideshowDirectoryURL)
        try c.encode(slideshowInterval, forKey: .slideshowInterval)
        try c.encode(slideshowTransition, forKey: .slideshowTransition)
        try c.encode(generativePreset, forKey: .generativePreset)
        try c.encode(generativeSeed, forKey: .generativeSeed)
    }
    
    // MARK: - Persistence
    
    private static var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacLiveEngine", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }
    
    static func load() -> Configuration {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Configuration.self, from: data) else {
            let config = Configuration()
            config.save()
            return config
        }
        return config
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.configURL, options: .atomic)
    }
}
