import AppKit
import Combine

final class PreferencesWindowController: NSWindowController {
    
    private let engine: Engine
    private var cancellables = Set<AnyCancellable>()
    
    init(engine: Engine) {
        self.engine = engine
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacLiveEngine Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        guard let window = self.window else { return }
        
        let tabView = NSTabView(frame: window.contentView!.bounds)
        tabView.autoresizingMask = [.width, .height]
        
        // General Tab
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        generalTab.view = createGeneralView()
        tabView.addTabViewItem(generalTab)
        
        // Performance Tab
        let perfTab = NSTabViewItem(identifier: "performance")
        perfTab.label = "Performance"
        perfTab.view = createPerformanceView()
        tabView.addTabViewItem(perfTab)
        
        // Audio Tab
        let audioTab = NSTabViewItem(identifier: "audio")
        audioTab.label = "Audio"
        audioTab.view = createAudioView()
        tabView.addTabViewItem(audioTab)
        
        // Advanced Tab
        let advancedTab = NSTabViewItem(identifier: "advanced")
        advancedTab.label = "Advanced"
        advancedTab.view = createAdvancedView()
        tabView.addTabViewItem(advancedTab)
        
        window.contentView?.addSubview(tabView)
    }
    
    private func createGeneralView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 400))
        
        let launchAtLogin = NSButton(checkboxWithTitle: "Launch at Login",
                                      target: self,
                                      action: #selector(toggleLaunchAtLogin))
        launchAtLogin.frame = NSRect(x: 20, y: 360, width: 300, height: 20)
        launchAtLogin.state = engine.configuration.launchAtLogin ? .on : .off
        view.addSubview(launchAtLogin)
        
        let showNotifications = NSButton(checkboxWithTitle: "Show Notifications on Change",
                                          target: self,
                                          action: #selector(toggleNotifications))
        showNotifications.frame = NSRect(x: 20, y: 330, width: 300, height: 20)
        showNotifications.state = engine.configuration.showNotifications ? .on : .off
        view.addSubview(showNotifications)
        
        return view
    }
    
    private func createPerformanceView() -> NSView {
        return NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 400))
    }
    
    private func createAudioView() -> NSView {
        return NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 400))
    }
    
    private func createAdvancedView() -> NSView {
        return NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 400))
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        engine.configuration.launchAtLogin = sender.state == .on
        engine.configuration.save()
    }
    
    @objc private func toggleNotifications(_ sender: NSButton) {
        engine.configuration.showNotifications = sender.state == .on
        engine.configuration.save()
    }
}
