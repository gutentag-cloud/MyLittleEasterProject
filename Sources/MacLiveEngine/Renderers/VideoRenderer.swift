import AppKit
import AVFoundation
import Combine

/// Renders video files (mp4, mov, mkv, etc.) using AVFoundation.
final class VideoRenderer: WallpaperRenderer {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
    }
    
    func load(url: URL) {
        // Clean up previous player
        cleanup()
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])
        let item = AVPlayerItem(asset: asset)
        
        let player = AVQueuePlayer(playerItem: item)
        self.player = player
        
        // Configure player
        player.volume = configuration.wallpaperVolume
        player.rate = configuration.wallpaperPlaybackSpeed
        player.isMuted = configuration.wallpaperVolume == 0
        player.preventsDisplaySleepDuringVideoPlayback = false
        
        // Loop
        if configuration.wallpaperLoops {
            let templateItem = AVPlayerItem(asset: asset)
            self.looper = AVPlayerLooper(player: player, templateItem: templateItem)
        }
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = targetView.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        switch configuration.wallpaperScaleMode {
        case .fill:   playerLayer.videoGravity = .resizeAspectFill
        case .fit:    playerLayer.videoGravity = .resizeAspect
        case .stretch: playerLayer.videoGravity = .resize
        default:      playerLayer.videoGravity = .resizeAspectFill
        }
        
        playerLayer.backgroundColor = NSColor.black.cgColor
        
        // Ensure the target view is layer-backed
        targetView.wantsLayer = true
        
        // Remove old sublayers
        targetView.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        targetView.layer?.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        Logger.shared.info("Video loaded: \(url.lastPathComponent)")
    }
    
    func start() {
        player?.play()
        Logger.shared.info("Video renderer started")
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
    
    func stop() {
        cleanup()
        Logger.shared.info("Video renderer stopped")
    }
    
    func setTargetFPS(_ fps: Int) {
        // AVPlayer handles its own frame rate; we can limit via preferredMaximumResolution
        // but typically this is unnecessary for video playback
    }
    
    func setProperty(_ key: String, value: Any) {
        switch key {
        case "volume":
            if let vol = value as? Float {
                player?.volume = vol
                player?.isMuted = vol == 0
            }
        case "speed":
            if let speed = value as? Float { player?.rate = speed }
        case "position":
            if let pos = value as? Double {
                let time = CMTime(seconds: pos, preferredTimescale: 600)
                player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        default: break
        }
    }
    
    private func cleanup() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        looper?.disableLooping()
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        timeObserver = nil
    }
}
