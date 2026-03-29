import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var engine: Engine!
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.info("MacLiveEngine starting up...")
        
        // Load or create default configuration
        let config = Configuration.load()
        
        // Initialize the core engine
        engine = Engine(configuration: config)
        
        // Initialize the menu bar controller
        statusBarController = StatusBarController(engine: engine)
        
        // Start the engine
        engine.start()
        
        // Listen for display configuration changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Logger.shared.info("Display configuration changed")
                self?.engine.handleDisplayChange()
            }
            .store(in: &cancellables)
        
        // Listen for workspace notifications (sleep/wake, screen lock)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                Logger.shared.info("System going to sleep")
                self?.engine.pause()
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Logger.shared.info("System waking up")
                self?.engine.resume()
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.engine.handleSpaceChange()
            }
            .store(in: &cancellables)
        
        // Register global hotkeys
        HotkeyManager.shared.register(engine: engine)
        
        Logger.shared.info("MacLiveEngine started successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        engine.shutdown()
        Logger.shared.info("MacLiveEngine shut down")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
