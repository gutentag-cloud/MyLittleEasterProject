import AppKit

/// Third-party plugins implement this protocol and are loaded at runtime.
@objc protocol MacLiveEnginePlugin: NSObjectProtocol {
    
    /// Unique identifier for this plugin.
    static var pluginIdentifier: String { get }
    
    /// Human-readable name.
    static var pluginName: String { get }
    
    /// Plugin version.
    static var pluginVersion: String { get }
    
    /// Called when the plugin is loaded.
    func pluginDidLoad(host: PluginHost)
    
    /// Called when the plugin is about to be unloaded.
    func pluginWillUnload()
    
    /// Optionally provide a custom renderer.
    @objc optional func createRenderer(targetView: NSView, configuration: [String: Any]) -> NSObject?
    
    /// Optionally provide a preferences view for the menu.
    @objc optional func preferencesView() -> NSView?
}

/// The host interface exposed to plugins.
@objc protocol PluginHost: NSObjectProtocol {
    
    /// Log a message.
    func log(_ message: String)
    
    /// Get the current audio spectrum.
    func currentAudioSpectrum() -> [String: Any]
    
    /// Request a wallpaper change.
    func setWallpaper(url: URL)
    
    /// Get engine configuration values.
    func configurationValue(forKey key: String) -> Any?
    
    /// Set engine configuration values.
    func setConfigurationValue(_ value: Any, forKey key: String)
}
