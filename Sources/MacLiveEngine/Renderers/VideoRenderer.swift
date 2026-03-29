
import AppKit
import AVFoundation
import Combine

final class VideoRenderer: WallpaperRenderer {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    private var cancellables = Set<AnyCancellable>()
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
    }
    
    func load(url: URL) {
        cleanup()
        
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: item)
        self.player = player
        
        player.volume = configuration.wallpaperVolume
        player.rate = configuration.wallpaperPlaybackSpeed
        player.isMuted = configuration.wallpaperVolume == 0
        
        if configuration.wallpaperLoops {
            self.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: asset))
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = targetView.bounds
        
        // --- RESIZING LOGIC ---
        // .resizeAspectFill = Fills screen (crops edges, no black bars) - RECOMMENDED
        // .resizeAspect     = Fits screen (shows black bars if ratios differ)
        // .resize           = Stretches (distorts video to fit)
        
        switch configuration.wallpaperScaleMode {
        case .fill:    playerLayer.videoGravity = .resizeAspectFill
        case .fit:     playerLayer.videoGravity = .resizeAspect
        case .stretch: playerLayer.videoGravity = .resize
        default:       playerLayer.videoGravity = .resizeAspectFill
        }
        
        targetView.wantsLayer = true
        targetView.layer?.addSublayer(playerLayer)
        self.playerLayer = playerLayer
    }
    
    func start() { player?.play() }
    func pause() { player?.pause() }
    func resume() { player?.play() }
    func stop() { cleanup() }
    
    func setTargetFPS(_ fps: Int) {}
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {}
    
    func setProperty(_ key: String, value: Any) {
        if key == "volume", let vol = value as? Float {
            player?.volume = vol
            player?.isMuted = vol == 0
        }
    }
    
    private func cleanup() {
        player?.pause()
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }
}
