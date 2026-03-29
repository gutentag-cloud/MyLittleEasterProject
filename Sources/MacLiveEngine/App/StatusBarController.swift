import AppKit
import Combine

final class StatusBarController {
    
    private let statusItem: NSStatusItem
    private let engine: Engine
    private var cancellables = Set<AnyCancellable>()
    
    init(engine: Engine) {
        self.engine = engine
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupMenu()
        bindState()
    }
    
    private func setupMenu() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "sparkles.tv", accessibilityDescription: "MacLiveEngine")
        button.image?.isTemplate = true
        rebuildMenu()
    }
    
    private func bindState() {
        engine.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
        
        engine.performanceMonitor.$currentFPS
            .receive(on: RunLoop.main)
            .throttle(for: .seconds(2), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }
    
    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // ── Status ──
        let stateString: String
        switch engine.state {
        case .running: stateString = "● Running"
        case .paused: stateString = "❚❚ Paused"
        case .stopped: stateString = "■ Stopped"
        }
        let statusItem = NSMenuItem(title: stateString, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        let fpsItem = NSMenuItem(
            title: String(format: "FPS: %.0f  |  CPU: %.1f%%  |  MEM: %.0f MB",
                          engine.performanceMonitor.currentFPS,
                          engine.performanceMonitor.cpuUsage,
                          engine.performanceMonitor.memoryUsageMB),
            action: nil,
            keyEquivalent: ""
        )
        fpsItem.isEnabled = false
        menu.addItem(fpsItem)
        
        menu.addItem(.separator())
        
        // ── Playback Controls ──
        let playPause = NSMenuItem(
            title: engine.state == .running ? "Pause" : "Resume",
            action: #selector(togglePlayPause),
            keyEquivalent: "p"
        )
        playPause.target = self
        menu.addItem(playPause)
        
        let next = NSMenuItem(title: "Next Wallpaper", action: #selector(nextWallpaper), keyEquivalent: "n")
        next.target = self
        menu.addItem(next)
        
        let prev = NSMenuItem(title: "Previous Wallpaper", action: #selector(prevWallpaper), keyEquivalent: "b")
        prev.target = self
        menu.addItem(prev)
        
        menu.addItem(.separator())
        
        // ── Wallpaper Type Submenu ──
        let typeMenu = NSMenu()
        let types: [(String, WallpaperType)] = [
            ("Video File", .video),
            ("Web Page / HTML", .web),
            ("Metal Shader", .metalShader),
            ("Particle System", .particleSystem),
            ("Image Slideshow", .slideshow),
            ("Generative Art", .generativeArt),
        ]
        for (title, type) in types {
            let item = NSMenuItem(title: title, action: #selector(selectWallpaperType(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = type
            item.state = engine.configuration.wallpaperType == type ? .on : .off
            typeMenu.addItem(item)
        }
        let typeItem = NSMenuItem(title: "Wallpaper Type", action: nil, keyEquivalent: "")
        typeItem.submenu = typeMenu
        menu.addItem(typeItem)
        
        // ── Open File ──
        let openFile = NSMenuItem(title: "Open Wallpaper File...", action: #selector(openFile), keyEquivalent: "o")
        openFile.target = self
        menu.addItem(openFile)
        
        // ── Display Submenu ──
        let displayMenu = NSMenu()
        let displays = DisplayManager.shared.allDisplays()
        for display in displays {
            let item = NSMenuItem(
                title: display.localizedName,
                action: #selector(selectDisplay(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = display.id
            item.state = engine.configuration.activeDisplayIDs.contains(display.id) ? .on : .off
            displayMenu.addItem(item)
        }
        let allItem = NSMenuItem(title: "All Displays", action: #selector(selectAllDisplays), keyEquivalent: "")
        allItem.target = self
        displayMenu.addItem(.separator())
        displayMenu.addItem(allItem)
        let displayItem = NSMenuItem(title: "Displays", action: nil, keyEquivalent: "")
        displayItem.submenu = displayMenu
        menu.addItem(displayItem)
        
        menu.addItem(.separator())
        
        // ── Performance Submenu ──
        let perfMenu = NSMenu()
        let fpsOptions: [Int] = [15, 24, 30, 60, 120]
        for fps in fpsOptions {
            let item = NSMenuItem(title: "\(fps) FPS", action: #selector(setTargetFPS(_:)), keyEquivalent: "")
            item.target = self
            item.tag = fps
            item.state = engine.configuration.targetFPS == fps ? .on : .off
            perfMenu.addItem(item)
        }
        perfMenu.addItem(.separator())
        let batteryItem = NSMenuItem(
            title: "Pause on Battery",
            action: #selector(toggleBatteryPause),
            keyEquivalent: ""
        )
        batteryItem.target = self
        batteryItem.state = engine.configuration.pauseOnBattery ? .on : .off
        perfMenu.addItem(batteryItem)
        
        let focusItem = NSMenuItem(
            title: "Pause When App Fullscreen",
            action: #selector(toggleFullscreenPause),
            keyEquivalent: ""
        )
        focusItem.target = self
        focusItem.state = engine.configuration.pauseOnFullscreenApp ? .on : .off
        perfMenu.addItem(focusItem)
        
        let perfMenuItem = NSMenuItem(title: "Performance", action: nil, keyEquivalent: "")
        perfMenuItem.submenu = perfMenu
        menu.addItem(perfMenuItem)
        
        // ── Audio Reactive ──
        let audioItem = NSMenuItem(
            title: "Audio Reactive",
            action: #selector(toggleAudioReactive),
            keyEquivalent: ""
        )
        audioItem.target = self
        audioItem.state = engine.configuration.audioReactive ? .on : .off
        menu.addItem(audioItem)
        
        // ── Playlist Submenu ──
        let playlistMenu = NSMenu()
        let enablePlaylist = NSMenuItem(
            title: "Enable Playlist",
            action: #selector(togglePlaylist),
            keyEquivalent: ""
        )
        enablePlaylist.target = self
        enablePlaylist.state = engine.configuration.playlistEnabled ? .on : .off
        playlistMenu.addItem(enablePlaylist)
        
        let shuffleItem = NSMenuItem(
            title: "Shuffle",
            action: #selector(toggleShuffle),
            keyEquivalent: ""
        )
        shuffleItem.target = self
        shuffleItem.state = engine.configuration.playlistShuffle ? .on : .off
        playlistMenu.addItem(shuffleItem)
        
        let intervalMenu = NSMenu()
        let intervals: [(String, TimeInterval)] = [
            ("30 seconds", 30),
            ("1 minute", 60),
            ("5 minutes", 300),
            ("15 minutes", 900),
            ("30 minutes", 1800),
            ("1 hour", 3600),
        ]
        for (title, interval) in intervals {
            let item = NSMenuItem(title: title, action: #selector(setPlaylistInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = interval
            item.state = engine.configuration.playlistInterval == interval ? .on : .off
            intervalMenu.addItem(item)
        }
        let intervalItem = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        intervalItem.submenu = intervalMenu
        playlistMenu.addItem(intervalItem)
        
        let addToPlaylist = NSMenuItem(title: "Add Files to Playlist...", action: #selector(addToPlaylist), keyEquivalent: "")
        addToPlaylist.target = self
        playlistMenu.addItem(addToPlaylist)
        
        let clearPlaylist = NSMenuItem(title: "Clear Playlist", action: #selector(clearPlaylist), keyEquivalent: "")
        clearPlaylist.target = self
        playlistMenu.addItem(clearPlaylist)
        
        let playlistMenuItem = NSMenuItem(title: "Playlist", action: nil, keyEquivalent: "")
        playlistMenuItem.submenu = playlistMenu
        menu.addItem(playlistMenuItem)
        
        menu.addItem(.separator())
        
        // ── Schedule Submenu ──
        let scheduleMenu = NSMenu()
        let daySchedule = NSMenuItem(title: "Day Wallpaper...", action: #selector(setDayWallpaper), keyEquivalent: "")
        daySchedule.target = self
        scheduleMenu.addItem(daySchedule)
        let nightSchedule = NSMenuItem(title: "Night Wallpaper...", action: #selector(setNightWallpaper), keyEquivalent: "")
        nightSchedule.target = self
        scheduleMenu.addItem(nightSchedule)
        let enableSchedule = NSMenuItem(title: "Enable Day/Night Cycle", action: #selector(toggleSchedule), keyEquivalent: "")
        enableSchedule.target = self
        enableSchedule.state = engine.configuration.schedulerEnabled ? .on : .off
        scheduleMenu.addItem(enableSchedule)
        let scheduleMenuItem = NSMenuItem(title: "Schedule", action: nil, keyEquivalent: "")
        scheduleMenuItem.submenu = scheduleMenu
        menu.addItem(scheduleMenuItem)
        
        menu.addItem(.separator())
        
        // ── Quit ──
        let quit = NSMenuItem(title: "Quit MacLiveEngine", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        
        self.statusItem.menu = menu
    }
    
    // MARK: - Actions
    
    @objc private func togglePlayPause() {
        if engine.state == .running { engine.pause() }
        else { engine.resume() }
    }
    
    @objc private func nextWallpaper() {
        engine.playlistManager.next()
    }
    
    @objc private func prevWallpaper() {
        engine.playlistManager.previous()
    }
    
    @objc private func selectWallpaperType(_ sender: NSMenuItem) {
        guard let type = sender.representedObject as? WallpaperType else { return }
        engine.setWallpaperType(type)
    }
    
    @objc private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = engine.supportedContentTypes
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.engine.loadWallpaper(from: url)
        }
    }
    
    @objc private func selectDisplay(_ sender: NSMenuItem) {
        guard let displayID = sender.representedObject as? CGDirectDisplayID else { return }
        engine.toggleDisplay(displayID)
    }
    
    @objc private func selectAllDisplays() {
        engine.enableAllDisplays()
    }
    
    @objc private func setTargetFPS(_ sender: NSMenuItem) {
        engine.setTargetFPS(sender.tag)
    }
    
    @objc private func toggleBatteryPause() {
        engine.configuration.pauseOnBattery.toggle()
        engine.configuration.save()
    }
    
    @objc private func toggleFullscreenPause() {
        engine.configuration.pauseOnFullscreenApp.toggle()
        engine.configuration.save()
    }
    
    @objc private func toggleAudioReactive() {
        engine.configuration.audioReactive.toggle()
        engine.configuration.save()
        if engine.configuration.audioReactive {
            engine.audioEngine.start()
        } else {
            engine.audioEngine.stop()
        }
    }
    
    @objc private func togglePlaylist() {
        engine.configuration.playlistEnabled.toggle()
        engine.configuration.save()
        if engine.configuration.playlistEnabled {
            engine.playlistManager.start()
        } else {
            engine.playlistManager.stop()
        }
    }
    
    @objc private func toggleShuffle() {
        engine.configuration.playlistShuffle.toggle()
        engine.configuration.save()
    }
    
    @objc private func setPlaylistInterval(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? TimeInterval else { return }
        engine.configuration.playlistInterval = interval
        engine.configuration.save()
        engine.playlistManager.updateInterval(interval)
    }
    
    @objc private func addToPlaylist() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = engine.supportedContentTypes
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            for url in panel.urls {
                self?.engine.playlistManager.add(url)
            }
        }
    }
    
    @objc private func clearPlaylist() {
        engine.playlistManager.clear()
    }
    
    @objc private func setDayWallpaper() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = engine.supportedContentTypes
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.engine.configuration.dayWallpaperURL = url
            self?.engine.configuration.save()
        }
    }
    
    @objc private func setNightWallpaper() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = engine.supportedContentTypes
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.engine.configuration.nightWallpaperURL = url
            self?.engine.configuration.save()
        }
    }
    
    @objc private func toggleSchedule() {
        engine.configuration.schedulerEnabled.toggle()
        engine.configuration.save()
        if engine.configuration.schedulerEnabled {
            engine.scheduler.start()
        } else {
            engine.scheduler.stop()
        }
    }
    
    @objc private func quitApp() {
        engine.shutdown()
        NSApp.terminate(nil)
    }
}
