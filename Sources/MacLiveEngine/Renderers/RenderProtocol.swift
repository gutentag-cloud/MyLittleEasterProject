import AppKit

/// Every wallpaper renderer must conform to this protocol.
protocol WallpaperRenderer: AnyObject {
    
    /// The view this renderer draws into.
    var targetView: NSView { get }
    
    /// Load content from a URL (file or remote).
    func load(url: URL)
    
    /// Start rendering.
    func start()
    
    /// Pause rendering (should be near-zero CPU when paused).
    func pause()
    
    /// Resume rendering.
    func resume()
    
    /// Stop and clean up all resources.
    func stop()
    
    /// Set the target frames per second.
    func setTargetFPS(_ fps: Int)
    
    /// Receive audio spectrum data for reactive effects.
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum)
    
    /// Set a custom property on the renderer.
    func setProperty(_ key: String, value: Any)
}

/// Default implementations so not every renderer needs to implement everything.
extension WallpaperRenderer {
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {}
    func setProperty(_ key: String, value: Any) {}
}
