import AppKit

// MARK: - NSScreen

extension NSScreen {
    /// The CGDirectDisplayID for this screen.
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

// MARK: - NSView

extension NSView {
    /// Take a snapshot of this view as an NSImage.
    func snapshot() -> NSImage? {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: bitmapRep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }
}

// MARK: - CGFloat

extension CGFloat {
    /// Linearly interpolate between two values.
    static func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
}

// MARK: - Float

extension Float {
    /// Clamp a value between min and max.
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Array

extension Array {
    /// Safe subscript that returns nil for out-of-bounds.
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - URL

extension URL {
    /// Check if this URL points to a video file.
    var isVideoFile: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "webm"]
        return videoExtensions.contains(pathExtension.lowercased())
    }
    
    /// Check if this URL points to an image file.
    var isImageFile: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "webp", "bmp"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
    
    /// Check if this URL points to a web file.
    var isWebFile: Bool {
        let webExtensions = ["html", "htm", "webarchive"]
        return webExtensions.contains(pathExtension.lowercased())
    }
}

// MARK: - Date

extension Date {
    /// Hour component (0-23).
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
}
