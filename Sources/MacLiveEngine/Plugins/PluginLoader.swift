import Foundation

/// Discovers and loads third-party plugin bundles from the plugins directory.
final class PluginLoader {
    
    private var loadedPlugins: [String: MacLiveEnginePlugin] = [:]
    
    static let pluginDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("MacLiveEngine/Plugins", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    func discoverAndLoad(host: PluginHost) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: Self.pluginDirectory,
                                                          includingPropertiesForKeys: nil) else { return }
        
        for url in contents where url.pathExtension == "bundle" {
            loadPlugin(at: url, host: host)
        }
        
        Logger.shared.info("Loaded \(loadedPlugins.count) plugin(s)")
    }
    
    func loadPlugin(at url: URL, host: PluginHost) {
        guard let bundle = Bundle(url: url),
              bundle.load(),
              let principalClass = bundle.principalClass as? (NSObject & MacLiveEnginePlugin).Type else {
            Logger.shared.warning("Failed to load plugin at: \(url.lastPathComponent)")
            return
        }
        
        let identifier = principalClass.pluginIdentifier
        guard loadedPlugins[identifier] == nil else {
            Logger.shared.warning("Plugin \(identifier) already loaded, skipping duplicate")
            return
        }
        
        let instance = principalClass.init()
        instance.pluginDidLoad(host: host)
        loadedPlugins[identifier] = instance
        
        Logger.shared.info("Loaded plugin: \(principalClass.pluginName) v\(principalClass.pluginVersion)")
    }
    
    func unloadAll() {
        for (_, plugin) in loadedPlugins {
            plugin.pluginWillUnload()
        }
        loadedPlugins.removeAll()
    }
    
    func plugin(withIdentifier id: String) -> MacLiveEnginePlugin? {
        return loadedPlugins[id]
    }
    
    var allPlugins: [MacLiveEnginePlugin] {
        Array(loadedPlugins.values)
    }
}
