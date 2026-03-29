cat > ~/MyLittleEasterProject/Sources/MacLiveEngine/Core/WallpaperWindow.swift << 'EOF'
import AppKit

/// A borderless, transparent window pinned to the desktop level (behind all other windows).
final class WallpaperWindow: NSWindow {
    
    var displayID: CGDirectDisplayID?
    
    init(screen: NSScreen, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.setupWindow(screen: screen)
    }

    // This override is required to prevent the "unimplemented initializer" crash
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.setupWindow(screen: NSScreen.main ?? screen!)
    }
    
    private func setupWindow(screen: NSScreen) {
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
        
        // Ensure it stays on the correct screen
        self.setFrame(screen.frame, display: true)
        
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
EOF
