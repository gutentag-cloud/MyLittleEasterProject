import AppKit
import Carbon

/// Registers global hotkeys for controlling the engine.
final class HotkeyManager {
    
    static let shared = HotkeyManager()
    private init() {}
    
    private weak var engine: Engine?
    private var monitors: [Any] = []
    
    func register(engine: Engine) {
        self.engine = engine
        
        // ⌃⌥⌘P — Toggle play/pause
        addGlobalHotkey(keyCode: kVK_ANSI_P, modifiers: [.control, .option, .command]) { [weak engine] in
            guard let engine = engine else { return }
            if engine.state == .running { engine.pause() }
            else { engine.resume() }
        }
        
        // ⌃⌥⌘N — Next wallpaper
        addGlobalHotkey(keyCode: kVK_ANSI_N, modifiers: [.control, .option, .command]) { [weak engine] in
            engine?.playlistManager.next()
        }
        
        // ⌃⌥⌘B — Previous wallpaper
        addGlobalHotkey(keyCode: kVK_ANSI_B, modifiers: [.control, .option, .command]) { [weak engine] in
            engine?.playlistManager.previous()
        }
        
        // ⌃⌥⌘M — Mute/unmute
        addGlobalHotkey(keyCode: kVK_ANSI_M, modifiers: [.control, .option, .command]) { [weak engine] in
            guard let engine = engine else { return }
            engine.configuration.wallpaperVolume = engine.configuration.wallpaperVolume > 0 ? 0 : 0.5
            engine.configuration.save()
        }
        
        Logger.shared.info("Global hotkeys registered")
    }
    
    func unregister() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
    }
    
    private func addGlobalHotkey(keyCode: Int, modifiers: NSEvent.ModifierFlags, handler: @escaping () -> Void) {
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers {
                handler()
            }
        } {
            monitors.append(monitor)
        }
    }
}
