import AppKit

/// Info about one display.
struct DisplayInfo {
    let id: CGDirectDisplayID
    let localizedName: String
    let frame: NSRect
    let isMain: Bool
    let screen: NSScreen
}

/// Manages display enumeration and mapping.
final class DisplayManager {
    
    static let shared = DisplayManager()
    private init() {}
    
    func allDisplays() -> [DisplayInfo] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(16, &displayIDs, &displayCount)
        
        let activeIDs = Array(displayIDs.prefix(Int(displayCount)))
        
        return activeIDs.compactMap { id in
            guard let screen = screen(for: id) else { return nil }
            return DisplayInfo(
                id: id,
                localizedName: screen.localizedName,
                frame: screen.frame,
                isMain: id == CGMainDisplayID(),
                screen: screen
            )
        }
    }
    
    func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return false
            }
            return screenNumber == displayID
        }
    }
    
    func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
