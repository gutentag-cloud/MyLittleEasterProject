import XCTest
@testable import MacLiveEngine

final class EngineTests: XCTestCase {
    
    func testConfigurationSaveLoad() {
        let config = Configuration()
        config.targetFPS = 60
        config.wallpaperType = .metalShader
        config.pauseOnBattery = false
        config.shaderSpeed = 2.0
        config.particleCount = 10000
        config.playlistInterval = 120
        config.save()
        
        let loaded = Configuration.load()
        XCTAssertEqual(loaded.targetFPS, 60)
        XCTAssertEqual(loaded.wallpaperType, .metalShader)
        XCTAssertEqual(loaded.pauseOnBattery, false)
        XCTAssertEqual(loaded.shaderSpeed, 2.0)
        XCTAssertEqual(loaded.particleCount, 10000)
        XCTAssertEqual(loaded.playlistInterval, 120)
    }
    
    func testWallpaperTypeDetection() {
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.mp4")), .video)
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.mov")), .video)
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.html")), .web)
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.metal")), .metalShader)
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.png")), .slideshow)
        XCTAssertEqual(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.qtz")), .quartzComposer)
        XCTAssertNil(WallpaperTypeDetector.detect(url: URL(fileURLWithPath: "/test.unknown")))
    }
    
    func testAudioSpectrum() {
        let spectrum = AudioSpectrum(
            bands: [0.1, 0.5, 0.8, 0.3],
            bass: 0.7,
            mid: 0.5,
            treble: 0.3,
            overallLevel: 0.5
        )
        
        XCTAssertEqual(spectrum.bands.count, 4)
        XCTAssertEqual(spectrum.bass, 0.7)
        XCTAssertEqual(spectrum.mid, 0.5)
        XCTAssertEqual(spectrum.treble, 0.3)
        XCTAssertEqual(spectrum.overallLevel, 0.5)
    }
    
    func testPlaylistManager() {
        let config = Configuration()
        config.playlistShuffle = false
        
        let manager = PlaylistManager(configuration: config)
        
        let url1 = URL(fileURLWithPath: "/tmp/test1.mp4")
        let url2 = URL(fileURLWithPath: "/tmp/test2.mp4")
        let url3 = URL(fileURLWithPath: "/tmp/test3.mp4")
        
        manager.add(url1)
        manager.add(url2)
        manager.add(url3)
        
        XCTAssertEqual(manager.items.count, 3)
        
        manager.next()
        // After calling next from index -1, it should go to 0
        
        manager.clear()
        XCTAssertTrue(manager.items.isEmpty)
    }
    
    func testDisplayManager() {
        let displays = DisplayManager.shared.allDisplays()
        XCTAssertFalse(displays.isEmpty, "Should have at least one display")
        XCTAssertTrue(displays.contains(where: { $0.isMain }))
    }
    
    func testURLExtensions() {
        let videoURL = URL(fileURLWithPath: "/test.mp4")
        XCTAssertTrue(videoURL.isVideoFile)
        XCTAssertFalse(videoURL.isImageFile)
        
        let imageURL = URL(fileURLWithPath: "/test.png")
        XCTAssertTrue(imageURL.isImageFile)
        XCTAssertFalse(imageURL.isVideoFile)
        
        let webURL = URL(fileURLWithPath: "/test.html")
        XCTAssertTrue(webURL.isWebFile)
    }
    
    func testFloatClamped() {
        XCTAssertEqual(Float(1.5).clamped(to: 0...1), 1.0)
        XCTAssertEqual(Float(-0.5).clamped(to: 0...1), 0.0)
        XCTAssertEqual(Float(0.5).clamped(to: 0...1), 0.5)
    }
    
    func testSafeSubscript() {
        let arr = [1, 2, 3]
        XCTAssertEqual(arr[safe: 0], 1)
        XCTAssertEqual(arr[safe: 2], 3)
        XCTAssertNil(arr[safe: 5])
        XCTAssertNil(arr[safe: -1])
    }
    
    func testSchedulerDaytime() {
        let config = Configuration()
        config.sunriseHour = 6
        config.sunsetHour = 20
        
        let scheduler = Scheduler(configuration: config)
        // Just ensure it initializes
        XCTAssertNotNil(scheduler)
    }
}
