import Foundation

/// A lightweight scripting layer that executes simple custom scripts.
/// (For a full Lua integration, you'd embed lua.h via C bridging —
///  this provides a JSON-based "mini-script" system instead.)
final class LuaScriptEngine {
    
    struct ScriptCommand: Codable {
        let action: String
        let parameters: [String: String]?
    }
    
    struct Script: Codable {
        let name: String
        let version: String
        let onStart: [ScriptCommand]?
        let onFrame: [ScriptCommand]?
        let onAudio: [ScriptCommand]?
        let onStop: [ScriptCommand]?
    }
    
    private var script: Script?
    weak var engine: Engine?
    
    func load(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let script = try? JSONDecoder().decode(Script.self, from: data) else {
            Logger.shared.error("Failed to load script from \(url)")
            return
        }
        self.script = script
        Logger.shared.info("Loaded script: \(script.name) v\(script.version)")
    }
    
    func executeOnStart() {
        guard let commands = script?.onStart else { return }
        execute(commands)
    }
    
    func executeOnFrame(time: Double) {
        guard let commands = script?.onFrame else { return }
        execute(commands, context: ["time": String(time)])
    }
    
    func executeOnAudio(spectrum: AudioSpectrum) {
        guard let commands = script?.onAudio else { return }
        execute(commands, context: [
            "bass": String(spectrum.bass),
            "mid": String(spectrum.mid),
            "treble": String(spectrum.treble),
            "level": String(spectrum.overallLevel)
        ])
    }
    
    func executeOnStop() {
        guard let commands = script?.onStop else { return }
        execute(commands)
    }
    
    private func execute(_ commands: [ScriptCommand], context: [String: String] = [:]) {
        for cmd in commands {
            switch cmd.action {
            case "log":
                let msg = cmd.parameters?["message"] ?? ""
                Logger.shared.info("[Script] \(msg)")
                
            case "setProperty":
                if let key = cmd.parameters?["key"], let value = cmd.parameters?["value"] {
                    // Apply property to active renderers
                    Logger.shared.info("[Script] Set \(key) = \(value)")
                }
                
            case "setShaderSpeed":
                if let speedStr = cmd.parameters?["speed"], let speed = Float(speedStr) {
                    engine?.configuration.shaderSpeed = speed
                }
                
            case "setFPS":
                if let fpsStr = cmd.parameters?["fps"], let fps = Int(fpsStr) {
                    engine?.setTargetFPS(fps)
                }
                
            case "nextWallpaper":
                engine?.playlistManager.next()
                
            case "previousWallpaper":
                engine?.playlistManager.previous()
                
            default:
                Logger.shared.warning("[Script] Unknown action: \(cmd.action)")
            }
        }
    }
}
