import AppKit

/// A borderless, transparent window pinned to the desktop level (behind all other windows).
final class WallpaperWindow: NSWindow {
    
    let displayID: CGDirectDisplayID
    
    init(screen: NSScreen, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .canJoinAllApplications]
        self.isOpaque = true
        self.hasShadow = false
        self.backgroundColor = .black
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.canHide = false
        self.animationBehavior = .none
        
        // Create a layer-backed content view for GPU rendering
        let view = WallpaperView(frame: screen.frame)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        self.contentView = view
        
        self.orderFront(nil)
    }
    
    /// Re-assert that we are behind everything.
    func enforceDesktopLevel() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.orderFront(nil)
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// The content view of the wallpaper window.
final class WallpaperView: NSView {
    override var acceptsFirstResponder: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    
    override func updateLayer() {
        super.updateLayer()
    }
}
